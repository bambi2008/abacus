import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../config/constants.dart';
import '../models/badge_record.dart';
import '../models/complete_log_day_mark.dart';
import '../models/monthly_savings_result.dart';
import '../models/owl_mood.dart';
import '../models/owl_state.dart';
import '../models/category_challenge_result.dart';
import '../models/no_spend_day_mark.dart';
import '../services/analytics_service.dart';
import 'category_provider.dart';
import 'expense_provider.dart';

/// Owns gamification state layered on top of ExpenseProvider/CategoryProvider
/// without changing either's public API — see docs/technical-architecture.md
/// and the gamification-depth plan. Reads live streak/category state via
/// [bind], set once at app start (see main.dart) — no ChangeNotifierProxyProvider
/// wiring needed since neither dependency is expected to be swapped at runtime.
class GamificationProvider extends ChangeNotifier {
  late Box<BadgeRecord> _badges;
  late Box<NoSpendDayMark> _noSpendDays;
  late Box<CategoryChallengeResult> _categoryResults;
  late Box<OwlState> _owlStateBox;
  late Box<CompleteLogDayMark> _completeLogDays;
  late Box<MonthlySavingsResult> _monthlySavingsResults;
  late Box _settings;
  ExpenseProvider? _expenseProvider;
  CategoryProvider? _categoryProvider;

  void load() {
    _badges = Hive.box<BadgeRecord>(HiveBoxes.badges);
    _noSpendDays = Hive.box<NoSpendDayMark>(HiveBoxes.noSpendDays);
    _categoryResults = Hive.box<CategoryChallengeResult>(
      HiveBoxes.categoryChallengeResults,
    );
    _owlStateBox = Hive.box<OwlState>(HiveBoxes.owlState);
    _completeLogDays = Hive.box<CompleteLogDayMark>(HiveBoxes.completeLogDays);
    _monthlySavingsResults = Hive.box<MonthlySavingsResult>(
      HiveBoxes.monthlySavingsResults,
    );
    _settings = Hive.box(HiveBoxes.settings);
  }

  void bind(
    ExpenseProvider expenseProvider,
    CategoryProvider categoryProvider,
  ) {
    _expenseProvider = expenseProvider;
    _categoryProvider = categoryProvider;
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
  String _dateKey(DateTime d) => _dateOnly(d).toIso8601String();

  // --- Badges / milestones (Layer 1) ---

  List<BadgeRecord> get earnedBadges => _badges.values.toList();

  bool isEarned(int milestoneDay) =>
      _badges.get('streak_$milestoneDay') != null;

  /// A badge that's been earned but whose full-screen celebration hasn't
  /// been shown yet — resilient to the app being killed mid-flow, since
  /// this is just a box scan, safe to check on every relevant screen build.
  BadgeRecord? get pendingCelebration {
    for (final badge in _badges.values) {
      if (!badge.celebrationShown) return badge;
    }
    return null;
  }

  /// Idempotent: safe to call after every log and on app start. Returns the
  /// newly-earned badge if `currentStreak` just crossed a milestone for the
  /// first time, otherwise null.
  Future<BadgeRecord?> checkForNewMilestone(int currentStreak) async {
    if (!MilestoneCatalog.milestoneDays.contains(currentStreak)) return null;
    final id = 'streak_$currentStreak';
    if (_badges.get(id) != null) return null;
    final badge = BadgeRecord(
      id: id,
      milestoneDay: currentStreak,
      earnedAt: DateTime.now(),
    );
    await _badges.put(id, badge);
    AnalyticsService.instance.capture(
      'milestone_reached',
      properties: {'milestone_day': currentStreak},
    );
    notifyListeners();
    return badge;
  }

  Future<void> markCelebrationShown(String badgeId) async {
    final badge = _badges.get(badgeId);
    if (badge == null) return;
    await _badges.put(badgeId, badge.copyWith(celebrationShown: true));
    notifyListeners();
  }

  // --- No-spend days (Layer 2) ---

  bool isNoSpendDay(DateTime date) => _noSpendDays.get(_dateKey(date)) != null;

  int get noSpendDayCountThisMonth {
    final now = DateTime.now();
    return _noSpendDays.values
        .where((m) => m.date.year == now.year && m.date.month == now.month)
        .length;
  }

  /// Idempotent — marking an already-marked day is a no-op. Any date
  /// (including today) can be marked: intent-based framing ("I'm
  /// committing to no spend today") is a valid win condition too, matching
  /// real no-spend-challenge apps' "mark as a deliberate win" language.
  Future<bool> markNoSpendDay(DateTime date) async {
    final key = _dateKey(date);
    if (_noSpendDays.get(key) != null) return true;
    final expenses = _expenseProvider;
    if (expenses == null || expenses.hasExpensesOn(date)) return false;
    await _noSpendDays.put(
      key,
      NoSpendDayMark(date: _dateOnly(date), markedAt: DateTime.now()),
    );
    await expenses.recordNoSpendCompletion(date);
    AnalyticsService.instance.capture('no_spend_day_logged');
    await refreshOwlState();
    notifyListeners();
    return true;
  }

  // --- Complete-log days (Layer 2 bonus — does NOT gate the streak) ---

  /// 2026-07-05 design decision: raising the streak's daily requirement from
  /// 1 log to a fixed count (e.g. 3-5) was considered and rejected — a fixed
  /// count is arbitrary and unfair on days a user genuinely only spent once,
  /// and it would raise the core loop's daily friction right after the
  /// opposite direction (lowering psychological pressure to "just log your
  /// biggest expense") was chosen. Instead this is a self-declared, opt-in
  /// bonus — mirrors NoSpendDayMark's honesty-based pattern, since there's
  /// no bank sync to verify true completeness against. It only feeds
  /// [careScore] as an optional depth layer for more engaged users; the
  /// streak itself is untouched.
  bool isCompleteLogDay(DateTime date) =>
      _completeLogDays.get(_dateKey(date)) != null;

  /// Idempotent — marking an already-marked day is a no-op.
  Future<void> markCompleteLogDay(DateTime date) async {
    final key = _dateKey(date);
    if (_completeLogDays.get(key) != null) return;
    await _completeLogDays.put(
      key,
      CompleteLogDayMark(date: _dateOnly(date), markedAt: DateTime.now()),
    );
    AnalyticsService.instance.capture('complete_log_day_marked');
    await refreshOwlState();
    notifyListeners();
  }

  // --- Category "boss battle" (Layer 2) ---

  List<CategoryChallengeResult> get categoryChallengeResults =>
      _categoryResults.values.toList();

  CategoryChallengeResult? get pendingCategoryCelebration {
    for (final result in _categoryResults.values) {
      if (result.won && !result.celebrationShown) return result;
    }
    return null;
  }

  Future<void> markCategoryCelebrationShown(String resultId) async {
    final result = _categoryResults.get(resultId);
    if (result == null) return;
    await _categoryResults.put(
      resultId,
      result.copyWith(celebrationShown: true),
    );
    notifyListeners();
  }

  /// Idempotent and safe to call repeatedly (app start, first screen build
  /// each session). Evaluates the previous calendar month's spend-vs-limit
  /// for every category, exactly once per month boundary crossed. On the
  /// very first-ever call there is nothing to evaluate retroactively (no
  /// prior "previous month" the app was actually used for) — this just
  /// records today as the baseline so evaluation starts from the *next*
  /// month boundary, avoiding a spurious trivial "win" for a month that
  /// predates any real usage.
  Future<List<CategoryChallengeResult>> evaluateMonthBoundaryIfNeeded() async {
    final expenseProvider = _expenseProvider;
    final categoryProvider = _categoryProvider;
    if (expenseProvider == null || categoryProvider == null) return [];

    final now = DateTime.now();
    final lastCheckStr =
        _settings.get(SettingsKeys.lastMonthBoundaryCheck) as String?;

    if (lastCheckStr == null) {
      await _settings.put(
        SettingsKeys.lastMonthBoundaryCheck,
        now.toIso8601String(),
      );
      return [];
    }

    final lastCheck = DateTime.parse(lastCheckStr);
    if (lastCheck.year == now.year && lastCheck.month == now.month) {
      return [];
    }

    final prevMonthDate = DateTime(now.year, now.month - 1, 1);
    final wins = <CategoryChallengeResult>[];
    for (final category in categoryProvider.all) {
      if (category.monthlyLimit <= 0)
        continue; // no challenge set — same convention as _totalMonthlyBudget
      final id =
          '${category.id}_${prevMonthDate.year}-${prevMonthDate.month.toString().padLeft(2, '0')}';
      if (_categoryResults.get(id) != null) continue; // already evaluated
      final spend = expenseProvider.spendForCategoryInMonth(
        category.id,
        prevMonthDate,
      );
      final won = spend <= category.monthlyLimit;
      final result = CategoryChallengeResult(
        id: id,
        categoryId: category.id,
        year: prevMonthDate.year,
        month: prevMonthDate.month,
        limit: category.monthlyLimit,
        actualSpend: spend,
        won: won,
        evaluatedAt: now,
      );
      await _categoryResults.put(id, result);
      if (won) {
        AnalyticsService.instance.capture(
          'category_challenge_won',
          properties: {'category_id': category.id},
        );
        wins.add(result);
      }
    }
    await _evaluateMonthlySavings(
      categoryProvider,
      expenseProvider,
      prevMonthDate,
      now,
    );
    await _settings.put(
      SettingsKeys.lastMonthBoundaryCheck,
      now.toIso8601String(),
    );
    await refreshOwlState();
    notifyListeners();
    return wins;
  }

  /// The monthly "you spent less than average" recap — same idempotent
  /// once-per-month-boundary evaluation as the category boss battles above,
  /// just a single aggregate number instead of per-category detail. See
  /// computeMonthlySavings for the real-BLS-benchmark comparison logic.
  Future<void> _evaluateMonthlySavings(
    CategoryProvider categoryProvider,
    ExpenseProvider expenseProvider,
    DateTime prevMonthDate,
    DateTime now,
  ) async {
    final id =
        '${prevMonthDate.year}-${prevMonthDate.month.toString().padLeft(2, '0')}';
    if (_monthlySavingsResults.get(id) != null) return;
    final spendByName = <String, double>{
      for (final category in categoryProvider.all)
        category.name: expenseProvider.spendForCategoryInMonth(
          category.id,
          prevMonthDate,
        ),
    };
    final totalSaved = computeMonthlySavings(spendByName);
    await _monthlySavingsResults.put(
      id,
      MonthlySavingsResult(
        id: id,
        year: prevMonthDate.year,
        month: prevMonthDate.month,
        totalSaved: totalSaved,
        evaluatedAt: now,
      ),
    );
    if (totalSaved > 0) {
      // Event name only — never the actual dollar figure, same rule as
      // every other analytics call in this app.
      AnalyticsService.instance.capture('monthly_savings_positive');
    }
  }

  /// A positive monthly savings recap that hasn't been shown yet — mirrors
  /// [pendingCelebration]/[pendingCategoryCelebration]. A $0-saved month
  /// (nothing beat the benchmark, or no comparable categories tracked) is
  /// never pending — there's nothing worth celebrating in that case.
  MonthlySavingsResult? get pendingMonthlySavingsCelebration {
    for (final result in _monthlySavingsResults.values) {
      if (result.totalSaved > 0 && !result.celebrationShown) return result;
    }
    return null;
  }

  /// Every evaluated month, most recent first — including $0 months. The
  /// celebration screen only ever shows the positive-savings moment once;
  /// this is what makes that data visible again afterward (previously it
  /// was computed, persisted, shown once, and then effectively invisible —
  /// no UI anywhere let you look back and ask "how did last month go?").
  /// Showing $0 months too, not just wins, is a deliberate honesty choice:
  /// cherry-picking only the good months would make this decorative
  /// rather than a real record.
  List<MonthlySavingsResult> get monthlySavingsHistory {
    final results = _monthlySavingsResults.values.toList();
    results.sort(
      (a, b) => b.id.compareTo(a.id),
    ); // "yyyy-MM" sorts correctly as a string
    return results;
  }

  Future<void> markMonthlySavingsCelebrationShown(String resultId) async {
    final result = _monthlySavingsResults.get(resultId);
    if (result == null) return;
    await _monthlySavingsResults.put(
      resultId,
      result.copyWith(celebrationShown: true),
    );
    notifyListeners();
  }

  // --- Buddy weekly mini-challenge (Layer 2, local scaffold only) ---

  /// Computed live from real local DailyLogCompletion data over the last 7
  /// days — no persistence needed for this, it's a view over data that
  /// already exists. The partner side has no real data source yet (no
  /// backend), so the UI must show an honest "waiting to sync" state rather
  /// than fabricate a number — see settings_screen.dart's _BuddyStreakTile.
  int get currentWeekLoggedDaysCount {
    final expenseProvider = _expenseProvider;
    if (expenseProvider == null) return 0;
    var count = 0;
    final today = _dateOnly(DateTime.now());
    for (var i = 0; i < 7; i++) {
      final day = today.subtract(Duration(days: i));
      final completion = expenseProvider.completionOn(day);
      if (completion != null &&
          (completion.loggedAnyExpense ||
              completion.completedNoSpend ||
              completion.usedStreakFreeze)) {
        count++;
      }
    }
    return count;
  }

  // --- Companion owl (Layer 3) ---

  /// A category win counts toward mood for roughly one evaluation cycle
  /// after it happened — category wins are always retrospective (evaluated
  /// at a month boundary, about the month that just ended), so "recent"
  /// here means "from the most recent evaluation," not "this calendar
  /// month" literally.
  static const _recentWinWindow = Duration(days: 35);

  int get _recentCategoryWinCount {
    final cutoff = DateTime.now().subtract(_recentWinWindow);
    return _categoryResults.values
        .where((r) => r.won && r.evaluatedAt.isAfter(cutoff))
        .length;
  }

  /// Computed live from real streak/challenge data every time — never
  /// stored as the source of truth. See OwlMood for the emoji/copy per
  /// state and docs/technical-architecture.md for the design rationale.
  OwlMood get currentMood {
    final expenseProvider = _expenseProvider;
    if (expenseProvider == null) return OwlMood.sleeping;
    final streak = expenseProvider.currentStreak;
    if (streak == 0) return OwlMood.sleeping;

    final loggedToday = expenseProvider.loggedToday;
    final isEvening = DateTime.now().hour >= 18;
    final atRisk = !loggedToday && isEvening;
    if (atRisk) return OwlMood.hungry;

    if (streak >= 100 || _recentCategoryWinCount >= 2) return OwlMood.thriving;
    if (streak >= 30 || (streak >= 7 && _recentCategoryWinCount >= 1))
      return OwlMood.happy;
    return OwlMood.content;
  }

  /// A derived, on-demand accumulator over data that already exists
  /// elsewhere (logged days, category wins, no-spend days, complete-log
  /// days, badges) — deliberately never imperatively incremented at each
  /// trigger point, which would risk drifting out of sync with the
  /// underlying records.
  int get careScore {
    final expenseProvider = _expenseProvider;
    if (expenseProvider == null) return 0;
    final loggedDays = expenseProvider.totalLoggedDaysCount;
    final categoryWins = _categoryResults.values.where((r) => r.won).length;
    final noSpendDays = _noSpendDays.length;
    final completeLogDays = _completeLogDays.length;
    final badges = _badges.length;
    return loggedDays * 1 +
        categoryWins * 3 +
        noSpendDays * 5 +
        completeLogDays * 3 +
        badges * 10;
  }

  /// Coarse, long-term tier over [careScore] — separate from the day-to-day
  /// [currentMood]. Thresholds are a planning estimate, not load-bearing.
  int get evolutionStage {
    final score = careScore;
    if (score < 30) return 0;
    if (score < 120) return 1;
    if (score < 365) return 2;
    return 3;
  }

  String get evolutionStageName => EvolutionStages.names[evolutionStage];

  /// Recomputes mood/stage and persists only when something actually
  /// changed — this both avoids needless Hive writes and ensures
  /// `owl_evolved` only fires on genuine stage transitions, not every call.
  /// A genuine transition also arms [pendingOwlEvolutionCelebration] so the
  /// UI can show a real full-screen moment for it instead of the silent
  /// text-label swap this used to be.
  Future<void> refreshOwlState() async {
    final mood = currentMood;
    final stage = evolutionStage;
    final existing = _owlStateBox.get('owl');
    if (existing != null &&
        existing.moodLevel == mood.index &&
        existing.evolutionStage == stage) {
      return;
    }
    final previousStage = existing?.evolutionStage;
    final justEvolved = previousStage != null && stage != previousStage;
    await _owlStateBox.put(
      'owl',
      OwlState(
        moodLevel: mood.index,
        totalCareScore: careScore,
        lastUpdated: DateTime.now(),
        evolutionStage: stage,
        evolutionCelebrationShown: !justEvolved,
      ),
    );
    if (justEvolved) {
      AnalyticsService.instance.capture(
        'owl_evolved',
        properties: {'new_stage': stage},
      );
    }
    notifyListeners();
  }

  /// An owl-evolution celebration that hasn't been shown yet — mirrors
  /// [pendingCelebration] for badges. Surfaced on the next natural Today
  /// screen visit rather than the instant it happens, same reasoning as
  /// badges (don't celebrate before the user has even opened a screen).
  bool get pendingOwlEvolutionCelebration {
    final state = _owlStateBox.get('owl');
    return state != null && !state.evolutionCelebrationShown;
  }

  Future<void> markOwlEvolutionCelebrationShown() async {
    final state = _owlStateBox.get('owl');
    if (state == null) return;
    await _owlStateBox.put(
      'owl',
      state.copyWith(evolutionCelebrationShown: true),
    );
    notifyListeners();
  }

  /// Single orchestration entry point for "something just happened that
  /// might earn a badge and/or change the owl's mood" — called from the
  /// log-expense confirm flow instead of two separate provider calls.
  Future<BadgeRecord?> onExpenseLogged(int currentStreak) async {
    final badge = await checkForNewMilestone(currentStreak);
    await refreshOwlState();
    return badge;
  }
}

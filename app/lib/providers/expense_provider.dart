import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../config/constants.dart';
import '../models/category.dart';
import '../models/daily_log_completion.dart';
import '../models/expense.dart';
import '../services/analytics_service.dart';

/// Owns expenses, daily-log completions, and the streak/freeze mechanics
/// built on top of them. See docs/technical-architecture.md for the
/// mechanic design (loss-aversion streak framing, streak-freeze safety
/// net) and docs/product-design.md for how it surfaces on the Today screen.
class ExpenseProvider extends ChangeNotifier {
  late Box<Expense> _expenseBox;
  late Box<DailyLogCompletion> _completionBox;
  late Box<ExpenseCategory> _categoryBox;
  late Box _settings;
  final _uuid = const Uuid();

  void load() {
    _expenseBox = Hive.box<Expense>(HiveBoxes.expenses);
    _completionBox = Hive.box<DailyLogCompletion>(HiveBoxes.dailyLogCompletions);
    _categoryBox = Hive.box<ExpenseCategory>(HiveBoxes.categories);
    _settings = Hive.box(HiveBoxes.settings);
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
  String _key(DateTime d) => _dateOnly(d).toIso8601String();

  // --- Expenses ---

  List<Expense> get todayExpenses {
    final today = _dateOnly(DateTime.now());
    return _expenseBox.values.where((e) => _dateOnly(e.date) == today).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  double get todaySpend => todayExpenses.fold(0.0, (sum, e) => sum + e.amount);

  double spendForCategoryToday(String categoryId) =>
      todayExpenses.where((e) => e.categoryId == categoryId).fold(0.0, (s, e) => s + e.amount);

  List<Expense> expensesOn(DateTime date) {
    final d = _dateOnly(date);
    return _expenseBox.values.where((e) => _dateOnly(e.date) == d).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  double get monthToDateSpend {
    final now = DateTime.now();
    return _expenseBox.values
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .fold(0.0, (s, e) => s + e.amount);
  }

  Map<String, double> spendByCategoryInMonth(DateTime month) {
    final map = <String, double>{};
    for (final e in _expenseBox.values) {
      if (e.date.year == month.year && e.date.month == month.month) {
        map[e.categoryId] = (map[e.categoryId] ?? 0) + e.amount;
      }
    }
    return map;
  }

  /// Single-category convenience wrapper around [spendByCategoryInMonth] —
  /// used by the category "boss battle" month-end evaluation and the
  /// in-progress boss-health-bar display. See GamificationProvider.
  double spendForCategoryInMonth(String categoryId, DateTime month) {
    return spendByCategoryInMonth(month)[categoryId] ?? 0.0;
  }

  Future<void> addExpense({required double amount, required String categoryId, String note = ''}) async {
    final expense = Expense(id: _uuid.v4(), amount: amount, categoryId: categoryId, note: note, date: DateTime.now());
    await _expenseBox.put(expense.id, expense);
    await _recordTodayCompletion();
    AnalyticsService.instance.capture('expense_logged');
    notifyListeners();
  }

  Future<void> deleteExpense(String id) async {
    await _expenseBox.delete(id);
    notifyListeners();
  }

  double get _totalMonthlyBudget => _categoryBox.values.fold(0.0, (s, c) => s + c.monthlyLimit);

  Future<void> _recordTodayCompletion() async {
    final today = _dateOnly(DateTime.now());
    final budget = _totalMonthlyBudget;
    final withinBudget = budget <= 0 || monthToDateSpend <= budget;
    await _completionBox.put(
      _key(today),
      DailyLogCompletion(date: today, loggedAnyExpense: true, withinBudget: withinBudget),
    );
  }

  // --- Streak & completions ---

  DailyLogCompletion? completionOn(DateTime date) => _completionBox.get(_key(date));

  bool get loggedToday => completionOn(DateTime.now()) != null;

  int get freeStreakFreezesAvailable =>
      _settings.get(SettingsKeys.freeStreakFreezesAvailable, defaultValue: 1) as int;

  Future<void> setFreeStreakFreezesAvailable(int value) async {
    await _settings.put(SettingsKeys.freeStreakFreezesAvailable, value);
  }

  /// Call once on app start. If yesterday has no completion but the day
  /// before it does (an active streak interrupted by exactly one gap),
  /// auto-consumes a freeze rather than letting the streak zero out — this
  /// is the "what-the-hell effect" fix, and it's friction-free by design
  /// (no user action required).
  Future<bool> checkAndApplyStreakFreeze() async {
    final today = _dateOnly(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));
    final dayBefore = yesterday.subtract(const Duration(days: 1));
    if (completionOn(yesterday) != null) return false;
    final dayBeforeCompletion = completionOn(dayBefore);
    final hadActiveStreak =
        dayBeforeCompletion != null && (dayBeforeCompletion.loggedAnyExpense || dayBeforeCompletion.usedStreakFreeze);
    if (!hadActiveStreak || freeStreakFreezesAvailable <= 0) return false;
    await _completionBox.put(
      _key(yesterday),
      DailyLogCompletion(date: yesterday, loggedAnyExpense: false, withinBudget: true, usedStreakFreeze: true),
    );
    await setFreeStreakFreezesAvailable(freeStreakFreezesAvailable - 1);
    AnalyticsService.instance.capture('streak_freeze_used');
    notifyListeners();
    return true;
  }

  /// Duolingo-style: counts consecutive logged/frozen days ending today if
  /// today is already logged, otherwise ending yesterday (today still
  /// "counts" once logged — this is why the UI shows the pre-today streak
  /// with loss-aversion copy rather than showing 0 at the start of the day).
  int get currentStreak {
    var count = 0;
    var cursor = _dateOnly(DateTime.now());
    if (completionOn(cursor) == null) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    while (true) {
      final completion = completionOn(cursor);
      if (completion == null || !(completion.loggedAnyExpense || completion.usedStreakFreeze)) break;
      count++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return count;
  }

  /// All-time count of days with a real log (excludes frozen days) — used
  /// by the companion cat's care-score accumulator. Not the same as
  /// [currentStreak], which only counts the *current* consecutive run.
  int get totalLoggedDaysCount => _completionBox.values.where((c) => c.loggedAnyExpense).length;
}

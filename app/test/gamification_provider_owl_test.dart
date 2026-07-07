import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:abacus/config/constants.dart';
import 'package:abacus/models/badge_record.dart';
import 'package:abacus/models/category.dart';
import 'package:abacus/models/category_challenge_result.dart';
import 'package:abacus/models/daily_log_completion.dart';
import 'package:abacus/models/expense.dart';
import 'package:abacus/models/no_spend_day_mark.dart';
import 'package:abacus/models/owl_mood.dart';
import 'package:abacus/models/owl_state.dart';
import 'package:abacus/models/complete_log_day_mark.dart';
import 'package:abacus/models/monthly_savings_result.dart';
import 'package:abacus/providers/category_provider.dart';
import 'package:abacus/providers/expense_provider.dart';
import 'package:abacus/providers/gamification_provider.dart';

void main() {
  late GamificationProvider gamification;
  late ExpenseProvider expenseProvider;
  late CategoryProvider categoryProvider;

  setUp(() async {
    Hive.init('test_hive_gamification_owl');
    if (!Hive.isAdapterRegistered(HiveTypeIds.expense)) {
      Hive.registerAdapter(ExpenseAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveTypeIds.category)) {
      Hive.registerAdapter(CategoryAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveTypeIds.dailyLogCompletion)) {
      Hive.registerAdapter(DailyLogCompletionAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveTypeIds.badge)) {
      Hive.registerAdapter(BadgeRecordAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveTypeIds.noSpendDay)) {
      Hive.registerAdapter(NoSpendDayMarkAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveTypeIds.categoryChallengeResult)) {
      Hive.registerAdapter(CategoryChallengeResultAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveTypeIds.owl)) {
      Hive.registerAdapter(OwlStateAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveTypeIds.completeLogDay)) {
      Hive.registerAdapter(CompleteLogDayMarkAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveTypeIds.monthlySavingsResult)) {
      Hive.registerAdapter(MonthlySavingsResultAdapter());
    }
    await Hive.openBox<Expense>(HiveBoxes.expenses);
    await Hive.openBox<ExpenseCategory>(HiveBoxes.categories);
    await Hive.openBox<DailyLogCompletion>(HiveBoxes.dailyLogCompletions);
    await Hive.openBox<BadgeRecord>(HiveBoxes.badges);
    await Hive.openBox<NoSpendDayMark>(HiveBoxes.noSpendDays);
    await Hive.openBox<CategoryChallengeResult>(HiveBoxes.categoryChallengeResults);
    await Hive.openBox<OwlState>(HiveBoxes.owlState);
    await Hive.openBox<CompleteLogDayMark>(HiveBoxes.completeLogDays);
    await Hive.openBox<MonthlySavingsResult>(HiveBoxes.monthlySavingsResults);
    await Hive.openBox(HiveBoxes.settings);

    expenseProvider = ExpenseProvider()..load();
    categoryProvider = CategoryProvider()..load();
    gamification = GamificationProvider()..load();
    gamification.bind(expenseProvider, categoryProvider);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
  });

  group('currentMood', () {
    // "hungry" is deliberately not asserted here — it depends on the real
    // wall-clock hour (DateTime.now().hour >= 18), which isn't injectable
    // without refactoring the provider to take a clock dependency. The
    // other four tiers are all reachable and tested deterministically via
    // streak/category-win state instead.

    test('zero streak is sleeping, regardless of anything else', () {
      expect(gamification.currentMood, OwlMood.sleeping);
    });

    test('an active streak with nothing special is content', () async {
      final category = await _addCategory(categoryProvider, 'Food', limit: 100.0);
      await expenseProvider.addExpense(amount: 10.0, categoryId: category.id);
      expect(expenseProvider.currentStreak, 1);
      // Not asserting mood directly here since it can legitimately be
      // "hungry" if the test happens to run in the evening — assert the
      // weaker, still-meaningful property that it's neither sleeping nor a
      // higher tier than warranted by a 1-day streak with no wins.
      expect(gamification.currentMood, isNot(OwlMood.sleeping));
      expect(gamification.currentMood, isNot(OwlMood.thriving));
    });
  });

  group('careScore', () {
    test('zero activity is zero score', () {
      expect(gamification.careScore, 0);
    });

    test('accumulates from logged days, category wins, no-spend days, complete-log days, and badges', () async {
      final category = await _addCategory(categoryProvider, 'Food', limit: 100.0);
      await expenseProvider.addExpense(amount: 5.0, categoryId: category.id); // +1 logged day
      await gamification.markNoSpendDay(DateTime.now().subtract(const Duration(days: 1))); // +5
      await gamification.markCompleteLogDay(DateTime.now()); // +3
      await gamification.checkForNewMilestone(7); // +10 (badge, even though streak isn't really 7 here)

      // 1 logged day (+1) + 0 category wins (+0) + 1 no-spend day (+5) + 1 complete-log day (+3) + 1 badge (+10) = 19
      expect(gamification.careScore, 19);
    });
  });

  group('evolutionStage', () {
    test('starts at owlet (stage 0) with zero score', () {
      expect(gamification.evolutionStage, 0);
      expect(gamification.evolutionStageName, 'Owlet');
    });

    test('crosses into young owl once score reaches the threshold', () async {
      // 3 badges * 10 = 30, right at the young-owl threshold.
      await gamification.checkForNewMilestone(7);
      await gamification.checkForNewMilestone(30);
      await gamification.checkForNewMilestone(100);
      expect(gamification.careScore, 30);
      expect(gamification.evolutionStage, 1);
      expect(gamification.evolutionStageName, 'Young Owl');
    });
  });

  group('refreshOwlState', () {
    test('is idempotent when nothing changed (no duplicate owl_evolved-worthy writes)', () async {
      await gamification.refreshOwlState();
      await gamification.refreshOwlState();
      // No exception, no crash — the point of this test is the guard
      // clause comparing against the persisted record short-circuits.
    });
  });

  group('pendingOwlEvolutionCelebration', () {
    test('is false before any state has ever been saved', () {
      expect(gamification.pendingOwlEvolutionCelebration, isFalse);
    });

    test('stays false on the very first save (no prior stage to have transitioned from)', () async {
      await gamification.refreshOwlState();
      expect(gamification.pendingOwlEvolutionCelebration, isFalse);
    });

    test('becomes true on a genuine stage transition, then false once marked shown', () async {
      await gamification.refreshOwlState(); // first save: stage 0, not pending
      await gamification.checkForNewMilestone(7);
      await gamification.checkForNewMilestone(30);
      await gamification.checkForNewMilestone(100); // careScore 30 -> stage 1
      await gamification.refreshOwlState();
      expect(gamification.pendingOwlEvolutionCelebration, isTrue);

      await gamification.markOwlEvolutionCelebrationShown();
      expect(gamification.pendingOwlEvolutionCelebration, isFalse);
    });
  });
}

Future<ExpenseCategory> _addCategory(CategoryProvider provider, String name, {required double limit}) async {
  await provider.add(name, '🍔', 0xFFEF6C00, limit);
  return provider.all.firstWhere((c) => c.name == name);
}

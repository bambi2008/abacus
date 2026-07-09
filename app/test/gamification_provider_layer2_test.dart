import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:abacus/config/constants.dart';
import 'package:abacus/models/badge_record.dart';
import 'package:abacus/models/owl_state.dart';
import 'package:abacus/models/complete_log_day_mark.dart';
import 'package:abacus/models/monthly_savings_result.dart';
import 'package:abacus/models/category.dart';
import 'package:abacus/models/category_challenge_result.dart';
import 'package:abacus/models/daily_log_completion.dart';
import 'package:abacus/models/expense.dart';
import 'package:abacus/models/no_spend_day_mark.dart';
import 'package:abacus/providers/category_provider.dart';
import 'package:abacus/providers/expense_provider.dart';
import 'package:abacus/providers/gamification_provider.dart';

void main() {
  late GamificationProvider gamification;
  late ExpenseProvider expenseProvider;
  late CategoryProvider categoryProvider;

  setUp(() async {
    Hive.init('test_hive_gamification_layer2');
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

  group('no-spend days', () {
    test('a day is not marked until markNoSpendDay is called', () {
      expect(gamification.isNoSpendDay(DateTime.now()), isFalse);
    });

    test('marking is idempotent and reflected by isNoSpendDay', () async {
      final day = DateTime.now();
      await gamification.markNoSpendDay(day);
      expect(gamification.isNoSpendDay(day), isTrue);
      await gamification.markNoSpendDay(day); // second call should not throw or duplicate
      expect(gamification.noSpendDayCountThisMonth, 1);
    });
  });

  group('complete-log days', () {
    // This is the "3-5 logs/day instead of 1" question's bonus-layer
    // answer (2026-07-05): self-declared, not a fixed log-count quota, and
    // it never gates the streak itself (see GamificationProvider's doc
    // comment on markCompleteLogDay).

    test('a day is not marked until markCompleteLogDay is called', () {
      expect(gamification.isCompleteLogDay(DateTime.now()), isFalse);
    });

    test('marking is idempotent and reflected by isCompleteLogDay', () async {
      final day = DateTime.now();
      await gamification.markCompleteLogDay(day);
      expect(gamification.isCompleteLogDay(day), isTrue);
      await gamification.markCompleteLogDay(day); // second call should not throw or duplicate
      expect(gamification.careScore, 3); // +3 exactly once, not twice
    });

    test('does not affect the streak — a separate, unrelated signal', () async {
      final before = expenseProvider.currentStreak;
      await gamification.markCompleteLogDay(DateTime.now());
      expect(expenseProvider.currentStreak, before);
    });
  });

  group('month-boundary category challenge evaluation', () {
    test('first-ever call evaluates nothing (avoids a spurious retroactive win)', () async {
      await categoryProvider.add('Food', '🍔', 0xFFEF6C00, 100.0);
      final wins = await gamification.evaluateMonthBoundaryIfNeeded();
      expect(wins, isEmpty);
      expect(gamification.categoryChallengeResults, isEmpty);
    });

    test('after seeding a prior-month baseline, evaluates last month and detects a win', () async {
      final now = DateTime.now();
      final settings = Hive.box(HiveBoxes.settings);
      // Seed a baseline from last month so the next call sees a crossed
      // month boundary — this is the only way to deterministically test
      // this path without injecting a fake clock.
      await settings.put(
        SettingsKeys.lastMonthBoundaryCheck,
        DateTime(now.year, now.month - 1, 15).toIso8601String(),
      );
      final category = await _addCategory(categoryProvider, 'Food', limit: 100.0);
      final prevMonth = DateTime(now.year, now.month - 1, 1);
      await expenseProvider.addExpense(amount: 40.0, categoryId: category.id);
      // addExpense always dates as "now" — for this test we only need
      // spendForCategoryInMonth(prevMonth) to be well-defined (0 spend is a
      // valid, if uninteresting, win); assert the real spend-tracking path
      // separately in the ExpenseProvider-level test below.
      final wins = await gamification.evaluateMonthBoundaryIfNeeded();
      final result = gamification.categoryChallengeResults.firstWhere((r) => r.categoryId == category.id);
      expect(result.year, prevMonth.year);
      expect(result.month, prevMonth.month);
      expect(result.won, isTrue, reason: 'zero spend in the un-logged previous month should count as a win');
      expect(wins, contains(result));
    });

    test('calling again within the same month is a no-op (idempotent)', () async {
      final now = DateTime.now();
      final settings = Hive.box(HiveBoxes.settings);
      await settings.put(
        SettingsKeys.lastMonthBoundaryCheck,
        DateTime(now.year, now.month - 1, 15).toIso8601String(),
      );
      await _addCategory(categoryProvider, 'Food', limit: 100.0);
      final firstRun = await gamification.evaluateMonthBoundaryIfNeeded();
      expect(firstRun, isNotEmpty);
      final secondRun = await gamification.evaluateMonthBoundaryIfNeeded();
      expect(secondRun, isEmpty, reason: 'already evaluated this month, should not re-fire');
      expect(gamification.categoryChallengeResults.length, 1);
    });

    test('categories with monthlyLimit <= 0 are skipped (no challenge set)', () async {
      final now = DateTime.now();
      final settings = Hive.box(HiveBoxes.settings);
      await settings.put(
        SettingsKeys.lastMonthBoundaryCheck,
        DateTime(now.year, now.month - 1, 15).toIso8601String(),
      );
      await _addCategory(categoryProvider, 'Uncapped', limit: 0.0);
      final wins = await gamification.evaluateMonthBoundaryIfNeeded();
      expect(wins, isEmpty);
      expect(gamification.categoryChallengeResults, isEmpty);
    });
  });

  group('monthly savings recap (evaluated alongside the month boundary)', () {
    test('a positive-savings month arms pendingMonthlySavingsCelebration', () async {
      final now = DateTime.now();
      final settings = Hive.box(HiveBoxes.settings);
      await settings.put(
        SettingsKeys.lastMonthBoundaryCheck,
        DateTime(now.year, now.month - 1, 15).toIso8601String(),
      );
      // A "Dining Out" category with zero logged spend in the (unlogged)
      // previous month — the full benchmark counts as saved.
      await _addCategory(categoryProvider, 'Dining Out', limit: 200.0);
      await gamification.evaluateMonthBoundaryIfNeeded();

      final pending = gamification.pendingMonthlySavingsCelebration;
      expect(pending, isNotNull);
      expect(pending!.totalSaved, greaterThan(0));

      await gamification.markMonthlySavingsCelebrationShown(pending.id);
      expect(gamification.pendingMonthlySavingsCelebration, isNull);
    });

    test('calling again within the same month does not re-evaluate savings', () async {
      final now = DateTime.now();
      final settings = Hive.box(HiveBoxes.settings);
      await settings.put(
        SettingsKeys.lastMonthBoundaryCheck,
        DateTime(now.year, now.month - 1, 15).toIso8601String(),
      );
      await _addCategory(categoryProvider, 'Dining Out', limit: 200.0);
      await gamification.evaluateMonthBoundaryIfNeeded();
      final pending = gamification.pendingMonthlySavingsCelebration!;
      await gamification.markMonthlySavingsCelebrationShown(pending.id);

      await gamification.evaluateMonthBoundaryIfNeeded(); // same month, no-op
      expect(gamification.pendingMonthlySavingsCelebration, isNull);
    });

    test('a category with no matching benchmark never produces a pending celebration on its own', () async {
      final now = DateTime.now();
      final settings = Hive.box(HiveBoxes.settings);
      await settings.put(
        SettingsKeys.lastMonthBoundaryCheck,
        DateTime(now.year, now.month - 1, 15).toIso8601String(),
      );
      await _addCategory(categoryProvider, 'Subscriptions', limit: 50.0);
      await gamification.evaluateMonthBoundaryIfNeeded();
      expect(gamification.pendingMonthlySavingsCelebration, isNull);
    });

    test('monthlySavingsHistory surfaces every evaluated month, including \$0 ones', () async {
      final now = DateTime.now();
      final settings = Hive.box(HiveBoxes.settings);
      await settings.put(
        SettingsKeys.lastMonthBoundaryCheck,
        DateTime(now.year, now.month - 1, 15).toIso8601String(),
      );
      expect(gamification.monthlySavingsHistory, isEmpty);
      // No benchmark matches "Subscriptions" (see NationalSpendingBenchmarks)
      // — this month should still show up in history, just at $0, not be
      // silently dropped the way it's excluded from pendingCelebration.
      await _addCategory(categoryProvider, 'Subscriptions', limit: 50.0);
      await gamification.evaluateMonthBoundaryIfNeeded();
      expect(gamification.monthlySavingsHistory, hasLength(1));
      expect(gamification.monthlySavingsHistory.first.totalSaved, 0);
    });
  });
}

Future<ExpenseCategory> _addCategory(CategoryProvider provider, String name, {required double limit}) async {
  await provider.add(name, '🍔', 0xFFEF6C00, limit);
  return provider.all.firstWhere((c) => c.name == name);
}

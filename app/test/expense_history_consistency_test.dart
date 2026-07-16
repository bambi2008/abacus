import 'dart:io';

import 'package:abacus/config/constants.dart';
import 'package:abacus/models/category.dart';
import 'package:abacus/models/daily_log_completion.dart';
import 'package:abacus/models/expense.dart';
import 'package:abacus/providers/expense_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory directory;
  late ExpenseProvider provider;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('abacus_history_test_');
    Hive.init(directory.path);
    if (!Hive.isAdapterRegistered(HiveTypeIds.expense)) {
      Hive.registerAdapter(ExpenseAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveTypeIds.category)) {
      Hive.registerAdapter(CategoryAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveTypeIds.dailyLogCompletion)) {
      Hive.registerAdapter(DailyLogCompletionAdapter());
    }
    await Hive.openBox<Expense>(HiveBoxes.expenses);
    await Hive.openBox<ExpenseCategory>(HiveBoxes.categories);
    await Hive.openBox<DailyLogCompletion>(HiveBoxes.dailyLogCompletions);
    await Hive.openBox(HiveBoxes.settings);
    await Hive.box<ExpenseCategory>(HiveBoxes.categories).put(
      'food',
      ExpenseCategory(
        id: 'food',
        name: 'Food',
        emoji: '🍜',
        colorValue: 0xFF000000,
        monthlyLimit: 300,
      ),
    );
    provider = ExpenseProvider()..load();
  });

  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test(
    'moving the only transaction repairs both daily streak records',
    () async {
      await provider.addExpense(amount: 12, categoryId: 'food');
      final original = provider.allExpenses.single;
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));

      await provider.updateExpense(original.copyWith(date: yesterday));

      expect(provider.completionOn(today), isNull);
      expect(provider.completionOn(yesterday)?.loggedAnyExpense, isTrue);
    },
  );

  test(
    'a deliberate no-spend completion counts without inventing an expense',
    () async {
      final today = DateTime.now();
      await provider.recordNoSpendCompletion(today);

      expect(provider.allExpenses, isEmpty);
      expect(provider.completionOn(today)?.completedNoSpend, isTrue);
      expect(provider.loggedToday, isTrue);
    },
  );
}

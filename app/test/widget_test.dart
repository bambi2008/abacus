import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'package:abacus/app.dart';
import 'package:abacus/config/constants.dart';
import 'package:abacus/models/category.dart';
import 'package:abacus/models/daily_log_completion.dart';
import 'package:abacus/models/expense.dart';
import 'package:abacus/providers/category_provider.dart';
import 'package:abacus/providers/expense_provider.dart';
import 'package:abacus/providers/onboarding_provider.dart';
import 'package:abacus/providers/subscription_provider.dart';

void main() {
  setUp(() async {
    Hive.init('test_hive_widget');
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
    final settings = await Hive.openBox(HiveBoxes.settings);
    await settings.put(SettingsKeys.hasOnboarded, true);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
  });

  testWidgets('app builds and shows bottom navigation', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => OnboardingProvider()..load()),
          ChangeNotifierProvider(create: (_) => CategoryProvider()..load()),
          ChangeNotifierProvider(create: (_) => ExpenseProvider()..load()),
          ChangeNotifierProvider(create: (_) => SubscriptionProvider()..load()),
        ],
        child: const AbacusApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Today'), findsWidgets);
  });
}

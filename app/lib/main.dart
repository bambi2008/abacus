import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'config/constants.dart';
import 'models/badge_record.dart';
import 'models/category.dart';
import 'models/daily_log_completion.dart';
import 'models/expense.dart';
import 'providers/category_provider.dart';
import 'providers/expense_provider.dart';
import 'providers/gamification_provider.dart';
import 'providers/onboarding_provider.dart';
import 'providers/subscription_provider.dart';
import 'services/analytics_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
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
  await Hive.openBox<Expense>(HiveBoxes.expenses);
  await Hive.openBox<ExpenseCategory>(HiveBoxes.categories);
  await Hive.openBox<DailyLogCompletion>(HiveBoxes.dailyLogCompletions);
  await Hive.openBox<BadgeRecord>(HiveBoxes.badges);
  await Hive.openBox(HiveBoxes.settings);
  await AnalyticsService.instance.init();
  AnalyticsService.instance.capture('app_opened');

  final expenseProvider = ExpenseProvider()..load();
  await expenseProvider.checkAndApplyStreakFreeze();
  final gamificationProvider = GamificationProvider()..load();
  // Catch a milestone reached while the app was closed — recorded silently
  // here, the celebration itself is shown on the next Today screen visit
  // (see GamificationProvider.pendingCelebration).
  await gamificationProvider.checkForNewMilestone(expenseProvider.currentStreak);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => OnboardingProvider()..load()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()..load()),
        ChangeNotifierProvider.value(value: expenseProvider),
        ChangeNotifierProvider.value(value: gamificationProvider),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()..load()..init()),
      ],
      child: const AbacusApp(),
    ),
  );
}

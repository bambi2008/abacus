import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'config/constants.dart';
import 'models/badge_record.dart';
import 'models/buddy_weekly_challenge.dart';
import 'models/complete_log_day_mark.dart';
import 'models/monthly_savings_result.dart';
import 'models/owl_state.dart';
import 'models/category.dart';
import 'models/category_challenge_result.dart';
import 'models/daily_log_completion.dart';
import 'models/expense.dart';
import 'models/no_spend_day_mark.dart';
import 'providers/buddy_provider.dart';
import 'providers/category_provider.dart';
import 'providers/expense_provider.dart';
import 'providers/gamification_provider.dart';
import 'providers/onboarding_provider.dart';
import 'providers/subscription_provider.dart';
import 'services/analytics_service.dart';
import 'services/supabase_buddy_backend.dart';

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
  if (!Hive.isAdapterRegistered(HiveTypeIds.noSpendDay)) {
    Hive.registerAdapter(NoSpendDayMarkAdapter());
  }
  if (!Hive.isAdapterRegistered(HiveTypeIds.categoryChallengeResult)) {
    Hive.registerAdapter(CategoryChallengeResultAdapter());
  }
  if (!Hive.isAdapterRegistered(HiveTypeIds.buddyWeeklyChallenge)) {
    Hive.registerAdapter(BuddyWeeklyChallengeAdapter());
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
  await Hive.openBox<CategoryChallengeResult>(
    HiveBoxes.categoryChallengeResults,
  );
  await Hive.openBox<BuddyWeeklyChallenge>(HiveBoxes.buddyWeeklyChallenges);
  await Hive.openBox<OwlState>(HiveBoxes.owlState);
  await Hive.openBox<CompleteLogDayMark>(HiveBoxes.completeLogDays);
  await Hive.openBox<MonthlySavingsResult>(HiveBoxes.monthlySavingsResults);
  await Hive.openBox(HiveBoxes.settings);
  await AnalyticsService.instance.init();
  AnalyticsService.instance.capture('app_opened');

  // Constructed early (not inside the MultiProvider's create:) so isPro is
  // readable before the streak-freeze check below — without this, Pro
  // subscribers got the exact same one-time freeze as free users, since
  // nothing ever threaded isPro into checkAndApplyStreakFreeze.
  final subscriptionProvider = SubscriptionProvider();

  final expenseProvider = ExpenseProvider()..load();
  final categoryProvider = CategoryProvider()..load();
  final gamificationProvider = GamificationProvider()..load();
  gamificationProvider.bind(expenseProvider, categoryProvider);
  // Catch a milestone reached while the app was closed — recorded silently
  // here, the celebration itself is shown on the next Today screen visit
  // (see GamificationProvider.pendingCelebration).
  await gamificationProvider.checkForNewMilestone(
    expenseProvider.currentStreak,
  );
  // Evaluate last month's category "boss battles" if a month boundary was
  // crossed while the app was closed — see evaluateMonthBoundaryIfNeeded.
  await gamificationProvider.evaluateMonthBoundaryIfNeeded();
  // Reflect any mood decay from real time passing while the app was closed
  // (e.g. it's now evening and today isn't logged yet) — refreshOwlState()
  // is also called from evaluateMonthBoundaryIfNeeded above, but that only
  // runs on a month-boundary crossing, not every app open.
  await gamificationProvider.refreshOwlState();

  // Opt-in savings-buddy sync. Unconfigured (no Supabase --dart-defines) →
  // NoopBuddyBackend, and the buddy card keeps its local-only behavior.
  final buddyProvider = BuddyProvider(SupabaseBuddyBackend());
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => OnboardingProvider()..load()),
        ChangeNotifierProvider.value(value: categoryProvider),
        ChangeNotifierProvider.value(value: expenseProvider),
        ChangeNotifierProvider.value(value: gamificationProvider),
        ChangeNotifierProvider.value(value: buddyProvider),
        ChangeNotifierProvider.value(value: subscriptionProvider),
      ],
      child: const PocklumeApp(),
    ),
  );

  // Network-backed services start only after the first frame. A slow App
  // Store/RevenueCat/Supabase connection must never hold the launch screen.
  unawaited(
    subscriptionProvider.init().then(
      (_) => expenseProvider.checkAndApplyStreakFreeze(
        isPro: subscriptionProvider.isPro,
      ),
    ),
  );
  unawaited(
    buddyProvider.init().then(
      (_) => buddyProvider.markTodayLogged(expenseProvider.loggedToday),
    ),
  );
}

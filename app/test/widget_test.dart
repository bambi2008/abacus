import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'package:pocklume/app.dart';
import 'package:pocklume/config/constants.dart';
import 'package:pocklume/models/badge_record.dart';
import 'package:pocklume/models/buddy_weekly_challenge.dart';
import 'package:pocklume/models/owl_state.dart';
import 'package:pocklume/models/complete_log_day_mark.dart';
import 'package:pocklume/models/monthly_savings_result.dart';
import 'package:pocklume/models/category.dart';
import 'package:pocklume/models/category_challenge_result.dart';
import 'package:pocklume/models/daily_log_completion.dart';
import 'package:pocklume/models/expense.dart';
import 'package:pocklume/models/no_spend_day_mark.dart';
import 'package:pocklume/providers/buddy_provider.dart';
import 'package:pocklume/providers/category_provider.dart';
import 'package:pocklume/providers/expense_provider.dart';
import 'package:pocklume/providers/gamification_provider.dart';
import 'package:pocklume/providers/onboarding_provider.dart';
import 'package:pocklume/providers/subscription_provider.dart';
import 'package:pocklume/services/buddy_backend.dart';

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
          ChangeNotifierProvider(create: (_) => GamificationProvider()..load()),
          ChangeNotifierProvider(
            create: (_) => BuddyProvider(NoopBuddyBackend()),
          ),
          ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
        ],
        child: const PocklumeApp(),
      ),
    );
    // Not pumpAndSettle: the streak card has an intentionally infinite
    // repeating idle-pulse animation (flutter_animate), so pumpAndSettle
    // would hang forever waiting for it to "finish." A bounded pump is
    // enough to let one frame of that animation and any transient/entrance
    // animations settle.
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Today'), findsWidgets);
  });
}

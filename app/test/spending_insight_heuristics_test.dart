import 'package:flutter_test/flutter_test.dart';

import 'package:abacus/models/spending_insight.dart';

// Pure top-category-vs-last-month comparison that powers Progress screen's
// "Spending insight" Pro card — previously that card unlocked for Pro but
// had no real content behind it at all. Dedicated test file since it's the
// actual feature being delivered for the app's one remaining real Pro
// benefit, separate from the provider-level integration tests.

void main() {
  group('computeSpendingInsight', () {
    test('returns null when nothing was spent this month', () {
      final insight = computeSpendingInsight(
        thisMonthSpend: {},
        lastMonthSpend: {'food': 100.0},
        categories: [(id: 'food', name: 'Food', emoji: '🍔')],
      );
      expect(insight, isNull);
    });

    test('picks the single highest-spend category this month', () {
      final insight = computeSpendingInsight(
        thisMonthSpend: {'food': 50.0, 'shopping': 200.0, 'taxi': 30.0},
        lastMonthSpend: {},
        categories: [
          (id: 'food', name: 'Food', emoji: '🍔'),
          (id: 'shopping', name: 'Shopping', emoji: '👕'),
          (id: 'taxi', name: 'Taxi', emoji: '🚕'),
        ],
      );
      expect(insight, isNotNull);
      expect(insight!.categoryId, 'shopping');
      expect(insight.thisMonthAmount, 200.0);
    });

    test('a category present in spend but missing from categories (deleted) is skipped', () {
      final insight = computeSpendingInsight(
        thisMonthSpend: {'deleted-id': 500.0, 'food': 20.0},
        lastMonthSpend: {},
        categories: [(id: 'food', name: 'Food', emoji: '🍔')],
      );
      // "deleted-id" is the top spend but has no matching category, so no
      // insight is shown rather than one with a blank name/emoji.
      expect(insight, isNull);
    });

    test('changeFraction is null with no last-month baseline for that category', () {
      final insight = computeSpendingInsight(
        thisMonthSpend: {'food': 100.0},
        lastMonthSpend: {},
        categories: [(id: 'food', name: 'Food', emoji: '🍔')],
      );
      expect(insight!.changeFraction, isNull);
    });

    test('changeFraction is positive when spending more than last month', () {
      final insight = computeSpendingInsight(
        thisMonthSpend: {'food': 150.0},
        lastMonthSpend: {'food': 100.0},
        categories: [(id: 'food', name: 'Food', emoji: '🍔')],
      );
      expect(insight!.changeFraction, closeTo(0.5, 0.001));
    });

    test('changeFraction is negative when spending less than last month', () {
      final insight = computeSpendingInsight(
        thisMonthSpend: {'food': 50.0},
        lastMonthSpend: {'food': 100.0},
        categories: [(id: 'food', name: 'Food', emoji: '🍔')],
      );
      expect(insight!.changeFraction, closeTo(-0.5, 0.001));
    });
  });
}

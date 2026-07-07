import 'package:flutter_test/flutter_test.dart';

import 'package:abacus/models/monthly_savings_result.dart';

// Pure comparison against the real BLS benchmarks in
// config/constants.dart's NationalSpendingBenchmarks — this is the
// credibility-bearing piece of the monthly recap, so it gets its own
// dedicated test file separate from the provider-level integration tests.

void main() {
  group('computeMonthlySavings', () {
    test('a category not present in the map is excluded, not assumed to be zero spend', () {
      // No entries at all — nothing tracked, nothing to celebrate.
      expect(computeMonthlySavings({}), 0);
    });

    test('spending less than the benchmark counts as savings', () {
      // Benchmark for dining+snacks is 3945/12 ≈ 328.75/mo.
      final saved = computeMonthlySavings({'Dining Out': 100.0});
      expect(saved, closeTo(328.75 - 100.0, 0.01));
    });

    test('spending more than the benchmark contributes zero, never negative', () {
      final saved = computeMonthlySavings({'Dining Out': 10000.0});
      expect(saved, 0);
    });

    test('dining out and snacks & drinks share one combined benchmark', () {
      final combined = computeMonthlySavings({'Dining Out': 100.0, 'Snacks & Drinks': 50.0});
      final diningOnly = computeMonthlySavings({'Dining Out': 150.0});
      expect(combined, closeTo(diningOnly, 0.01));
    });

    test('zero spend in a tracked category counts as the full benchmark saved', () {
      final saved = computeMonthlySavings({'Clothing & Shopping': 0.0});
      expect(saved, closeTo(2001 / 12, 0.01));
    });

    test('sums savings across all three comparable groups', () {
      final saved = computeMonthlySavings({
        'Dining Out': 0.0,
        'Clothing & Shopping': 0.0,
        'Fun & Entertainment': 0.0,
      });
      expect(saved, closeTo(3945 / 12 + 2001 / 12 + 935 / 12, 0.01));
    });

    test('categories with no reliable benchmark (Taxi, Subscriptions) never contribute', () {
      final withExtras = computeMonthlySavings({
        'Dining Out': 100.0,
        'Taxi & Rideshare': 0.0,
        'Subscriptions': 0.0,
      });
      final withoutExtras = computeMonthlySavings({'Dining Out': 100.0});
      expect(withExtras, closeTo(withoutExtras, 0.01));
    });

    test('an unrelated custom category never contributes', () {
      final saved = computeMonthlySavings({'My Custom Thing': 0.0});
      expect(saved, 0);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:abacus/services/buddy_backend.dart';

// The joint-streak math is the one piece of the buddy backend that's pure
// and therefore verifiable without a live Supabase project (real two-device
// sync can only be validated end-to-end against a running backend). These
// tests pin the rule: consecutive days ending today (or yesterday, as a
// one-day grace window) on which BOTH buddies logged.

DateTime d(int year, int month, int day) => DateTime(year, month, day);

void main() {
  final today = d(2026, 7, 5);

  group('computeJointStreak', () {
    test('no overlap is zero', () {
      final self = {d(2026, 7, 5), d(2026, 7, 4)};
      final partner = {d(2026, 7, 3), d(2026, 7, 2)};
      expect(computeJointStreak(self, partner, today), 0);
    });

    test('both logged today only is a 1-day streak', () {
      final both = {d(2026, 7, 5)};
      expect(computeJointStreak(both, both, today), 1);
    });

    test('counts the consecutive run where both logged', () {
      final self = {d(2026, 7, 5), d(2026, 7, 4), d(2026, 7, 3), d(2026, 7, 2)};
      final partner = {d(2026, 7, 5), d(2026, 7, 4), d(2026, 7, 3)};
      // Overlap is 7/5, 7/4, 7/3 → 3 consecutive days ending today.
      expect(computeJointStreak(self, partner, today), 3);
    });

    test('a gap in one partner breaks the run', () {
      final self = {d(2026, 7, 5), d(2026, 7, 4), d(2026, 7, 3)};
      // Partner missed 7/4, so the joint run can only be today (7/5).
      final partner = {d(2026, 7, 5), d(2026, 7, 3)};
      expect(computeJointStreak(self, partner, today), 1);
    });

    test('yesterday-only overlap still counts (one-day grace, today not yet logged)', () {
      final both = {d(2026, 7, 4), d(2026, 7, 3)};
      // Neither logged today yet, but both logged 7/4 and 7/3 → streak of 2
      // survives on the grace window rather than resetting to 0.
      expect(computeJointStreak(both, both, today), 2);
    });

    test('overlap older than yesterday is already broken', () {
      final both = {d(2026, 7, 3), d(2026, 7, 2)};
      // Most recent joint day is 7/3, older than the yesterday grace → 0.
      expect(computeJointStreak(both, both, today), 0);
    });

    test('normalizes timestamps to calendar days', () {
      final self = {DateTime(2026, 7, 5, 9, 30), DateTime(2026, 7, 4, 23, 59)};
      final partner = {DateTime(2026, 7, 5, 20, 15), DateTime(2026, 7, 4, 0, 1)};
      expect(computeJointStreak(self, partner, DateTime(2026, 7, 5, 12)), 2);
    });
  });
}

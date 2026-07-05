import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:abacus/config/constants.dart';
import 'package:abacus/models/badge_record.dart';
import 'package:abacus/providers/gamification_provider.dart';

void main() {
  late GamificationProvider provider;

  setUp(() async {
    Hive.init('test_hive_gamification');
    if (!Hive.isAdapterRegistered(HiveTypeIds.badge)) {
      Hive.registerAdapter(BadgeRecordAdapter());
    }
    await Hive.openBox<BadgeRecord>(HiveBoxes.badges);
    provider = GamificationProvider()..load();
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
  });

  test('non-milestone streak values earn nothing', () async {
    for (final day in [1, 2, 6, 8, 29, 31, 99, 101, 364, 366]) {
      final badge = await provider.checkForNewMilestone(day);
      expect(badge, isNull, reason: 'day $day should not earn a badge');
    }
    expect(provider.earnedBadges, isEmpty);
  });

  test('milestone streak values earn exactly one badge each', () async {
    for (final day in [7, 30, 100, 365]) {
      final badge = await provider.checkForNewMilestone(day);
      expect(badge, isNotNull);
      expect(badge!.milestoneDay, day);
      expect(provider.isEarned(day), isTrue);
    }
    expect(provider.earnedBadges.length, 4);
  });

  test('checking the same milestone twice is idempotent', () async {
    final first = await provider.checkForNewMilestone(7);
    final second = await provider.checkForNewMilestone(7);
    expect(first, isNotNull);
    expect(second, isNull, reason: 'already-earned milestone should not re-fire');
    expect(provider.earnedBadges.length, 1);
  });

  test('pendingCelebration surfaces an unshown badge, then clears once marked shown', () async {
    expect(provider.pendingCelebration, isNull);
    final badge = await provider.checkForNewMilestone(30);
    expect(provider.pendingCelebration?.id, badge!.id);
    await provider.markCelebrationShown(badge.id);
    expect(provider.pendingCelebration, isNull);
  });
}

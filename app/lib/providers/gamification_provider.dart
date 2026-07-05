import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../config/constants.dart';
import '../models/badge_record.dart';
import '../services/analytics_service.dart';

/// Owns gamification state layered on top of ExpenseProvider/CategoryProvider
/// without changing either's public API — see docs/technical-architecture.md
/// and the gamification-depth plan. Milestone A: badge/milestone detection
/// only. Later milestones (no-spend days, category challenges, cat state)
/// will need live ExpenseProvider/CategoryProvider references — add a
/// `bind()` method + ChangeNotifierProxyProvider2 wiring then, not before,
/// to avoid unused fields now.
class GamificationProvider extends ChangeNotifier {
  late Box<BadgeRecord> _badges;

  void load() {
    _badges = Hive.box<BadgeRecord>(HiveBoxes.badges);
  }

  List<BadgeRecord> get earnedBadges => _badges.values.toList();

  bool isEarned(int milestoneDay) => _badges.get('streak_$milestoneDay') != null;

  /// A badge that's been earned but whose full-screen celebration hasn't
  /// been shown yet — resilient to the app being killed mid-flow, since
  /// this is just a box scan, safe to check on every relevant screen build.
  BadgeRecord? get pendingCelebration {
    for (final badge in _badges.values) {
      if (!badge.celebrationShown) return badge;
    }
    return null;
  }

  /// Idempotent: safe to call after every log and on app start. Returns the
  /// newly-earned badge if `currentStreak` just crossed a milestone for the
  /// first time, otherwise null.
  Future<BadgeRecord?> checkForNewMilestone(int currentStreak) async {
    if (!MilestoneCatalog.milestoneDays.contains(currentStreak)) return null;
    final id = 'streak_$currentStreak';
    if (_badges.get(id) != null) return null;
    final badge = BadgeRecord(id: id, milestoneDay: currentStreak, earnedAt: DateTime.now());
    await _badges.put(id, badge);
    AnalyticsService.instance.capture('milestone_reached', properties: {'milestone_day': currentStreak});
    notifyListeners();
    return badge;
  }

  Future<void> markCelebrationShown(String badgeId) async {
    final badge = _badges.get(badgeId);
    if (badge == null) return;
    await _badges.put(badgeId, badge.copyWith(celebrationShown: true));
    notifyListeners();
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/analytics_service.dart';
import '../services/buddy_backend.dart';

/// Owns savings-buddy sync state on top of a [BuddyBackend]. Kept separate
/// from GamificationProvider so the networked, opt-in social feature stays
/// isolated from the local-first core (and can be ripped out or swapped
/// without touching streak/owl logic). Derives the joint streak and today's
/// status purely from the backend's raw signals via [computeJointStreak].
class BuddyProvider extends ChangeNotifier {
  final BuddyBackend _backend;
  StreamSubscription<void>? _changesSubscription;

  BuddyProvider(this._backend) {
    // Auto-refresh on Realtime events (partner joined / partner logged a
    // day) so both sides update live. This is on top of, not instead of,
    // the manual pull-to-refresh in the UI — Realtime delivery isn't
    // guaranteed (dropped connections, backgrounded app), so a manual
    // fallback still matters.
    _changesSubscription = _backend.changes.listen((_) => refresh());
  }

  bool get isConfigured => _backend.isConfigured;

  BuddyRemoteState _state = const BuddyRemoteState.unlinked();

  bool get linked => _state.linked;
  bool get partnerJoined => _state.partnerJoined;
  String? get code => _state.code;

  int get jointStreak => computeJointStreak(_state.selfLoggedDays, _state.partnerLoggedDays, DateTime.now());

  bool get selfLoggedToday => _state.selfLoggedDays.contains(dateOnly(DateTime.now()));
  bool get partnerLoggedToday => _state.partnerLoggedDays.contains(dateOnly(DateTime.now()));

  /// Signs in anonymously (if configured) and pulls the current state.
  Future<void> init() async {
    if (!_backend.isConfigured) return;
    await _backend.init();
    await refresh();
  }

  Future<void> refresh() async {
    if (!_backend.isConfigured) return;
    _state = await _backend.fetchState();
    notifyListeners();
  }

  /// Creates a link and returns the share code (null on failure).
  Future<String?> createLink() async {
    if (!_backend.isConfigured) return null;
    final code = await _backend.createLink();
    if (code != null) {
      AnalyticsService.instance.capture('buddy_link_created');
      await refresh();
    }
    return code;
  }

  Future<bool> joinLink(String code) async {
    if (!_backend.isConfigured) return false;
    final ok = await _backend.joinLink(code);
    if (ok) {
      AnalyticsService.instance.capture('buddy_link_joined');
      await refresh();
    }
    return ok;
  }

  /// Pushes today's "did I log" signal. Called from the log-expense flow and
  /// on app start so the partner sees an up-to-date board.
  Future<void> markTodayLogged(bool logged) async {
    if (!_backend.isConfigured || !_state.linked) return;
    await _backend.markDay(DateTime.now(), logged: logged);
    await refresh();
  }

  /// Deletes all of this user's synced buddy data and their anonymous
  /// identity (App Store Guideline 5.1.1(v)). Resets to unlinked so the UI
  /// returns to the "find a buddy" state.
  Future<void> deleteMyData() async {
    if (!_backend.isConfigured) return;
    await _backend.deleteMyData();
    _state = const BuddyRemoteState.unlinked();
    notifyListeners();
  }

  @override
  void dispose() {
    _changesSubscription?.cancel();
    _backend.dispose();
    super.dispose();
  }
}

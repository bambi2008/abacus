import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/constants.dart';
import 'buddy_backend.dart';

/// Supabase-backed buddy sync. Uses anonymous auth so every install gets a
/// real, stable `auth.uid()` that row-level security keys off of — the
/// difference between a genuine backend and a shell. Every network call is
/// wrapped so a failure degrades to "unlinked" rather than crashing the
/// local-first app. See app/supabase/schema.sql for the tables + the
/// `join_buddy_link` security-definer RPC, and docs/technical-architecture.md
/// for the privacy boundary (only anon-id + date + a boolean sync, never
/// financial data).
class SupabaseBuddyBackend implements BuddyBackend {
  SupabaseClient? _client;
  final _changesController = StreamController<void>.broadcast();
  RealtimeChannel? _channel;
  String? _subscribedLinkId;

  @override
  bool get isConfigured => SupabaseConfig.url.isNotEmpty && SupabaseConfig.anonKey.isNotEmpty;

  @override
  Stream<void> get changes => _changesController.stream;

  @override
  Future<void> init() async {
    if (!isConfigured) return;
    try {
      await Supabase.initialize(url: SupabaseConfig.url, publishableKey: SupabaseConfig.anonKey);
      _client = Supabase.instance.client;
      if (_client!.auth.currentUser == null) {
        await _client!.auth.signInAnonymously();
      }
    } catch (e) {
      debugPrint('SupabaseBuddyBackend: init failed, buddy sync disabled: $e');
      _client = null;
    }
  }

  String? get _uid => _client?.auth.currentUser?.id;

  @override
  Future<String?> createLink() async {
    final client = _client;
    final uid = _uid;
    if (client == null || uid == null) return null;
    try {
      final code = _generateCode();
      await client.from('buddy_links').insert({'code': code, 'creator_id': uid});
      return code;
    } catch (e) {
      debugPrint('SupabaseBuddyBackend: createLink failed: $e');
      return null;
    }
  }

  @override
  Future<bool> joinLink(String code) async {
    final client = _client;
    if (client == null || _uid == null) return false;
    try {
      final linkId = await client.rpc('join_buddy_link', params: {'join_code': code.toUpperCase()});
      return linkId != null;
    } catch (e) {
      debugPrint('SupabaseBuddyBackend: joinLink failed: $e');
      return false;
    }
  }

  @override
  Future<void> markDay(DateTime date, {required bool logged}) async {
    final client = _client;
    final uid = _uid;
    if (client == null || uid == null) return;
    try {
      final link = await _activeLink();
      if (link == null) return;
      final day = dateOnly(date);
      final dayStr = '${day.year.toString().padLeft(4, '0')}-'
          '${day.month.toString().padLeft(2, '0')}-'
          '${day.day.toString().padLeft(2, '0')}';
      await client.from('buddy_marks').upsert(
        {'link_id': link['id'], 'user_id': uid, 'day': dayStr, 'logged': logged},
        onConflict: 'link_id,user_id,day',
      );
    } catch (e) {
      debugPrint('SupabaseBuddyBackend: markDay failed: $e');
    }
  }

  @override
  Future<BuddyRemoteState> fetchState() async {
    final client = _client;
    final uid = _uid;
    if (client == null || uid == null) return const BuddyRemoteState.unlinked();
    try {
      final link = await _activeLink();
      if (link == null) return const BuddyRemoteState.unlinked();

      final creatorId = link['creator_id'] as String;
      final partnerId = link['partner_id'] as String?;
      final partnerJoined = partnerId != null && creatorId != partnerId;

      final rows = await client.from('buddy_marks').select('user_id, day, logged').eq('link_id', link['id']);
      final self = <DateTime>{};
      final partner = <DateTime>{};
      for (final row in (rows as List)) {
        if (row['logged'] != true) continue;
        final day = dateOnly(DateTime.parse(row['day'] as String));
        if (row['user_id'] == uid) {
          self.add(day);
        } else {
          partner.add(day);
        }
      }
      return BuddyRemoteState(
        linked: true,
        code: link['code'] as String?,
        partnerJoined: partnerJoined,
        selfLoggedDays: self,
        partnerLoggedDays: partner,
      );
    } catch (e) {
      debugPrint('SupabaseBuddyBackend: fetchState failed: $e');
      return const BuddyRemoteState.unlinked();
    }
  }

  /// The most recent link this device is part of (as creator or partner).
  /// Also ensures a Realtime subscription is active for that link, so a
  /// call to [fetchState] anywhere (app start, after any local action)
  /// naturally keeps the live-update subscription current too.
  Future<Map<String, dynamic>?> _activeLink() async {
    final client = _client;
    final uid = _uid;
    if (client == null || uid == null) return null;
    final rows = await client
        .from('buddy_links')
        .select()
        .or('creator_id.eq.$uid,partner_id.eq.$uid')
        .order('created_at', ascending: false)
        .limit(1);
    final list = rows as List;
    if (list.isEmpty) return null;
    final link = list.first as Map<String, dynamic>;
    _subscribeToLink(client, link['id'] as String);
    return link;
  }

  /// Subscribes to Realtime changes on this link's row (partner joining)
  /// and its marks (either side logging a day), so both devices update
  /// live instead of only on the next local action. RLS applies to
  /// Realtime the same as to regular queries, so this only ever sees rows
  /// the current user is already allowed to read. Idempotent per link —
  /// re-subscribing to the same link id is a no-op.
  void _subscribeToLink(SupabaseClient client, String linkId) {
    if (_subscribedLinkId == linkId) return;
    if (_channel != null) client.removeChannel(_channel!);
    _subscribedLinkId = linkId;
    _channel = client
        .channel('buddy_link_$linkId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'buddy_marks',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'link_id', value: linkId),
          callback: (_) => _changesController.add(null),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'buddy_links',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'id', value: linkId),
          callback: (_) => _changesController.add(null),
        )
        .subscribe();
  }

  @override
  Future<void> dispose() async {
    final client = _client;
    if (client != null && _channel != null) {
      await client.removeChannel(_channel!);
    }
    _channel = null;
    _subscribedLinkId = null;
    await _changesController.close();
  }

  static String _generateCode() {
    // Ambiguity-free alphabet (no O/0/I/1) — codes get read aloud/typed.
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(6, (_) => alphabet[rng.nextInt(alphabet.length)]).join();
  }
}

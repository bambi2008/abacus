import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../config/constants.dart';
import '../config/theme.dart';
import '../providers/buddy_provider.dart';
import '../providers/gamification_provider.dart';
import '../services/analytics_service.dart';

/// Share.share() is a native platform-channel call — if the system share
/// sheet's presentation stalls (the same class of issue that hung
/// image_picker's camera UI earlier this session), an unguarded await
/// hangs forever with no feedback. Bounded here and used by every share
/// call site in this file instead of calling Share.share directly.
Future<void> _shareOrWarn(BuildContext context, String text) async {
  try {
    await Share.share(text).timeout(const Duration(seconds: 15));
  } catch (e) {
    debugPrint('buddy_streak_card: share failed or timed out: $e');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open the share sheet — try again.'),
        ),
      );
    }
  }
}

/// "省钱搭子" (savings buddy) — the third main-line card on Today, parallel
/// in visual weight to the streak card and the companion owl card. This is
/// the social/relational pillar: the streak card is the individual habit
/// metric, the owl is the individual emotional/growth metric, this card is
/// the relational one.
///
/// Two modes, chosen at build time by whether Supabase keys were supplied
/// (see SupabaseConfig / BuddyProvider):
///   • Configured → REAL two-device sync via [BuddyProvider]: create/join a
///     link, and a live joint streak that only advances on days BOTH people
///     log. Only an anonymous id + date + a boolean ever leave the device.
///   • Unconfigured → the original local-only behavior: an on-device invite
///     code and an honest "waiting to sync" placeholder, so the app is fully
///     functional with no backend. See docs/technical-architecture.md.
class BuddyStreakCard extends StatelessWidget {
  const BuddyStreakCard({super.key});

  @override
  Widget build(BuildContext context) {
    final buddy = context.watch<BuddyProvider>();
    if (buddy.isConfigured) {
      return _SyncedBuddyCard(buddy: buddy);
    }
    return const _LocalBuddyCard();
  }
}

/// Real-backend card: reflects create/join/streak state from [BuddyProvider].
class _SyncedBuddyCard extends StatefulWidget {
  final BuddyProvider buddy;
  const _SyncedBuddyCard({required this.buddy});

  @override
  State<_SyncedBuddyCard> createState() => _SyncedBuddyCardState();
}

class _SyncedBuddyCardState extends State<_SyncedBuddyCard> {
  bool _refreshing = false;

  BuddyProvider get buddy => widget.buddy;

  Future<void> _manualRefresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    try {
      await buddy.refresh();
    } catch (e) {
      // Without this, a single failed refresh (offline, unreachable
      // backend) left _refreshing stuck true forever — the re-entry
      // guard above then blocked every future tap, so the only way out
      // was restarting the app.
      debugPrint('buddy_streak_card: refresh failed: $e');
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _invite(BuildContext context) async {
    if (!buddy.hasOptedIn && !await _confirmBuddySync(context)) return;
    final code = await buddy.createLink();
    if (code == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not start a buddy streak. Check your connection.',
            ),
          ),
        );
      }
      return;
    }
    if (!context.mounted) return;
    await _shareOrWarn(
      context,
      'Join my Pocklume savings-buddy streak! Use code $code in the app.',
    );
  }

  Future<void> _join(BuildContext context) async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Join a buddy streak'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            hintText: 'Enter your buddy\'s code',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Join'),
          ),
        ],
      ),
    );
    if (code == null || code.isEmpty) return;
    if (!context.mounted) return;
    if (!buddy.hasOptedIn && !await _confirmBuddySync(context)) return;
    if (!context.mounted) return;
    final ok = await buddy.joinLink(code);
    if (context.mounted && !ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'That code didn\'t work — it may be wrong or already claimed.',
          ),
        ),
      );
    }
  }

  Future<bool> _confirmBuddySync(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Turn on buddy sync?'),
        content: const Text(
          'To connect two devices, Pocklume will create a random anonymous ID and sync only the date and whether you checked in that day. Expense amounts, categories, and notes never leave your device. You can delete the synced data and anonymous ID in Settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Turn on sync'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // AppColors.trust directly, not colorScheme.tertiaryContainer — see
    // config/theme.dart for why that role isn't overridden app-wide.
    final trustContainer = (theme.brightness == Brightness.dark
        ? AppColors.trustContainerDark
        : AppColors.trustContainer);

    Widget body;
    if (!buddy.linked) {
      body = _row(
        theme,
        title: 'Find a savings buddy',
        subtitle:
            'Both of you log an expense the same day to build a shared streak.',
        trailing: Wrap(
          spacing: 4,
          children: [
            TextButton(
              onPressed: () => _join(context),
              child: const Text('Join'),
            ),
            FilledButton.tonal(
              onPressed: () => _invite(context),
              child: const Text('Invite'),
            ),
          ],
        ),
      );
    } else if (!buddy.partnerJoined) {
      body = _row(
        theme,
        title: 'Waiting for your buddy',
        subtitle:
            'Share code ${buddy.code} — your streak starts the day you both log.',
        trailing: Wrap(
          spacing: 4,
          children: [
            _refreshButton(),
            IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: () => _shareOrWarn(
                context,
                'Join my Pocklume savings-buddy streak! Use code ${buddy.code} in the app.',
              ),
            ),
          ],
        ),
      );
    } else {
      final selfMark = buddy.selfLoggedToday ? '✓' : '⏳';
      final partnerMark = buddy.partnerLoggedToday ? '✓' : '⏳';
      body = _row(
        theme,
        title: '${buddy.jointStreak}-day buddy streak',
        subtitle:
            'Today — you $selfMark · buddy $partnerMark. Both must log to keep it alive.',
        trailing: _refreshButton(),
      );
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      color: trustContainer.withValues(alpha: 0.6),
      child: Padding(padding: const EdgeInsets.all(16), child: body),
    );
  }

  /// Manual fallback for "I don't see my buddy's latest status" — Realtime
  /// keeps both sides live in the common case, but delivery isn't
  /// guaranteed (dropped connection, backgrounded app), so this always
  /// stays available rather than assuming Realtime alone is enough.
  Widget _refreshButton() {
    return _refreshing
        ? const Padding(
            padding: EdgeInsets.all(8),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        : IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _manualRefresh,
          );
  }

  Widget _row(
    ThemeData theme, {
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return Row(
      children: [
        const Text('🤝', style: TextStyle(fontSize: AppIconSizes.large)),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleMedium),
              const SizedBox(height: 2),
              Text(subtitle, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing],
      ],
    );
  }
}

/// Local-only fallback (no Supabase keys configured) — identical to the
/// pre-backend behavior: an on-device invite code and an honest "waiting to
/// sync" placeholder. Keeps the app fully usable with zero backend.
class _LocalBuddyCard extends StatefulWidget {
  const _LocalBuddyCard();

  @override
  State<_LocalBuddyCard> createState() => _LocalBuddyCardState();
}

class _LocalBuddyCardState extends State<_LocalBuddyCard> {
  late Box _settings;
  late bool _inviteSent;

  @override
  void initState() {
    super.initState();
    _settings = Hive.box(HiveBoxes.settings);
    _inviteSent =
        (_settings.get(SettingsKeys.buddyStreakCode) as String?)?.isNotEmpty ??
        false;
  }

  Future<void> _sendInvite() async {
    final code = const Uuid().v4().substring(0, 6).toUpperCase();
    await _settings.put(SettingsKeys.buddyStreakCode, code);
    AnalyticsService.instance.capture('buddy_streak_invite_sent');
    setState(() => _inviteSent = true);
    if (!mounted) return;
    await _shareOrWarn(
      context,
      'Join my Pocklume savings-buddy streak! Use code $code in the app.',
    );
  }

  @override
  Widget build(BuildContext context) {
    // AppColors.trust directly, not colorScheme.tertiaryContainer — see
    // config/theme.dart for why that role isn't overridden app-wide.
    final trustContainer = (Theme.of(context).brightness == Brightness.dark
        ? AppColors.trustContainerDark
        : AppColors.trustContainer);
    if (!_inviteSent) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        color: trustContainer.withValues(alpha: 0.6),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text('🤝', style: TextStyle(fontSize: AppIconSizes.large)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Find a savings buddy',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Both of you log an expense the same day to keep it alive.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Sync isn\'t enabled in this build — inviting won\'t actually connect two devices yet.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: _sendInvite,
                child: const Text('Invite'),
              ),
            ],
          ),
        ),
      );
    }

    final selfCount = context
        .watch<GamificationProvider>()
        .currentWeekLoggedDaysCount;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      color: trustContainer.withValues(alpha: 0.6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Text('🤝', style: TextStyle(fontSize: AppIconSizes.large)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This week: $selfCount/7 days',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Sync isn\'t enabled in this build — your buddy\'s side won\'t actually connect.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

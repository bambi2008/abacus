import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../config/constants.dart';
import '../providers/gamification_provider.dart';
import '../services/analytics_service.dart';

/// "省钱搭子" (savings buddy) — the third main-line card on Today, parallel
/// in visual weight to the streak card and the companion cat card. This is
/// the social/relational pillar: the streak card is the individual habit
/// metric, the cat is the individual emotional/growth metric, this card is
/// the relational one. Local-only scaffold: the invite/own-count side is
/// real, the partner's side is an honest "waiting to sync" placeholder
/// since no backend exists yet for real two-device sync — see
/// docs/technical-architecture.md.
class BuddyStreakCard extends StatefulWidget {
  const BuddyStreakCard({super.key});

  @override
  State<BuddyStreakCard> createState() => _BuddyStreakCardState();
}

class _BuddyStreakCardState extends State<BuddyStreakCard> {
  late Box _settings;
  late bool _inviteSent;

  @override
  void initState() {
    super.initState();
    _settings = Hive.box(HiveBoxes.settings);
    _inviteSent = (_settings.get(SettingsKeys.buddyStreakCode) as String?)?.isNotEmpty ?? false;
  }

  Future<void> _sendInvite() async {
    final code = const Uuid().v4().substring(0, 6).toUpperCase();
    await _settings.put(SettingsKeys.buddyStreakCode, code);
    AnalyticsService.instance.capture('buddy_streak_invite_sent');
    setState(() => _inviteSent = true);
    await Share.share('Join my Abacus savings-buddy streak! Use code $code in the app.');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (!_inviteSent) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        color: scheme.tertiaryContainer.withValues(alpha: 0.6),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text('🤝', style: TextStyle(fontSize: 40)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Find a savings buddy', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      'Both of you log an expense the same day to keep it alive.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(onPressed: _sendInvite, child: const Text('Invite')),
            ],
          ),
        ),
      );
    }

    final selfCount = context.watch<GamificationProvider>().currentWeekLoggedDaysCount;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      color: scheme.tertiaryContainer.withValues(alpha: 0.6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Text('🤝', style: TextStyle(fontSize: 40)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('This week: $selfCount/7 days', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    'Waiting for your buddy to sync — coming soon.',
                    style: Theme.of(context).textTheme.bodySmall,
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

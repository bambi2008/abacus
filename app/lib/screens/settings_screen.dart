import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../config/constants.dart';
import '../models/expense.dart';
import '../providers/category_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/gamification_provider.dart';
import '../providers/subscription_provider.dart';
import '../services/analytics_service.dart';
import '../services/export_service.dart';
import 'paywall_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final subscription = context.watch<SubscriptionProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Subscription', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: Icon(subscription.isPro ? Icons.workspace_premium : Icons.lock_outline),
            title: Text(subscription.isPro ? 'Abacus Pro' : 'Free plan'),
            subtitle: Text(
              subscription.isPro
                  ? 'Unlimited streak freezes, buddy streaks, and spending insights.'
                  : 'Upgrade for unlimited streak freezes and spending insights.',
            ),
            trailing: subscription.isPro
                ? null
                : FilledButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PaywallScreen()),
                    ),
                    child: const Text('Upgrade'),
                  ),
          ),
          if (!subscription.isPro)
            TextButton(
              onPressed: () => context.read<SubscriptionProvider>().restore(),
              child: const Text('Restore Purchases'),
            ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Streaks', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const _BuddyStreakTile(),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Your Data', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text('Export as CSV'),
            subtitle: const Text('Your data, not ours — take it with you anytime.'),
            onTap: () {
              final expenses = context.read<ExpenseProvider>();
              final categories = context.read<CategoryProvider>();
              final all = <Expense>[];
              for (var i = 0; i < 365; i++) {
                all.addAll(expenses.expensesOn(DateTime.now().subtract(Duration(days: i))));
              }
              ExportService.exportExpenses(all, categories.all);
              AnalyticsService.instance.capture('data_exported');
            },
          ),
          const _NotificationTimeTile(),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Privacy', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const _AnalyticsToggle(),
          const Divider(),
          // Low-key, opt-in placement — the referral participation-rate
          // assumption is unvalidated (see docs/customer-and-market.md), so
          // this is deliberately not an aggressive prompt.
          ListTile(
            leading: const Icon(Icons.savings_outlined),
            title: const Text('Know someone who\'d like a high-yield savings account?'),
            subtitle: const Text('Optional — we only suggest this if it seems useful.'),
            onTap: () => AnalyticsService.instance.capture('referral_settings_tapped'),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsToggle extends StatefulWidget {
  const _AnalyticsToggle();

  @override
  State<_AnalyticsToggle> createState() => _AnalyticsToggleState();
}

class _AnalyticsToggleState extends State<_AnalyticsToggle> {
  late bool _enabled = AnalyticsService.instance.enabled;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: const Text('Anonymous usage analytics'),
      subtitle: const Text(
        'Helps us improve Abacus. Never sends expense amounts, categories, or notes.',
      ),
      value: _enabled,
      onChanged: (v) {
        setState(() => _enabled = v);
        AnalyticsService.instance.setEnabled(v);
      },
    );
  }
}

class _NotificationTimeTile extends StatefulWidget {
  const _NotificationTimeTile();

  @override
  State<_NotificationTimeTile> createState() => _NotificationTimeTileState();
}

class _NotificationTimeTileState extends State<_NotificationTimeTile> {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.schedule_outlined),
      title: const Text('Reminder time'),
      subtitle: const Text('When to nudge you if a streak is at risk.'),
      trailing: const Text('8:00 PM'),
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: const TimeOfDay(hour: 20, minute: 0),
        );
        if (time != null) {
          AnalyticsService.instance.capture('reminder_time_changed');
        }
      },
    );
  }
}

/// Buddy streak — the one mechanic that fixes the "no viral loop" weakness
/// identified in HeelEase's business-model critique. This scaffold
/// implements the sharing/UI surface plus a real, locally-computed weekly
/// count for the user's own side; real two-way sync (the partner's count)
/// needs a lightweight backend (Phase 2, not part of the local-first Hive
/// architecture this MVP uses) — so that side is shown as an honest
/// "waiting to sync" state, never a fabricated number.
class _BuddyStreakTile extends StatefulWidget {
  const _BuddyStreakTile();

  @override
  State<_BuddyStreakTile> createState() => _BuddyStreakTileState();
}

class _BuddyStreakTileState extends State<_BuddyStreakTile> {
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
    await Share.share('Join my Abacus buddy streak! Use code $code in the app.');
  }

  @override
  Widget build(BuildContext context) {
    final selfCount = context.watch<GamificationProvider>().currentWeekLoggedDaysCount;
    return ListTile(
      leading: const Icon(Icons.people_outline),
      title: const Text('Start a buddy streak'),
      subtitle: Text(
        _inviteSent
            ? 'This week: you logged $selfCount/7 days. Waiting for your buddy to sync — coming soon.'
            : 'Both of you log an expense the same day to keep it alive.',
      ),
      trailing: FilledButton.tonal(onPressed: _sendInvite, child: const Text('Invite')),
    );
  }
}

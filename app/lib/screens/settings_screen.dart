import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

import '../config/constants.dart';
import '../models/expense.dart';
import '../providers/category_provider.dart';
import '../providers/expense_provider.dart';
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
          // Buddy-streak invite/status now lives on the Today screen as its
          // own main-line card (BuddyStreakCard) — this is just a pointer,
          // not a duplicate interactive control.
          const ListTile(
            leading: Icon(Icons.people_outline),
            title: Text('Savings buddy'),
            subtitle: Text('Find or manage your savings buddy from the Today screen.'),
          ),
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
  late Box _settings;
  late TimeOfDay _time;

  @override
  void initState() {
    super.initState();
    _settings = Hive.box(HiveBoxes.settings);
    _time = TimeOfDay(
      hour: _settings.get(SettingsKeys.reminderHour, defaultValue: 20) as int,
      minute: _settings.get(SettingsKeys.reminderMinute, defaultValue: 0) as int,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.schedule_outlined),
      title: const Text('Reminder time'),
      subtitle: const Text('When to nudge you if a streak is at risk.'),
      trailing: Text(_time.format(context)),
      onTap: () async {
        final time = await showTimePicker(context: context, initialTime: _time);
        if (time == null || !mounted) return;
        await _settings.put(SettingsKeys.reminderHour, time.hour);
        await _settings.put(SettingsKeys.reminderMinute, time.minute);
        setState(() => _time = time);
        AnalyticsService.instance.capture('reminder_time_changed');
      },
    );
  }
}

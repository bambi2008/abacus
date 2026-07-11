import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

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
                  ? 'Unlimited streak freezes and spending insights.'
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
            onTap: () async {
              final expenses = context.read<ExpenseProvider>();
              final categories = context.read<CategoryProvider>();
              final all = <Expense>[];
              for (var i = 0; i < 365; i++) {
                all.addAll(expenses.expensesOn(DateTime.now().subtract(Duration(days: i))));
              }
              // Previously fire-and-forget with no error path at all — if
              // the share sheet failed or timed out, nothing told the user.
              final ok = await ExportService.exportExpenses(all, categories.all);
              if (!context.mounted) return;
              if (ok) {
                AnalyticsService.instance.capture('data_exported');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Could not export — try again.')),
                );
              }
            },
          ),
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
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Legal', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _openLink(context, LegalLinks.privacyPolicy),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Terms of Use'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _openLink(context, LegalLinks.termsOfUse),
          ),
        ],
      ),
    );
  }

  Future<void> _openLink(BuildContext context, String url) async {
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the link — check your connection.')),
      );
    }
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

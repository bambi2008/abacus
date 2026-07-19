import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/constants.dart';
import '../providers/buddy_provider.dart';
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
            child: Text('Plan', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: Icon(
              subscription.isPro ? Icons.workspace_premium : Icons.lock_outline,
            ),
            title: Text(subscription.isPro ? 'Pocklume Pro' : 'Free plan'),
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
              onPressed: () async {
                final restored = await context
                    .read<SubscriptionProvider>()
                    .restore();
                if (!context.mounted) return;
                final message = restored
                    ? 'Pocklume Pro was restored.'
                    : context.read<SubscriptionProvider>().errorMessage ??
                          'No previous purchase was found.';
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(message)));
              },
              child: const Text('Restore Purchases'),
            ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Streaks',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          // Buddy-streak invite/status lives on the Today screen as its own
          // main-line card (BuddyStreakCard) — this is just a pointer.
          const ListTile(
            leading: Icon(Icons.people_outline),
            title: Text('Savings buddy'),
            subtitle: Text(
              'Find or manage your savings buddy from the Today screen.',
            ),
          ),
          // In-app data deletion for the (anonymous) buddy account — required
          // by App Store Guideline 5.1.1(v) once the app creates accounts.
          // Only shown when the buddy backend is actually configured/active.
          if (context.watch<BuddyProvider>().isConfigured)
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete my savings-buddy data'),
              subtitle: const Text(
                'Removes your buddy link and synced logging days from the server.',
              ),
              onTap: () => _confirmDeleteBuddyData(context),
            ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Your Data',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text('Export as CSV'),
            subtitle: const Text(
              'Your data, not ours — take it with you anytime.',
            ),
            onTap: () async {
              final expenses = context.read<ExpenseProvider>();
              final categories = context.read<CategoryProvider>();
              final all = expenses.allExpenses;
              // Previously fire-and-forget with no error path at all — if
              // the share sheet failed or timed out, nothing told the user.
              final ok = await ExportService.exportExpenses(
                all,
                categories.all,
              );
              if (!context.mounted) return;
              if (ok) {
                AnalyticsService.instance.capture('data_exported');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Could not export — try again.'),
                  ),
                );
              }
            },
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
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open the link — check your connection.'),
        ),
      );
    }
  }

  Future<void> _confirmDeleteBuddyData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete savings-buddy data?'),
        content: const Text(
          'This removes your buddy link and every synced logging day from the '
          'server, and disconnects you from your buddy. Your local expenses and '
          'streaks are not affected. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final buddy = context.read<BuddyProvider>();
    try {
      await buddy.deleteMyData();
      messenger.showSnackBar(
        const SnackBar(content: Text('Your savings-buddy data was deleted.')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Could not delete right now — check your connection and try again.',
          ),
        ),
      );
    }
  }
}

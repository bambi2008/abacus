import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/constants.dart';
import '../providers/subscription_provider.dart';
import '../services/analytics_service.dart';

/// Lifetime-led pricing, no weekly billing — same discipline as
/// HeelEase/Regimen. See docs/product-design.md for when this is shown
/// (Day 5+ or first free-tier limit hit, never during onboarding).
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.capture('paywall_viewed');
  }

  Future<void> _purchase(BuildContext context) async {
    final subscription = context.read<SubscriptionProvider>();
    final success = await subscription.purchaseLifetime();
    if (!context.mounted) return;
    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Abacus Pro is unlocked.')));
      Navigator.of(context).pop();
    } else if (subscription.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(subscription.errorMessage!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final subscription = context.watch<SubscriptionProvider>();
    final busy = subscription.state == PurchaseFlowState.loading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Abacus Pro'),
        actions: [
          TextButton(
            onPressed: () => context.read<SubscriptionProvider>().restore(),
            child: const Text('Restore'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Pay once, budget forever',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(flex: 3, child: SizedBox.shrink()),
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    'Free',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    'Pro',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          // Deliberately only lists what's actually gated (verified against
          // the code, not aspirational): buddy streaks and full history are
          // free for everyone, always — an earlier version of this screen
          // listed them as Pro perks, which didn't match what free users
          // actually saw and was a real source of confusion.
          const _ComparisonRow(
            label: 'Manual expense logging, streaks, and the owl',
            free: true,
            pro: true,
          ),
          const _ComparisonRow(
            label: 'Buddy streaks and full budget history',
            free: true,
            pro: true,
          ),
          const _ComparisonRow(
            label: 'Streak freezes if you miss a day',
            free: '1 free',
            pro: 'Unlimited',
          ),
          const _ComparisonRow(
            label: 'Spending insights',
            free: false,
            pro: true,
          ),
          const SizedBox(height: 24),
          _PlanCard(
            title: 'Founding Lifetime',
            price: subscription.lifetimePrice,
            subtitle:
                'One early-supporter price. No subscription, ads, or bank connection.',
            highlighted: true,
            onTap: busy || !subscription.storeAvailable
                ? null
                : () => _purchase(context),
          ),
          if (busy) ...[
            const SizedBox(height: 12),
            const Center(child: CircularProgressIndicator()),
          ],
          if (!busy && !subscription.storeAvailable) ...[
            const SizedBox(height: 12),
            Text(
              subscription.errorMessage ??
                  'Purchases are unavailable. Check your connection and try again later.',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 24),
          const Text(
            'Founding Lifetime is a one-time, non-consumable App Store purchase. '
            'It unlocks the Pro features shown above for the life of the app and '
            'can be restored on another device using the same Apple ID.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              TextButton(
                onPressed: () => _openLink(context, LegalLinks.termsOfUse),
                child: const Text('Terms of Use'),
              ),
              const Text('·'),
              TextButton(
                onPressed: () => _openLink(context, LegalLinks.privacyPolicy),
                child: const Text('Privacy Policy'),
              ),
            ],
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
}

/// A "what you keep for free" vs "what Pro adds" row — accepts either a
/// bool (checkmark/nothing) or a short label (e.g. "1 free" / "Unlimited")
/// per column, so the same row shape works for both binary features and
/// ones with a real free-tier allowance.
class _ComparisonRow extends StatelessWidget {
  final String label;
  final Object free;
  final Object pro;

  const _ComparisonRow({
    required this.label,
    required this.free,
    required this.pro,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Expanded(flex: 2, child: Center(child: _cell(context, free))),
          Expanded(
            flex: 2,
            child: Center(child: _cell(context, pro, isPro: true)),
          ),
        ],
      ),
    );
  }

  Widget _cell(BuildContext context, Object value, {bool isPro = false}) {
    if (value is bool) {
      return value
          ? Icon(
              Icons.check,
              color: Theme.of(context).colorScheme.primary,
              size: 18,
            )
          : Icon(
              Icons.close,
              color: Theme.of(context).colorScheme.outline,
              size: 18,
            );
    }
    return Text(
      value as String,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        fontWeight: isPro ? FontWeight.bold : FontWeight.normal,
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String subtitle;
  final bool highlighted;
  final VoidCallback? onTap;

  const _PlanCard({
    required this.title,
    required this.price,
    required this.subtitle,
    required this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: highlighted
          ? Theme.of(context).colorScheme.primaryContainer
          : null,
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: FilledButton(onPressed: onTap, child: Text(price)),
      ),
    );
  }
}

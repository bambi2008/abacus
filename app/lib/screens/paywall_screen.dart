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

  Future<void> _purchase(BuildContext context, String productId) async {
    await context.read<SubscriptionProvider>().purchase(productId);
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final subscription = context.watch<SubscriptionProvider>();
    String priceFor(String productId, String fallback) => subscription.productFor(productId)?.price ?? fallback;

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
                  child: Text('Free', style: Theme.of(context).textTheme.labelLarge),
                ),
              ),
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    'Pro',
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
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
            title: 'Lifetime',
            price: priceFor(ProductIds.lifetime, '\$89.99 once'),
            subtitle: 'No subscription trap — pay once, use forever',
            highlighted: true,
            onTap: () => _purchase(context, ProductIds.lifetime),
          ),
          const SizedBox(height: 12),
          _PlanCard(
            title: 'Monthly',
            price: priceFor(ProductIds.monthly, '\$7.99 / month'),
            subtitle: 'Not sure yet? Try it month to month',
            onTap: () => _purchase(context, ProductIds.monthly),
          ),
          const SizedBox(height: 24),
          // App Store requires auto-renewable subscriptions to disclose the
          // renewal terms and cancellation path in the binary, plus reachable
          // links to the Terms/EULA and Privacy Policy (Guideline 3.1.2).
          Text(
            'The monthly plan is an auto-renewing subscription: it renews each '
            'month at the price shown above unless you cancel at least 24 hours '
            'before the period ends. Manage or cancel anytime in your device '
            'Settings → Apple ID → Subscriptions. The Lifetime plan is a '
            'one-time purchase, not a subscription.',
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
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the link — check your connection.')),
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

  const _ComparisonRow({required this.label, required this.free, required this.pro});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
          Expanded(flex: 2, child: Center(child: _cell(context, free))),
          Expanded(flex: 2, child: Center(child: _cell(context, pro, isPro: true))),
        ],
      ),
    );
  }

  Widget _cell(BuildContext context, Object value, {bool isPro = false}) {
    if (value is bool) {
      return value
          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary, size: 18)
          : Icon(Icons.close, color: Theme.of(context).colorScheme.outline, size: 18);
    }
    return Text(
      value as String,
      style: Theme.of(context)
          .textTheme
          .bodySmall
          ?.copyWith(fontWeight: isPro ? FontWeight.bold : FontWeight.normal),
      textAlign: TextAlign.center,
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String subtitle;
  final bool highlighted;
  final VoidCallback onTap;

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
      color: highlighted ? Theme.of(context).colorScheme.primaryContainer : null,
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: FilledButton(onPressed: onTap, child: Text(price)),
      ),
    );
  }
}

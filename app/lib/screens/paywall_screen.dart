import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
          const SizedBox(height: 8),
          const Text(
            'Unlimited streak freezes, buddy streaks, spending insights, '
            'and full budget history.',
            textAlign: TextAlign.center,
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
        ],
      ),
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/constants.dart';
import '../providers/category_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/onboarding_provider.dart';
import '../services/analytics_service.dart';

/// 4-step onboarding per docs/product-design.md: positioning (no account
/// wall), pick starter categories, log a real first expense (the Day-1
/// guaranteed win), then ask for notification permission — deliberately
/// AFTER the win, not before. The paywall is never shown here; first
/// exposure is Day 5+ or the first free-tier limit hit (see PaywallScreen).
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  // All presets pre-selected by default — with only 6, all of them are
  // worth tracking under the "beyond survival spending" philosophy rather
  // than making the user prune a long list on Day 1.
  final _selectedCategories = Set<int>.from(List.generate(StarterCategories.presets.length, (i) => i));
  bool _firstExpenseLogged = false;

  void _next() {
    _pageController.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  Future<void> _confirmFirstExpense() async {
    final categoryProvider = context.read<CategoryProvider>();
    final expenseProvider = context.read<ExpenseProvider>();
    await categoryProvider.seedFromPresets(_selectedCategories.toList()..sort());
    final foodCategory = categoryProvider.all.first;
    await expenseProvider.addExpense(amount: 5.00, categoryId: foodCategory.id, note: 'Coffee');
    AnalyticsService.instance.capture('onboarding_first_expense_logged');
    setState(() => _firstExpenseLogged = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _PositioningPage(onNext: _next),
            _PickCategoriesPage(
              selected: _selectedCategories,
              onToggle: (i) => setState(() {
                _selectedCategories.contains(i) ? _selectedCategories.remove(i) : _selectedCategories.add(i);
              }),
              onNext: _next,
            ),
            _FirstExpensePage(
              logged: _firstExpenseLogged,
              onConfirm: _confirmFirstExpense,
              onNext: _next,
            ),
            _NotificationPermissionPage(
              onFinish: () => context.read<OnboardingProvider>().complete(),
            ),
          ],
        ),
      ),
    );
  }
}

class _PositioningPage extends StatelessWidget {
  final VoidCallback onNext;
  const _PositioningPage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🧮', style: TextStyle(fontSize: 72)),
          const SizedBox(height: 24),
          Text(
            'Track spending without connecting your bank. Ever.',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'No account required to start. Your data stays on this device.',
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          FilledButton(onPressed: onNext, child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 8),
            child: Text('Get Started'),
          )),
        ],
      ),
    );
  }
}

class _PickCategoriesPage extends StatelessWidget {
  final Set<int> selected;
  final void Function(int) onToggle;
  final VoidCallback onNext;

  const _PickCategoriesPage({required this.selected, required this.onToggle, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What do you spend on?', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text('Pick a few to start — you can add, edit, or remove these anytime.'),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: List.generate(StarterCategories.presets.length, (i) {
              final (name, emoji, colorValue) = StarterCategories.presets[i];
              final isSelected = selected.contains(i);
              return FilterChip(
                label: Text('$emoji $name'),
                selected: isSelected,
                selectedColor: Color(colorValue).withValues(alpha: 0.25),
                onSelected: (_) => onToggle(i),
              );
            }),
          ),
          const Spacer(),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: selected.isEmpty ? null : onNext,
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FirstExpensePage extends StatelessWidget {
  final bool logged;
  final VoidCallback onConfirm;
  final VoidCallback onNext;

  const _FirstExpensePage({required this.logged, required this.onConfirm, required this.onNext});

  @override
  Widget build(BuildContext context) {
    if (logged) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🔥', style: TextStyle(fontSize: 96)),
            const SizedBox(height: 16),
            Text('Day 1', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            const Text('You logged your first expense. Streak started.', textAlign: TextAlign.center),
            const Spacer(),
            FilledButton(onPressed: onNext, child: const Text('Continue')),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Log your first expense', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text('We filled one in for you — just confirm it.'),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: const Text('🍔', style: TextStyle(fontSize: 28)),
              title: const Text('Coffee'),
              subtitle: const Text('Food'),
              trailing: Text('\$5.00', style: Theme.of(context).textTheme.titleMedium),
            ),
          ),
          const Spacer(),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(onPressed: onConfirm, child: const Text('Confirm')),
          ),
        ],
      ),
    );
  }
}

class _NotificationPermissionPage extends StatelessWidget {
  final VoidCallback onFinish;
  const _NotificationPermissionPage({required this.onFinish});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.notifications_active_outlined, size: 72),
          const SizedBox(height: 24),
          Text(
            'Get a nudge before your streak resets',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'We\'ll only remind you when a streak is actually at risk — not every day.',
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          FilledButton(onPressed: onFinish, child: const Text('Enable Reminders')),
          TextButton(onPressed: onFinish, child: const Text('Not Now')),
        ],
      ),
    );
  }
}

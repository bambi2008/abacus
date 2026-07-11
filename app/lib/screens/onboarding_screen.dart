import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/constants.dart';
import '../config/theme.dart';
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
  // Categories the user typed in themselves on the picker page — the copy
  // there ("you can add... anytime") wasn't actually backed by an add flow
  // until 2026-07-06, so this exists specifically to make that claim true.
  final _customCategories = <(String name, String emoji, int colorValue, double monthlyLimit)>[];
  bool _firstExpenseLogged = false;

  void _next() {
    _pageController.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  void _addCustomCategory(String name, String emoji, int colorValue, double monthlyLimit) {
    setState(() => _customCategories.add((name, emoji, colorValue, monthlyLimit)));
  }

  void _removeCustomCategory(int index) {
    setState(() => _customCategories.removeAt(index));
  }

  /// The preset/custom category the Day-1 example expense gets attached
  /// to. Prefers "Snacks & Drinks" specifically — a coffee purchase is the
  /// clearest real-world fit for it among the discretionary categories —
  /// falling back to whatever the user actually picked if that one wasn't
  /// selected. Used by both the preview card (before anything's created)
  /// and the real category lookup on confirm, so the two always agree.
  (String name, String emoji) get _exampleCategory {
    final snacksIndex = StarterCategories.presets.indexWhere((p) => p.$1 == 'Snacks & Drinks');
    if (snacksIndex != -1 && _selectedCategories.contains(snacksIndex)) {
      final preset = StarterCategories.presets[snacksIndex];
      return (preset.$1, preset.$2);
    }
    if (_selectedCategories.isNotEmpty) {
      final firstIndex = (_selectedCategories.toList()..sort()).first;
      final preset = StarterCategories.presets[firstIndex];
      return (preset.$1, preset.$2);
    }
    if (_customCategories.isNotEmpty) {
      final custom = _customCategories.first;
      return (custom.$1, custom.$2);
    }
    // Unreachable in practice ("Continue" is disabled while both are
    // empty) — kept total rather than throwing.
    final preset = StarterCategories.presets.first;
    return (preset.$1, preset.$2);
  }

  Future<void> _confirmFirstExpense() async {
    final categoryProvider = context.read<CategoryProvider>();
    final expenseProvider = context.read<ExpenseProvider>();
    await categoryProvider.seedFromPresets(_selectedCategories.toList()..sort());
    for (final custom in _customCategories) {
      await categoryProvider.add(custom.$1, custom.$2, custom.$3, custom.$4);
    }
    final exampleName = _exampleCategory.$1;
    final exampleCategory = categoryProvider.all.firstWhere(
      (c) => c.name == exampleName,
      orElse: () => categoryProvider.all.first,
    );
    await expenseProvider.addExpense(amount: 5.00, categoryId: exampleCategory.id, note: 'Coffee');
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
              custom: _customCategories,
              onToggle: (i) => setState(() {
                _selectedCategories.contains(i) ? _selectedCategories.remove(i) : _selectedCategories.add(i);
              }),
              onAddCustom: _addCustomCategory,
              onRemoveCustom: _removeCustomCategory,
              onNext: _next,
            ),
            _FirstExpensePage(
              logged: _firstExpenseLogged,
              exampleCategory: _exampleCategory,
              onConfirm: _confirmFirstExpense,
              onNext: _next,
            ),
            _AllSetPage(
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
          const Text('🧮', style: TextStyle(fontSize: AppIconSizes.xlarge)),
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
  final List<(String name, String emoji, int colorValue, double monthlyLimit)> custom;
  final void Function(int) onToggle;
  final void Function(String name, String emoji, int colorValue, double monthlyLimit) onAddCustom;
  final void Function(int index) onRemoveCustom;
  final VoidCallback onNext;

  const _PickCategoriesPage({
    required this.selected,
    required this.custom,
    required this.onToggle,
    required this.onAddCustom,
    required this.onRemoveCustom,
    required this.onNext,
  });

  Future<void> _showAddCustomDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final emojiController = TextEditingController();
    final limitController = TextEditingController(text: '100');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add a category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emojiController,
              decoration: const InputDecoration(labelText: 'Emoji (optional)'),
            ),
            const SizedBox(height: 12),
            // Asked here, not silently defaulted — a $200 limit baked in
            // with zero visibility was the exact confusion a real-device
            // tester hit: the boss-battle bar's 100% didn't correspond to
            // any number they'd ever seen or chosen.
            TextField(
              controller: limitController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Monthly limit', prefixText: '\$'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Add')),
        ],
      ),
    );
    if (confirmed != true) return;
    final name = nameController.text.trim();
    if (name.isEmpty) return;
    final emoji = emojiController.text.trim().isEmpty ? '📌' : emojiController.text.trim();
    final limit = double.tryParse(limitController.text.trim()) ?? 100.0;
    // A neutral, unopinionated color for anything the user names
    // themselves — the six presets each get a deliberate color, a custom
    // one doesn't need to mean anything.
    onAddCustom(name, emoji, 0xFF546E7A, limit);
  }

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
            children: [
              ...List.generate(StarterCategories.presets.length, (i) {
                final (name, emoji, colorValue, _) = StarterCategories.presets[i];
                final isSelected = selected.contains(i);
                return FilterChip(
                  label: Text('$emoji $name'),
                  selected: isSelected,
                  selectedColor: Color(colorValue).withValues(alpha: 0.25),
                  onSelected: (_) => onToggle(i),
                );
              }),
              ...List.generate(custom.length, (i) {
                final (name, emoji, colorValue, monthlyLimit) = custom[i];
                return InputChip(
                  label: Text('$emoji $name (\$${monthlyLimit.toStringAsFixed(0)}/mo)'),
                  backgroundColor: Color(colorValue).withValues(alpha: 0.25),
                  onDeleted: () => onRemoveCustom(i),
                );
              }),
              ActionChip(
                avatar: const Icon(Icons.add, size: 18),
                label: const Text('Add custom'),
                onPressed: () => _showAddCustomDialog(context),
              ),
            ],
          ),
          const Spacer(),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: (selected.isEmpty && custom.isEmpty) ? null : onNext,
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
  final (String name, String emoji) exampleCategory;
  final VoidCallback onConfirm;
  final VoidCallback onNext;

  const _FirstExpensePage({
    required this.logged,
    required this.exampleCategory,
    required this.onConfirm,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    if (logged) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🔥', style: TextStyle(fontSize: AppIconSizes.hero)),
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
              leading: Text(exampleCategory.$2, style: const TextStyle(fontSize: AppIconSizes.medium)),
              title: const Text('Coffee'),
              subtitle: Text(exampleCategory.$1),
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

/// Honest completion page. This slot used to be a "Get a nudge before your
/// streak resets" reminder-permission screen whose "Enable Reminders" and
/// "Not Now" buttons did the exact same thing (just finish onboarding) —
/// the app schedules no notifications at all, so it promised a feature that
/// doesn't exist. Reminders are a deliberate post-launch (v1.1) fast-follow
/// that needs real on-device scheduling + permission work; until then this
/// stays an honest "you're set up" summary rather than a false promise.
class _AllSetPage extends StatelessWidget {
  final VoidCallback onFinish;
  const _AllSetPage({required this.onFinish});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🧮', style: TextStyle(fontSize: AppIconSizes.xlarge)),
          const SizedBox(height: 24),
          Text(
            'You\'re all set',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'Log an expense each day to build your streak. Everything stays on '
            'your device — no account, no bank linking.',
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          FilledButton(onPressed: onFinish, child: const Text('Start budgeting')),
        ],
      ),
    );
  }
}

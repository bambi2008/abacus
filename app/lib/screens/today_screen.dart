import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../providers/category_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/gamification_provider.dart';
import 'milestone_celebration_screen.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final expenses = context.watch<ExpenseProvider>();
    final categories = context.watch<CategoryProvider>();
    final streak = expenses.currentStreak;
    final loggedToday = expenses.loggedToday;
    final isEvening = DateTime.now().hour >= 18;
    final atRisk = !loggedToday && isEvening && streak > 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Today'),
        actions: [
          if (expenses.freeStreakFreezesAvailable > 0)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Tooltip(
                  message: '${expenses.freeStreakFreezesAvailable} streak freeze available',
                  child: const Icon(Icons.shield_outlined),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _StreakCard(streak: streak, atRisk: atRisk),
            const SizedBox(height: 16),
            Text('Today\'s spending', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('\$${expenses.todaySpend.toStringAsFixed(2)}', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            ...categories.all.map((c) => _CategoryBar(category: c, spentToday: expenses.spendForCategoryToday(c.id))),
            const SizedBox(height: 96),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showLogExpenseSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Log an expense'),
      ),
    );
  }

  void _showLogExpenseSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _LogExpenseSheet(),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final int streak;
  final bool atRisk;
  const _StreakCard({required this.streak, required this.atRisk});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: atRisk ? Theme.of(context).colorScheme.errorContainer : Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // AnimatedSwitcher plays an elastic "pop" whenever the streak
            // value changes (increment or the 🔥/🔒 swap at zero); the
            // wrapped flutter_animate chain gives it a continuous idle
            // "breathing" pulse the rest of the time, so the card feels
            // alive even between logs, not just at the moment of change.
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: CurvedAnimation(parent: animation, curve: Curves.elasticOut),
                child: child,
              ),
              child: Text(
                streak > 0 ? '🔥' : '🔒',
                key: ValueKey(streak),
                style: const TextStyle(fontSize: 40),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.08, 1.08),
                    duration: 1800.ms,
                    curve: Curves.easeInOut,
                  ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$streak-day streak',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  // Loss-aversion framing when a streak is actually at risk —
                  // never generic "don't forget" copy. See
                  // docs/technical-architecture.md.
                  Text(
                    atRisk
                        ? 'You\'re about to lose your $streak-day streak — log something now.'
                        : streak == 0
                            ? 'Log an expense to start a streak.'
                            : 'Keep it going — log at least one expense today.',
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

class _CategoryBar extends StatelessWidget {
  final ExpenseCategory category;
  final double spentToday;
  const _CategoryBar({required this.category, required this.spentToday});

  @override
  Widget build(BuildContext context) {
    final dailyShare = category.monthlyLimit / 30;
    final progress = dailyShare <= 0 ? 0.0 : (spentToday / dailyShare).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('${category.emoji} ${category.name}'),
              const Spacer(),
              Text('\$${spentToday.toStringAsFixed(0)} of \$${dailyShare.toStringAsFixed(0)}'),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              color: Color(category.colorValue),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogExpenseSheet extends StatefulWidget {
  const _LogExpenseSheet();

  @override
  State<_LogExpenseSheet> createState() => _LogExpenseSheetState();
}

class _LogExpenseSheetState extends State<_LogExpenseSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String? _selectedCategoryId;
  bool _confirmed = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _confirm(BuildContext context) async {
    if (_confirmed) return;
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0 || _selectedCategoryId == null) return;
    // Light haptic on every routine log — deliberately the *light* variant,
    // reserving stronger haptics/confetti for milestones only. See
    // docs/technical-architecture.md's "game feel" calibration.
    HapticFeedback.lightImpact();
    setState(() => _confirmed = true);
    final expenseProvider = context.read<ExpenseProvider>();
    final gamificationProvider = context.read<GamificationProvider>();
    final navigator = Navigator.of(context);
    await expenseProvider.addExpense(
      amount: amount,
      categoryId: _selectedCategoryId!,
      note: _noteController.text,
    );
    final badge = await gamificationProvider.checkForNewMilestone(expenseProvider.currentStreak);
    // Brief pause so the inline checkmark is actually seen before the sheet
    // closes — this replaces the previous silent, instant dismiss.
    await Future.delayed(const Duration(milliseconds: 300));
    navigator.pop();
    if (badge != null) {
      navigator.push(MaterialPageRoute(builder: (_) => MilestoneCelebrationScreen(badge: badge)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>().all;
    _selectedCategoryId ??= categories.isNotEmpty ? categories.first.id : null;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Log an expense', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Amount', prefixText: '\$'),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: categories.map((c) {
              return ChoiceChip(
                label: Text('${c.emoji} ${c.name}'),
                selected: _selectedCategoryId == c.id,
                onSelected: (_) => setState(() => _selectedCategoryId = c.id),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(labelText: 'Note (optional)'),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _confirmed ? null : () => _confirm(context),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                child: _confirmed
                    ? const Icon(Icons.check, key: ValueKey('check'))
                    : const Text('Confirm', key: ValueKey('label')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

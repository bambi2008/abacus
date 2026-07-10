import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/monthly_savings_result.dart';
import '../models/spending_insight.dart';
import '../providers/category_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/gamification_provider.dart';
import '../providers/subscription_provider.dart';
import 'category_management_screen.dart';
import 'paywall_screen.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final expenses = context.watch<ExpenseProvider>();
    final categories = context.watch<CategoryProvider>();
    final gamification = context.watch<GamificationProvider>();
    final isPro = context.watch<SubscriptionProvider>().isPro;
    final now = DateTime.now();
    final spendByCategory = expenses.spendByCategoryInMonth(now);
    // Only computed for Pro — free users see the paywall prompt instead,
    // and the comparison is cheap either way (in-memory Hive box scan) but
    // there's no reason to build it when it won't be shown.
    final insight = isPro
        ? computeSpendingInsight(
            thisMonthSpend: spendByCategory,
            lastMonthSpend: expenses.spendByCategoryInMonth(DateTime(now.year, now.month - 1, 1)),
            categories: [for (final c in categories.all) (id: c.id, name: c.name, emoji: c.emoji)],
          )
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress'),
        actions: [
          IconButton(
            tooltip: 'Manage categories',
            icon: const Icon(Icons.tune),
            onPressed: () =>
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CategoryManagementScreen())),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _InsightCard(isPro: isPro, insight: insight),
          const SizedBox(height: 24),
          Text('This month by category', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: categories.all.isEmpty
                ? const Center(child: Text('Add a category to see spending here.'))
                : BarChart(
                    BarChartData(
                      gridData: const FlGridData(show: true),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i < 0 || i >= categories.all.length) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(categories.all[i].emoji, style: const TextStyle(fontSize: 16)),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: [
                        for (var i = 0; i < categories.all.length; i++)
                          BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: spendByCategory[categories.all[i].id] ?? 0,
                                color: Color(categories.all[i].colorValue),
                                width: 24,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 24),
          Text('Streak history', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          _StreakCalendar(month: now),
          const SizedBox(height: 24),
          Text('No-spend days', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Tap a day to mark it as a deliberate no-spend win.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          _NoSpendCalendar(month: now),
          const SizedBox(height: 24),
          Text('Monthly savings', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Vs. real U.S. averages for dining out, shopping, and entertainment (BLS).',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          _MonthlySavingsHistory(results: gamification.monthlySavingsHistory),
          const SizedBox(height: 24),
          Text('Recent entries', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ..._recentEntries(context, expenses, categories),
        ],
      ),
    );
  }

  List<Widget> _recentEntries(BuildContext context, ExpenseProvider expenses, CategoryProvider categories) {
    final today = DateTime.now();
    final entries = <Widget>[];
    for (var i = 0; i < 7; i++) {
      final day = today.subtract(Duration(days: i));
      final dayExpenses = expenses.expensesOn(day);
      for (final e in dayExpenses) {
        final category = categories.byId(e.categoryId);
        entries.add(Dismissible(
          key: ValueKey(e.id),
          direction: DismissDirection.endToStart,
          background: Container(color: Theme.of(context).colorScheme.errorContainer),
          onDismissed: (_) => expenses.deleteExpense(e.id),
          child: ListTile(
            leading: Text(category?.emoji ?? '❓', style: const TextStyle(fontSize: 24)),
            title: Text(e.note.isEmpty ? (category?.name ?? 'Uncategorized') : e.note),
            subtitle: Text('${day.month}/${day.day}'),
            trailing: Text('\$${e.amount.toStringAsFixed(2)}'),
          ),
        ));
      }
    }
    if (entries.isEmpty) {
      entries.add(const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text('No expenses logged yet.'),
      ));
    }
    return entries;
  }
}

/// Added 2026-07-06: the monthly savings recap used to be computed,
/// persisted, shown once as a full-screen celebration, and then
/// effectively invisible forever — there was no way anywhere in the app to
/// look back and ask "how did last month go?" This makes that history
/// visible. Deliberately shows $0 months too, not just wins — cherry-
/// picking only the good months would make this decorative rather than an
/// honest record.
class _MonthlySavingsHistory extends StatelessWidget {
  final List<MonthlySavingsResult> results;
  const _MonthlySavingsHistory({required this.results});

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return const Text('Your first monthly recap appears here after your first full month of tracking.');
    }
    return Column(
      children: results.map((r) {
        final saved = r.totalSaved;
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Text(saved > 0 ? '💰' : '➖', style: const TextStyle(fontSize: 20)),
          title: Text('${_monthName(r.month)} ${r.year}'),
          trailing: Text(
            saved > 0 ? 'Saved \$${saved.toStringAsFixed(0)}' : 'No savings that month',
            style: TextStyle(
              fontWeight: saved > 0 ? FontWeight.bold : FontWeight.normal,
              color: saved > 0
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        );
      }).toList(),
    );
  }

  String _monthName(int month) {
    const names = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return names[month - 1];
  }
}

/// Previously this card unlocked for Pro but had no real content behind
/// it — `onTap: null` and generic filler text regardless of the user's
/// actual data. A paying customer got nothing for the app's one remaining
/// real Pro benefit. Now shows an actual computed insight (see
/// models/spending_insight.dart) when there's enough data, and an honest
/// "not enough data yet" state rather than fabricating one when there isn't.
class _InsightCard extends StatelessWidget {
  final bool isPro;
  final SpendingInsight? insight;
  const _InsightCard({required this.isPro, required this.insight});

  @override
  Widget build(BuildContext context) {
    if (!isPro) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.lock_outline),
          title: const Text('Unlock spending insights'),
          subtitle: const Text('See how this month compares to your average, generated from your own data.'),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallScreen())),
        ),
      );
    }
    if (insight == null) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.insights),
          title: Text('Spending insight'),
          subtitle: Text('Log a few expenses this month to see your first insight here.'),
        ),
      );
    }
    final change = insight!.changeFraction;
    final subtitle = change == null
        ? '\$${insight!.thisMonthAmount.toStringAsFixed(0)} so far this month — no comparison yet, '
            'this is the first month you\'ve logged this category.'
        : '\$${insight!.thisMonthAmount.toStringAsFixed(0)} so far this month, '
            '${change >= 0 ? 'up' : 'down'} ${(change.abs() * 100).round()}% from last month '
            '(\$${insight!.lastMonthAmount.toStringAsFixed(0)}).';
    return Card(
      child: ListTile(
        leading: Text(insight!.categoryEmoji, style: const TextStyle(fontSize: 24)),
        title: Text('${insight!.categoryName} is your top category'),
        subtitle: Text(subtitle),
      ),
    );
  }
}

/// Visually distinct from _StreakCalendar (a different fill color, and
/// cells are tappable) — a no-spend day is a separate, opt-in signal, not
/// the same thing as "logged an expense." See
/// GamificationProvider.markNoSpendDay and docs/technical-architecture.md.
class _NoSpendCalendar extends StatelessWidget {
  final DateTime month;
  const _NoSpendCalendar({required this.month});

  @override
  Widget build(BuildContext context) {
    final gamification = context.watch<GamificationProvider>();
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final today = DateTime.now();
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(daysInMonth, (i) {
        final day = DateTime(month.year, month.month, i + 1);
        final marked = gamification.isNoSpendDay(day);
        final isFuture = day.isAfter(today);
        return GestureDetector(
          onTap: isFuture || marked ? null : () => _confirmMark(context, day),
          child: Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isFuture
                  ? Colors.transparent
                  : marked
                      ? Theme.of(context).colorScheme.tertiary
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            child: Text(
              marked ? '💚' : '${i + 1}',
              style: TextStyle(
                fontSize: marked ? 12 : 10,
                color: marked ? Theme.of(context).colorScheme.onTertiary : null,
              ),
            ),
          ),
        );
      }),
    );
  }

  Future<void> _confirmMark(BuildContext context, DateTime day) async {
    final gamification = context.read<GamificationProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Mark ${day.month}/${day.day} as a no-spend day?'),
        content: const Text('This is a separate win from your logging streak — a deliberate day you chose not to spend.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Mark it')),
        ],
      ),
    );
    if (confirmed == true) {
      await gamification.markNoSpendDay(day);
    }
  }
}

class _StreakCalendar extends StatelessWidget {
  final DateTime month;
  const _StreakCalendar({required this.month});

  @override
  Widget build(BuildContext context) {
    final expenses = context.watch<ExpenseProvider>();
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(daysInMonth, (i) {
        final day = DateTime(month.year, month.month, i + 1);
        final completion = expenses.completionOn(day);
        final filled = completion != null && (completion.loggedAnyExpense || completion.usedStreakFreeze);
        final isFuture = day.isAfter(DateTime.now());
        return Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFuture
                ? Colors.transparent
                : filled
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          child: Text(
            '${i + 1}',
            style: TextStyle(
              fontSize: 10,
              color: filled ? Theme.of(context).colorScheme.onPrimary : null,
            ),
          ),
        );
      }),
    );
  }
}

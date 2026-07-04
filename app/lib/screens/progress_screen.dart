import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/category_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/subscription_provider.dart';
import 'paywall_screen.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final expenses = context.watch<ExpenseProvider>();
    final categories = context.watch<CategoryProvider>();
    final isPro = context.watch<SubscriptionProvider>().isPro;
    final now = DateTime.now();
    final spendByCategory = expenses.spendByCategoryInMonth(now);

    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _InsightCard(isPro: isPro),
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

class _InsightCard extends StatelessWidget {
  final bool isPro;
  const _InsightCard({required this.isPro});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(isPro ? Icons.insights : Icons.lock_outline),
        title: Text(isPro ? 'Spending insight' : 'Unlock spending insights'),
        subtitle: Text(
          isPro
              ? 'You\'ve been logging consistently — keep an eye on your top category this month.'
              : 'See how this month compares to your average, generated from your own data.',
        ),
        onTap: isPro
            ? null
            : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallScreen())),
      ),
    );
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

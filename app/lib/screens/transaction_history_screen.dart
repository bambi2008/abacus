import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../providers/category_provider.dart';
import '../providers/expense_provider.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expenses = context.watch<ExpenseProvider>();
    final categories = context.watch<CategoryProvider>();
    final query = _search.text.trim().toLowerCase();
    final visible = expenses.allExpenses.where((expense) {
      final category =
          categories.byId(expense.categoryId)?.name ?? 'Uncategorized';
      return query.isEmpty ||
          expense.note.toLowerCase().contains(query) ||
          category.toLowerCase().contains(query) ||
          expense.amount.toStringAsFixed(2).contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Transaction history')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _search,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search note, category, or amount',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: visible.isEmpty
                ? const Center(child: Text('No matching transactions.'))
                : ListView.builder(
                    itemCount: visible.length,
                    itemBuilder: (context, index) {
                      final expense = visible[index];
                      final category = categories.byId(expense.categoryId);
                      return Dismissible(
                        key: ValueKey(expense.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Theme.of(context).colorScheme.errorContainer,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          child: const Icon(Icons.delete_outline),
                        ),
                        onDismissed: (_) async {
                          await expenses.deleteExpense(expense.id);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Transaction deleted.'),
                              action: SnackBarAction(
                                label: 'Undo',
                                onPressed: () =>
                                    expenses.updateExpense(expense),
                              ),
                            ),
                          );
                        },
                        child: ListTile(
                          leading: Text(
                            category?.emoji ?? '❓',
                            style: const TextStyle(fontSize: 24),
                          ),
                          title: Text(
                            expense.note.isEmpty
                                ? (category?.name ?? 'Uncategorized')
                                : expense.note,
                          ),
                          subtitle: Text(
                            '${category?.name ?? 'Uncategorized'} · ${DateFormat.yMMMd().format(expense.date)}',
                          ),
                          trailing: Text(
                            '\$${expense.amount.toStringAsFixed(2)}',
                          ),
                          onTap: () => _editExpense(context, expense),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _editExpense(BuildContext context, Expense expense) async {
    final expenseProvider = context.read<ExpenseProvider>();
    final categories = context.read<CategoryProvider>().all;
    final amountController = TextEditingController(
      text: expense.amount.toStringAsFixed(2),
    );
    final noteController = TextEditingController(text: expense.note);
    var categoryId = expense.categoryId;
    var date = expense.date;

    final updated = await showDialog<Expense>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit transaction'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Amount'),
                ),
                DropdownButtonFormField<String>(
                  initialValue: categoryId,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: [
                    for (final category in categories)
                      DropdownMenuItem(
                        value: category.id,
                        child: Text('${category.emoji} ${category.name}'),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) setDialogState(() => categoryId = value);
                  },
                ),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(labelText: 'Note'),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: Text(DateFormat.yMMMd().format(date)),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                      initialDate: date.isAfter(DateTime.now())
                          ? DateTime.now()
                          : date,
                    );
                    if (picked != null) {
                      setDialogState(
                        () => date = DateTime(
                          picked.year,
                          picked.month,
                          picked.day,
                          date.hour,
                          date.minute,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text.trim());
                if (amount == null || amount <= 0) return;
                Navigator.pop(
                  dialogContext,
                  expense.copyWith(
                    amount: amount,
                    categoryId: categoryId,
                    note: noteController.text.trim(),
                    date: date,
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    amountController.dispose();
    noteController.dispose();
    if (updated != null) await expenseProvider.updateExpense(updated);
  }
}

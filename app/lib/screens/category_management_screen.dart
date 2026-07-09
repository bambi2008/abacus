import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../providers/category_provider.dart';

/// The category management screen `docs/product-design.md` always
/// described ("Progress → Edit Budgets") but that never actually got
/// built — until 2026-07-06, onboarding was the *only* place a category
/// could be created, and nothing after that could add, edit, or delete
/// one. Add/edit share one dialog; delete is a swipe with a confirmation
/// that's honest about what happens to past expenses (they aren't
/// deleted, just unlinked — see `progress_screen.dart`'s
/// `category?.name ?? 'Uncategorized'` fallback, which already handled
/// this gracefully before this screen existed to trigger it).
class CategoryManagementScreen extends StatelessWidget {
  const CategoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>().all;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage categories'),
        actions: [
          IconButton(
            tooltip: 'Add a category',
            icon: const Icon(Icons.add),
            onPressed: () => _showAddOrEditDialog(context),
          ),
        ],
      ),
      body: categories.isEmpty
          ? const Center(child: Text('No categories yet — add one to start tracking.'))
          : ListView(
              children: categories
                  .map((c) => Dismissible(
                        key: ValueKey(c.id),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) => _confirmDelete(context, c),
                        onDismissed: (_) => context.read<CategoryProvider>().remove(c.id),
                        background: Container(
                          color: Theme.of(context).colorScheme.errorContainer,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.onErrorContainer),
                        ),
                        child: ListTile(
                          leading: Text(c.emoji, style: const TextStyle(fontSize: 28)),
                          title: Text(c.name),
                          subtitle: Text('\$${c.monthlyLimit.toStringAsFixed(0)}/month limit'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _showAddOrEditDialog(context, existing: c),
                        ),
                      ))
                  .toList(),
            ),
    );
  }

  Future<void> _showAddOrEditDialog(BuildContext context, {ExpenseCategory? existing}) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final emojiController = TextEditingController(text: existing?.emoji ?? '');
    final limitController = TextEditingController(
      text: existing != null ? existing.monthlyLimit.toStringAsFixed(0) : '',
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Add a category' : 'Edit category'),
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
            TextField(
              controller: limitController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Monthly limit', prefixText: '\$'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(existing == null ? 'Add' : 'Save')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final name = nameController.text.trim();
    if (name.isEmpty) return;
    final emoji = emojiController.text.trim().isEmpty ? '📌' : emojiController.text.trim();
    final limit = double.tryParse(limitController.text.trim()) ?? existing?.monthlyLimit ?? 0.0;
    final provider = context.read<CategoryProvider>();
    if (existing == null) {
      // A neutral color for anything the user names themselves — the
      // starter presets each get a deliberate color, a custom one
      // doesn't need to mean anything.
      await provider.add(name, emoji, 0xFF546E7A, limit);
    } else {
      await provider.update(existing.copyWith(name: name, emoji: emoji, monthlyLimit: limit));
    }
  }

  Future<bool> _confirmDelete(BuildContext context, ExpenseCategory category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${category.name}?'),
        content: const Text(
          'Past expenses in this category aren\'t deleted — they\'ll just show as "Uncategorized."',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }
}

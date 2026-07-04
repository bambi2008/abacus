import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/category.dart';
import '../models/expense.dart';

/// CSV export — a real trust signal for the "your data, not ours"
/// positioning, and functionally necessary since there's no bank sync to
/// fall back on if a user wants their history elsewhere. See
/// docs/product-design.md.
class ExportService {
  static Future<void> exportExpenses(List<Expense> expenses, List<ExpenseCategory> categories) async {
    final categoryNames = {for (final c in categories) c.id: c.name};
    final rows = [
      ['Date', 'Category', 'Amount', 'Note'],
      for (final e in expenses)
        [
          e.date.toIso8601String().split('T').first,
          categoryNames[e.categoryId] ?? 'Uncategorized',
          e.amount.toStringAsFixed(2),
          e.note,
        ],
    ];
    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/abacus_export.csv');
    await file.writeAsString(csv);
    await Share.shareXFiles([XFile(file.path)], text: 'Abacus expense export');
  }
}

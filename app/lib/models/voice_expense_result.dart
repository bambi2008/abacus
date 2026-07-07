import '../models/category.dart';

/// Best-guess amount/category extracted from a spoken transcript — like
/// [ReceiptScanResult], this only ever pre-fills the manual log-expense
/// sheet; the user still confirms or edits every field before it becomes a
/// real Expense. [note] is always the raw transcript (never dropped) so the
/// user can see exactly what was heard even when parsing gets it wrong.
class VoiceExpenseResult {
  final double? amount;
  final String? categoryId;
  final String note;

  const VoiceExpenseResult({this.amount, this.categoryId, required this.note});
}

/// Pure heuristic over a speech-to-text transcript — independently unit
/// tested (test/voice_expense_heuristics_test.dart) since the actual speech
/// recognition can't run in CI. Deliberately simple: take the first number
/// spoken as the amount (speech recognizers normalize spoken numbers like
/// "fifty" to digits in their text output), and match a category by seeing
/// if any of the user's own category names appears in the transcript.
VoiceExpenseResult parseVoiceExpense(String transcript, List<ExpenseCategory> categories) {
  final amount = _extractAmount(transcript);
  final categoryId = _matchCategory(transcript, categories);
  return VoiceExpenseResult(amount: amount, categoryId: categoryId, note: transcript.trim());
}

double? _extractAmount(String transcript) {
  final match = RegExp(r'(\d+(?:\.\d{1,2})?)').firstMatch(transcript);
  if (match == null) return null;
  return double.tryParse(match.group(1)!);
}

String? _matchCategory(String transcript, List<ExpenseCategory> categories) {
  final lower = transcript.toLowerCase();
  for (final category in categories) {
    if (lower.contains(category.name.toLowerCase())) return category.id;
  }
  return null;
}

/// Ephemeral result of scanning a receipt — never persisted to Hive. It only
/// exists to pre-fill the manual log-expense sheet; the user still confirms
/// (or edits) every field before it becomes a real Expense. This keeps the
/// "structured data the user typed" trust model intact — OCR assists entry,
/// it never silently creates a transaction on its own.
class ReceiptScanResult {
  final double? amount;
  final String? vendor;
  final DateTime? date;

  const ReceiptScanResult({this.amount, this.vendor, this.date});

  bool get isEmpty => amount == null && vendor == null && date == null;
}

/// Pulls a best-guess amount/vendor/date out of raw OCR text lines. Pure and
/// independently unit-tested (test/receipt_ocr_heuristics_test.dart) since
/// the native Vision recognition itself can't run in CI. Heuristics, not a
/// parser: receipts vary too much for anything stricter, and every field
/// stays user-editable in the log sheet regardless.
ReceiptScanResult parseReceiptText(List<String> lines) {
  final cleaned = lines.map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
  if (cleaned.isEmpty) return const ReceiptScanResult();

  final amount = _extractTotalAmount(cleaned);
  final vendor = _extractVendor(cleaned);
  final date = _extractDate(cleaned);
  return ReceiptScanResult(amount: amount, vendor: vendor, date: date);
}

/// Prefers a line that reads like a "Total" line; falls back to the largest
/// dollar amount found anywhere (receipts usually total more than any single
/// line item, and "Total" wording varies too much to rely on alone).
double? _extractTotalAmount(List<String> lines) {
  final moneyPattern = RegExp(r'\$?\s?(\d{1,5}(?:[.,]\d{2}))');
  double? totalLineAmount;
  double? largestAmount;

  for (final line in lines) {
    final match = moneyPattern.firstMatch(line);
    if (match == null) continue;
    final value = double.tryParse(match.group(1)!.replaceAll(',', '.'));
    if (value == null) continue;
    if (largestAmount == null || value > largestAmount) largestAmount = value;
    if (RegExp(r'total', caseSensitive: false).hasMatch(line) &&
        !RegExp(r'sub.?total', caseSensitive: false).hasMatch(line)) {
      totalLineAmount = value;
    }
  }
  return totalLineAmount ?? largestAmount;
}

/// The first substantial line is almost always the merchant/vendor name on a
/// real receipt (header, above any address/item lines) — matches the
/// heuristic already documented for this pattern.
String? _extractVendor(List<String> lines) {
  for (final line in lines) {
    if (line.length < 3) continue;
    if (RegExp(r'^\$?\d').hasMatch(line)) continue; // skip lines that are just numbers/amounts
    return line;
  }
  return null;
}

DateTime? _extractDate(List<String> lines) {
  final datePattern = RegExp(r'(\d{1,2})[/\-](\d{1,2})[/\-](\d{2,4})');
  for (final line in lines) {
    final match = datePattern.firstMatch(line);
    if (match == null) continue;
    final a = int.parse(match.group(1)!);
    final b = int.parse(match.group(2)!);
    var year = int.parse(match.group(3)!);
    if (year < 100) year += 2000;
    // Receipts are printed locale-dependent (MM/DD vs DD/MM) — assume
    // MM/DD/YYYY (US) since Abacus's initial market is US-first per
    // docs/customer-and-market.md, and fall back gracefully on invalid dates.
    try {
      return DateTime(year, a, b);
    } catch (_) {
      continue;
    }
  }
  return null;
}

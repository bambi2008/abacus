import 'package:flutter_test/flutter_test.dart';

import 'package:abacus/models/receipt_scan_result.dart';

// The native Vision recognition itself can't run in CI (it's an iOS-only
// on-device call) — what IS pure and testable is the heuristic parsing of
// whatever text lines Vision returns. These tests pin that behavior against
// realistic (hand-typed) receipt text shapes.

void main() {
  group('parseReceiptText', () {
    test('empty input yields an empty result', () {
      final result = parseReceiptText([]);
      expect(result.isEmpty, isTrue);
    });

    test('picks the "Total" line amount over a larger subtotal or tax line', () {
      final lines = [
        'Joe\'s Coffee Shop',
        '123 Main St',
        'Latte              4.50',
        'Subtotal          12.00',
        'Tax                1.05',
        'Total             13.05',
      ];
      final result = parseReceiptText(lines);
      expect(result.amount, 13.05);
    });

    test('falls back to the largest amount when no "Total" line exists', () {
      final lines = ['Corner Market', 'Bread    3.99', 'Milk     4.25'];
      final result = parseReceiptText(lines);
      expect(result.amount, 4.25);
    });

    test('does not confuse "Subtotal" with "Total"', () {
      final lines = ['Store', 'Subtotal 20.00'];
      final result = parseReceiptText(lines);
      // No true "Total" line, so it falls back to the largest amount found —
      // which happens to be the subtotal's value, but not because the
      // "total" keyword matched it.
      expect(result.amount, 20.00);
    });

    test('extracts the first substantial line as the vendor', () {
      final lines = ['Trader Joe\'s', '456 Elm St', 'Total 8.50'];
      final result = parseReceiptText(lines);
      expect(result.vendor, "Trader Joe's");
    });

    test('skips numeric-only leading lines when picking a vendor', () {
      final lines = ['12345', 'Whole Foods Market', 'Total 22.10'];
      final result = parseReceiptText(lines);
      expect(result.vendor, 'Whole Foods Market');
    });

    test('extracts a US-format date', () {
      final lines = ['Shop', '07/04/2026', 'Total 5.00'];
      final result = parseReceiptText(lines);
      expect(result.date, DateTime(2026, 7, 4));
    });

    test('handles a 2-digit year', () {
      final lines = ['Shop', '7/4/26', 'Total 5.00'];
      final result = parseReceiptText(lines);
      expect(result.date, DateTime(2026, 7, 4));
    });

    test('gracefully returns null date when nothing matches', () {
      final lines = ['Shop', 'Total 5.00'];
      final result = parseReceiptText(lines);
      expect(result.date, isNull);
    });

    test('blank/whitespace-only lines are ignored', () {
      final lines = ['', '   ', 'Cafe', 'Total 6.75'];
      final result = parseReceiptText(lines);
      expect(result.vendor, 'Cafe');
      expect(result.amount, 6.75);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:pocklume/models/category.dart';
import 'package:pocklume/models/voice_expense_result.dart';

// The actual speech recognition can't run in CI (it's an on-device call) —
// what IS pure and testable is parsing whatever transcript it returns.
// These tests pin that behavior against realistic transcript shapes.

ExpenseCategory _category(String name) => ExpenseCategory(
  id: name.toLowerCase(),
  name: name,
  emoji: '🔥',
  colorValue: 0xFF000000,
  monthlyLimit: 100,
);

void main() {
  final categories = [
    _category('Food'),
    _category('Transport'),
    _category('Fun'),
  ];

  group('parseVoiceExpense', () {
    test('extracts an amount and matches a category by name', () {
      final result = parseVoiceExpense('fifty for food', categories);
      // Speech recognizers normalize spoken numbers to digits, so "fifty"
      // arriving as "50" is the realistic shape being tested here.
      final result2 = parseVoiceExpense('50 for food', categories);
      expect(result.amount, isNull); // "fifty" (a word) has no digit to extract
      expect(result2.amount, 50.0);
      expect(result2.categoryId, 'food');
    });

    test('preserves decimal amounts', () {
      final result = parseVoiceExpense(
        '12.50 for the bus transport',
        categories,
      );
      expect(result.amount, 12.50);
      expect(result.categoryId, 'transport');
    });

    test('is case-insensitive when matching category names', () {
      final result = parseVoiceExpense('20 dollars FUN night out', categories);
      expect(result.categoryId, 'fun');
    });

    test('returns null category when no name matches', () {
      final result = parseVoiceExpense('30 dollars for rent', categories);
      expect(result.categoryId, isNull);
    });

    test('returns null amount when no number is present', () {
      final result = parseVoiceExpense('coffee with a friend', categories);
      expect(result.amount, isNull);
    });

    test('always preserves the raw transcript as the note', () {
      final result = parseVoiceExpense('15 for food at the market', categories);
      expect(result.note, '15 for food at the market');
    });

    test('takes the first number when multiple are present', () {
      final result = parseVoiceExpense(
        '5 items for 20 dollars food',
        categories,
      );
      expect(result.amount, 5.0);
    });
  });
}

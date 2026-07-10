/// Ephemeral, computed-on-demand — never persisted to Hive, unlike
/// MonthlySavingsResult/CategoryChallengeResult. It's a live comparison
/// against this month's own data, so recomputing on every Progress screen
/// build is correct, not wasteful (a stale cached version would be wrong
/// the moment a new expense is logged).
///
/// Was previously a completely inert card: the Progress screen's "Spending
/// insight" tile unlocked when a user went Pro but had no `onTap` and no
/// real content underneath the generic placeholder text — a paying
/// customer got nothing for the one Pro benefit the paywall still (validly)
/// promises. This is the actual feature the card was always meant to show.
class SpendingInsight {
  final String categoryId;
  final String categoryName;
  final String categoryEmoji;
  final double thisMonthAmount;
  final double lastMonthAmount;

  const SpendingInsight({
    required this.categoryId,
    required this.categoryName,
    required this.categoryEmoji,
    required this.thisMonthAmount,
    required this.lastMonthAmount,
  });

  /// Positive = spending more than last month, negative = less. Null when
  /// there's no last-month baseline for this category — a percentage
  /// change from zero is meaningless, not just "infinitely large."
  double? get changeFraction => lastMonthAmount > 0 ? (thisMonthAmount - lastMonthAmount) / lastMonthAmount : null;
}

/// Pure and independently unit-tested (test/spending_insight_heuristics_test.dart).
/// Finds the user's single highest-spend category this month and compares
/// it to that same category's spend last month. [categories] only needs to
/// contain categories that still exist — a category present in
/// [thisMonthSpend] but missing from [categories] (deleted since) is
/// skipped rather than shown with a blank name/emoji.
SpendingInsight? computeSpendingInsight({
  required Map<String, double> thisMonthSpend,
  required Map<String, double> lastMonthSpend,
  required List<({String id, String name, String emoji})> categories,
}) {
  String? topId;
  var topAmount = 0.0;
  for (final entry in thisMonthSpend.entries) {
    if (entry.value > topAmount) {
      topAmount = entry.value;
      topId = entry.key;
    }
  }
  if (topId == null) return null;

  ({String id, String name, String emoji})? category;
  for (final c in categories) {
    if (c.id == topId) {
      category = c;
      break;
    }
  }
  if (category == null) return null;

  return SpendingInsight(
    categoryId: category.id,
    categoryName: category.name,
    categoryEmoji: category.emoji,
    thisMonthAmount: topAmount,
    lastMonthAmount: lastMonthSpend[topId] ?? 0.0,
  );
}

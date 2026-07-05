/// Contract for the savings-buddy sync backend. Abstracted behind an
/// interface so the concrete provider (Supabase today) can be swapped
/// without touching the provider/UI, and so tests can supply a fake.
///
/// PRIVACY BOUNDARY (load-bearing for Abacus's positioning): a buddy link
/// syncs only three things per person per day — an anonymous user id, a
/// date, and a single boolean "logged something that day". No amounts, no
/// categories, no notes, nothing financial ever leaves the device. All
/// real financial data stays local-first in Hive exactly as before; this
/// backend is opt-in (only touched if you actually start a buddy streak)
/// and only active when Supabase keys are configured. See
/// docs/technical-architecture.md.
library;

abstract class BuddyBackend {
  /// True only when real backend credentials were supplied at build time.
  /// When false, the whole feature degrades to the local-only behavior
  /// (invite code stored on-device, honest "waiting to sync" copy).
  bool get isConfigured;

  /// Establishes an anonymous identity (idempotent). No-op when unconfigured.
  Future<void> init();

  /// Creates a new buddy link owned by this device and returns the share
  /// code, or null on failure.
  Future<String?> createLink();

  /// Joins an existing link by its share code. Returns true on success.
  Future<bool> joinLink(String code);

  /// Upserts today's (or any day's) "did I log" signal for the active link.
  /// Safe no-op when there's no active link or the backend is unconfigured.
  Future<void> markDay(DateTime date, {required bool logged});

  /// Fetches the current link + both parties' logged-day signals. Returns
  /// an unlinked state on any failure — network errors must never surface
  /// as crashes in a local-first app.
  Future<BuddyRemoteState> fetchState();
}

/// Raw sync snapshot from the backend — the provider derives the joint
/// streak and today's status from this (keeps the streak math pure and
/// client-side, and therefore unit-testable without a live backend).
class BuddyRemoteState {
  final bool linked;
  final String? code;
  final bool partnerJoined;
  final Set<DateTime> selfLoggedDays;
  final Set<DateTime> partnerLoggedDays;

  const BuddyRemoteState({
    required this.linked,
    this.code,
    required this.partnerJoined,
    required this.selfLoggedDays,
    required this.partnerLoggedDays,
  });

  const BuddyRemoteState.unlinked()
      : linked = false,
        code = null,
        partnerJoined = false,
        selfLoggedDays = const {},
        partnerLoggedDays = const {};
}

/// Normalizes a timestamp to a date-only value (local midnight) so set
/// membership compares by calendar day, not instant.
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// The joint streak: the count of consecutive calendar days — ending today,
/// or yesterday as a one-day grace window — on which BOTH buddies logged an
/// expense. Mirrors the individual-streak grace rule in ExpenseProvider so
/// the two feel consistent. Pure and deterministic given [today]; this is
/// the piece that's unit-tested, since live two-device sync can't be.
int computeJointStreak(
  Set<DateTime> selfLoggedDays,
  Set<DateTime> partnerLoggedDays,
  DateTime today,
) {
  final partnerDays = <DateTime>{for (final d in partnerLoggedDays) dateOnly(d)};
  final both = <DateTime>{
    for (final d in selfLoggedDays)
      if (partnerDays.contains(dateOnly(d))) dateOnly(d),
  };
  final t = dateOnly(today);
  DateTime cursor;
  if (both.contains(t)) {
    cursor = t;
  } else {
    final yesterday = t.subtract(const Duration(days: 1));
    if (both.contains(yesterday)) {
      cursor = yesterday;
    } else {
      return 0;
    }
  }
  var count = 0;
  while (both.contains(cursor)) {
    count++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return count;
}

/// Used when no backend keys are supplied (and in tests). Reports itself as
/// unconfigured so the UI keeps the local-only invite behavior it had before
/// any backend existed. Lives here (not with the Supabase impl) so tests and
/// the unconfigured build don't pull in the Supabase dependency.
class NoopBuddyBackend implements BuddyBackend {
  @override
  bool get isConfigured => false;
  @override
  Future<void> init() async {}
  @override
  Future<String?> createLink() async => null;
  @override
  Future<bool> joinLink(String code) async => false;
  @override
  Future<void> markDay(DateTime date, {required bool logged}) async {}
  @override
  Future<BuddyRemoteState> fetchState() async => const BuddyRemoteState.unlinked();
}

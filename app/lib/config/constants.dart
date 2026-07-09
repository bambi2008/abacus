class HiveBoxes {
  static const expenses = 'expenses';
  static const categories = 'categories';
  static const dailyLogCompletions = 'daily_log_completions';
  static const settings = 'settings';
  static const badges = 'badges';
  static const noSpendDays = 'no_spend_days';
  static const categoryChallengeResults = 'category_challenge_results';
  static const buddyWeeklyChallenges = 'buddy_weekly_challenges';
  static const owlState = 'owl_state';
  static const completeLogDays = 'complete_log_days';
  static const monthlySavingsResults = 'monthly_savings_results';
}

class HiveTypeIds {
  static const expense = 0;
  static const category = 1;
  static const dailyLogCompletion = 2;
  static const badge = 3;
  static const noSpendDay = 4;
  static const categoryChallengeResult = 5;
  static const owl = 6;
  static const buddyWeeklyChallenge = 7;
  static const completeLogDay = 8;
  static const monthlySavingsResult = 9;
}

/// Coarse, long-term progression tier over cumulative care score — separate
/// from the day-to-day OwlMood. See GamificationProvider.evolutionStage.
class EvolutionStages {
  static const names = ['Owlet', 'Young Owl', 'Grown Owl', 'Elder Owl'];

  /// The careScore threshold each stage index is reached AT — mirrors the
  /// cutoffs in GamificationProvider.evolutionStage, duplicated here (not
  /// derived) so the companion-owl detail sheet can show "X to next stage"
  /// without the provider needing to expose its internal thresholds.
  static const thresholds = [0, 30, 120, 365];
}

/// Flavor line shown on the full-screen celebration when the owl crosses
/// into a new evolution stage — keyed by the stage just reached. Stage 0
/// (Owlet) has no entry since there's no "reached" transition into it, it's
/// the starting stage. See OwlEvolutionCelebrationScreen.
class EvolutionCelebrationCatalog {
  static const Map<int, String> messages = {
    1: 'Steady care is starting to show.',
    2: 'Your owl is thriving under your care.',
    3: 'A wise elder now — this is what long-term care looks like.',
  };
}

/// Milestone streak days that trigger a full-screen celebration, and the
/// escalating emoji/copy for each — see MilestoneCelebrationScreen.
class MilestoneCatalog {
  static const Map<int, (String emoji, String headline, String message)> data = {
    7: ('🔥', '7-Day Streak!', 'One week of consistent logging. Keep it up.'),
    30: ('🏆', '30-Day Streak!', 'A full month. This is a habit now.'),
    100: ('💎', '100-Day Streak!', 'Triple digits. Most people never get here.'),
    365: ('👑', 'One Year Streak!', 'You logged an expense every day for a year.'),
  };

  static List<int> get milestoneDays => data.keys.toList();
}

class SettingsKeys {
  static const isPro = 'is_pro';
  static const hasOnboarded = 'has_onboarded';
  static const analyticsEnabled = 'analytics_enabled';
  static const freeStreakFreezesAvailable = 'free_streak_freezes_available';
  static const reminderHour = 'reminder_hour';
  static const reminderMinute = 'reminder_minute';
  static const buddyStreakCode = 'buddy_streak_code';
  static const buddyStreakPartnerName = 'buddy_streak_partner_name';
  static const lastMonthBoundaryCheck = 'last_month_boundary_check';
}

/// No weekly billing — see docs/customer-and-market.md for why competitors'
/// weekly mechanic is the single biggest driver of their worst reviews.
class ProductIds {
  static const monthly = 'com.abacus.pro.monthly';
  static const lifetime = 'com.abacus.pro.lifetime';
}

/// Empty key disables the feature entirely (safe default) — see
/// AnalyticsService.
class RemoteConfig {
  static const posthogApiKey = String.fromEnvironment('POSTHOG_API_KEY');
  static const posthogHost = 'https://us.i.posthog.com';
}

/// Savings-buddy sync backend. Empty values (the default) disable networking
/// entirely and the buddy feature degrades to its local-only behavior — same
/// safe-by-default pattern as [RemoteConfig]. Supply via
/// --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
/// See app/supabase/schema.sql for the one-time project setup.
class SupabaseConfig {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
}

/// Preset starter categories offered during onboarding — deliberately not
/// YNAB's "give every dollar a job" zero-based setup. See
/// docs/product-design.md.
///
/// 2026-07-06: redefined around a "beyond survival" philosophy — track
/// discretionary spending you actually have a choice about (dining out,
/// impulse buys, rideshare, subscriptions), not baseline necessities
/// (groceries you cook yourself, rent, public transit) that don't respond
/// to day-to-day willpower anyway. No "Everything Else" catch-all: if a
/// purchase doesn't fit one of these, it's very likely not the kind of
/// spending this app is trying to catch, and users can still add a custom
/// category any time via Settings if they genuinely want one.
class StarterCategories {
  /// (name, emoji, color, default monthly limit). The limit is a starting
  /// point, not a claim about what's "right" for any given category —
  /// deliberately varies by category rather than one flat number for
  /// everything (the flat $200 default used until 2026-07-06 made the boss
  /// battle mechanic meaningless: a $50/mo subscriptions habit and a
  /// $200/mo dining-out habit aren't the same kind of "limit"). Editable
  /// any time from Progress → Manage categories.
  static const presets = [
    ('Dining Out', '🍽️', 0xFFEF6C00, 150.0),
    ('Snacks & Drinks', '🍿', 0xFFFFB300, 60.0),
    ('Taxi & Rideshare', '🚕', 0xFF1E88E5, 50.0),
    ('Clothing & Shopping', '👕', 0xFF8E24AA, 100.0),
    ('Subscriptions', '📺', 0xFF43A047, 50.0),
    ('Fun & Entertainment', '🎬', 0xFFD81B60, 80.0),
  ];
}

/// Real, government-sourced monthly spending benchmarks used for the
/// monthly savings recap (see MonthlySavingsResult /
/// computeMonthlySavings) — 2024 BLS Consumer Expenditure Survey
/// (https://www.bls.gov/news.release/cesan.nr0.htm), same survey/year
/// across all three so the comparisons are methodologically consistent.
///
/// Deliberately excludes Taxi & Rideshare and Subscriptions: every
/// available estimate for those varies 3-4x across sources depending on
/// methodology (often "per active user of the service" rather than
/// "average American," or wildly different self-reported vs
/// vendor-estimated figures from SaaS-adjacent blogs with an incentive to
/// make the number look scary). A comparison claim is only as credible as
/// the data behind it — those two are tracked normally, just without a
/// "vs. average" badge, rather than built on numbers that shaky.
class NationalSpendingBenchmarks {
  /// "Food away from home," 2024: $3,945/year. Applies to the combined
  /// Dining Out + Snacks & Drinks spend since BLS doesn't split these.
  static const diningAndSnacksMonthly = 3945 / 12;

  /// "Apparel and services," 2024: $2,001/year.
  static const clothingMonthly = 2001 / 12;

  /// "Entertainment: fees and admissions," 2024: $935/year.
  static const entertainmentMonthly = 935 / 12;

  static const diningAndSnacksCategoryNames = {'Dining Out', 'Snacks & Drinks'};
  static const clothingCategoryNames = {'Clothing & Shopping'};
  static const entertainmentCategoryNames = {'Fun & Entertainment'};
}

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
class StarterCategories {
  static const presets = [
    ('Food', '🍔', 0xFFEF6C00),
    ('Transport', '🚗', 0xFF1E88E5),
    ('Fun', '🎬', 0xFF8E24AA),
    ('Everything Else', '📦', 0xFF546E7A),
  ];
}

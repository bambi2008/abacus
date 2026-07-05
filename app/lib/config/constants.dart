class HiveBoxes {
  static const expenses = 'expenses';
  static const categories = 'categories';
  static const dailyLogCompletions = 'daily_log_completions';
  static const settings = 'settings';
  static const badges = 'badges';
}

class HiveTypeIds {
  static const expense = 0;
  static const category = 1;
  static const dailyLogCompletion = 2;
  static const badge = 3;
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

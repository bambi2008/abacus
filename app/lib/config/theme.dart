import 'package:flutter/material.dart';

/// Deliberate per-concept color roles, replacing a single Material 3
/// seed color that auto-derived every surface in the app to a near-
/// identical green — a real-device design review found the three main
/// Today-screen cards (streak, owl, buddy) all read as the same muted
/// green because they shared one seed, and that the boss-battle bar's
/// green/orange/red (the one place status color was used deliberately)
/// never got promoted to a reusable app-wide convention. Modeled on
/// Duolingo's approach (a distinct hue per concept — green CTA, yellow
/// XP, red hearts, blue info) rather than one seed auto-deriving
/// everything, and on the finance-app convention of reserving green
/// specifically for "on track / achieved" rather than using it as the
/// default background tint for the whole app.
class AppColors {
  AppColors._();

  // Budget health / brand — green. Scoped specifically to "on track,
  // achieved, primary action" — not used as a generic background tint
  // anymore.
  static const budgetGood = Color(0xFF1FA971);
  static const budgetGoodContainer = Color(0xFFD3F5E6);

  // Warning — the boss-battle bar's mid-tier color, promoted from a
  // one-off `Colors.orange` to the app's shared "caution" convention.
  static const budgetWarning = Color(0xFFF5A524);
  static const budgetWarningContainer = Color(0xFFFDECC8);

  // Danger — over budget, streak at risk. Also promoted from a one-off
  // `Colors.red` to a shared convention, and now also drives the
  // streak-at-risk card instead of a green-derived errorContainer.
  static const budgetDanger = Color(0xFFE5484D);
  static const budgetDangerContainer = Color(0xFFFAD2D3);

  // Owl / personal-growth pillar — a distinct warm purple so it reads
  // as its own concept next to the streak card's green and the buddy
  // card's blue, instead of a secondaryContainer that was just another
  // green tint from the same seed.
  static const growth = Color(0xFF9B7EDE);
  static const growthContainer = Color(0xFFEAE1FA);

  // Buddy / social pillar — blue, matching the general "trust/info"
  // convention finance apps use (distinct from the budget-health green,
  // which is reserved for spend-tracking outcomes specifically).
  static const trust = Color(0xFF3B82F6);
  static const trustContainer = Color(0xFFDCE9FE);

  // Dark-mode variants — lighter/more saturated for contrast against a
  // dark surface, same three-way status meaning as the light versions.
  static const budgetGoodDark = Color(0xFF4FD8A0);
  static const budgetGoodContainerDark = Color(0xFF14513A);
  static const budgetWarningDark = Color(0xFFFFC966);
  static const budgetWarningContainerDark = Color(0xFF5C4113);
  static const budgetDangerDark = Color(0xFFFF7A7E);
  static const budgetDangerContainerDark = Color(0xFF5C1E20);
  static const growthDark = Color(0xFFC3AEF2);
  static const growthContainerDark = Color(0xFF3E2E63);
  static const trustDark = Color(0xFF8AB6FB);
  static const trustContainerDark = Color(0xFF1E3A66);
}

/// Consolidates what were previously ad hoc numeric `fontSize` values
/// scattered across a dozen files (10/14/16/18/20/24/28/40/72/96, with
/// no evident system) into a small named scale. Mostly used for emoji
/// rendered as icons (category glyphs, card hero emoji, celebration
/// art) rather than body text, which already goes through
/// `Theme.of(context).textTheme` consistently.
class AppIconSizes {
  AppIconSizes._();

  static const double micro = 10; // calendar day-number labels
  static const double tiny = 14; // inline status glyphs (boss emoji)
  static const double small = 18; // badge accents, list-row leading emoji
  static const double medium = 24; // category leading emoji
  static const double large = 40; // card hero emoji (owl, buddy, streak)
  static const double xlarge = 72; // page-level hero icon (onboarding)
  static const double hero = 96; // celebration-screen hero emoji
}

class AppTheme {
  static const seed = AppColors.budgetGood;

  // secondary/tertiary are deliberately left at Material 3's own
  // seed-derived defaults, NOT overridden to the owl (growth) / buddy
  // (trust) colors. A first pass did override them here, and it looked
  // right on the two cards those roles were meant for — but secondary/
  // tertiaryContainer are also the roles NavigationBar's selected-tab
  // indicator and ChoiceChip's selected state pull from by default, so
  // the whole app's nav bar and every chip picked up the owl card's
  // purple too. AppColors.growth/trust are applied directly on
  // CompanionOwlCard/BuddyStreakCard instead (see those files) so the
  // distinct-hue-per-concept idea stays scoped to the two cards it's
  // actually about, not leaked into unrelated Material components.
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed).copyWith(
          error: AppColors.budgetDanger,
          errorContainer: AppColors.budgetDangerContainer,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F8FA),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
        ).copyWith(
          error: AppColors.budgetDangerDark,
          errorContainer: AppColors.budgetDangerContainerDark,
        ),
      );
}

/// Day-to-day emotional state of the companion owl, driven by streak health
/// and recent challenge wins — see GamificationProvider.currentMood. Stored
/// as an int index on OwlState for Hive-friendliness (avoids needing a
/// separate enum adapter).
///
/// Unicode has only one owl glyph (no mood variants like the cat-face
/// range), so mood is conveyed through animation + label copy in
/// CompanionOwlCard rather than swapping emoji per tier.
enum OwlMood {
  sleeping, // no active streak
  hungry, // streak at risk, not logged yet today, evening
  content, // active streak, nothing special this cycle
  happy, // streak >= 30, or streak >= 7 with a recent category win
  thriving; // streak >= 100, or multiple simultaneous category wins

  String get emoji => '🦉';

  String get label {
    switch (this) {
      case OwlMood.sleeping:
        return 'Sleeping';
      case OwlMood.hungry:
        return 'Hungry';
      case OwlMood.content:
        return 'Content';
      case OwlMood.happy:
        return 'Happy';
      case OwlMood.thriving:
        return 'Thriving';
    }
  }

  String get actionableLine {
    switch (this) {
      case OwlMood.sleeping:
        return 'Log an expense to wake your owl up and start a streak.';
      case OwlMood.hungry:
        return 'Log an expense today to keep your owl happy.';
      case OwlMood.content:
        return 'Keep logging daily to make your owl even happier.';
      case OwlMood.happy:
        return 'Your owl loves the consistency — keep it up.';
      case OwlMood.thriving:
        return 'Your owl is thriving. This is what a real habit looks like.';
    }
  }
}

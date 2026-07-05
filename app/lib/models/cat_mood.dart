/// Day-to-day emotional state of the companion cat, driven by streak health
/// and recent challenge wins — see GamificationProvider.currentMood. Stored
/// as an int index on CatState for Hive-friendliness (avoids needing a
/// separate enum adapter).
enum CatMood {
  sleeping, // no active streak
  hungry, // streak at risk, not logged yet today, evening
  content, // active streak, nothing special this cycle
  happy, // streak >= 30, or streak >= 7 with a recent category win
  thriving; // streak >= 100, or multiple simultaneous category wins

  String get emoji {
    switch (this) {
      case CatMood.sleeping:
        return '😴';
      case CatMood.hungry:
        return '🙀';
      case CatMood.content:
        return '😺';
      case CatMood.happy:
        return '😸';
      case CatMood.thriving:
        return '😻';
    }
  }

  String get label {
    switch (this) {
      case CatMood.sleeping:
        return 'Sleeping';
      case CatMood.hungry:
        return 'Hungry';
      case CatMood.content:
        return 'Content';
      case CatMood.happy:
        return 'Happy';
      case CatMood.thriving:
        return 'Thriving';
    }
  }

  String get actionableLine {
    switch (this) {
      case CatMood.sleeping:
        return 'Log an expense to wake your cat up and start a streak.';
      case CatMood.hungry:
        return 'Log an expense today to keep your cat happy.';
      case CatMood.content:
        return 'Keep logging daily to make your cat even happier.';
      case CatMood.happy:
        return 'Your cat loves the consistency — keep it up.';
      case CatMood.thriving:
        return 'Your cat is thriving. This is what a real habit looks like.';
    }
  }
}

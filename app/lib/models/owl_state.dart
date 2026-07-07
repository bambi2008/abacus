import 'package:hive/hive.dart';

/// A cache of the companion owl's last-known mood/stage, used only to
/// detect genuine transitions (for the owl_evolved analytics event) — the
/// live mood/score/stage are always recomputed from real data by
/// GamificationProvider, this record is never the source of truth. Single
/// record, stored at key 'owl'.
class OwlState {
  final int moodLevel;
  final int totalCareScore;
  final DateTime lastUpdated;
  final int evolutionStage;

  /// Whether the full-screen evolution celebration for [evolutionStage] has
  /// already been shown — mirrors BadgeRecord.celebrationShown. Defaults to
  /// true (already shown) so a fresh record (the very first save, before
  /// any real transition has happened) never spuriously celebrates.
  final bool evolutionCelebrationShown;

  OwlState({
    required this.moodLevel,
    required this.totalCareScore,
    required this.lastUpdated,
    required this.evolutionStage,
    this.evolutionCelebrationShown = true,
  });

  OwlState copyWith({bool? evolutionCelebrationShown}) {
    return OwlState(
      moodLevel: moodLevel,
      totalCareScore: totalCareScore,
      lastUpdated: lastUpdated,
      evolutionStage: evolutionStage,
      evolutionCelebrationShown: evolutionCelebrationShown ?? this.evolutionCelebrationShown,
    );
  }
}

class OwlStateAdapter extends TypeAdapter<OwlState> {
  @override
  final int typeId = 6;

  @override
  OwlState read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < numFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return OwlState(
      moodLevel: fields[0] as int,
      totalCareScore: fields[1] as int,
      lastUpdated: fields[2] as DateTime,
      evolutionStage: fields[3] as int,
      // Older records predate this field — default to "already shown" so
      // upgrading doesn't spuriously celebrate a stage the user has been
      // sitting at for a while.
      evolutionCelebrationShown: fields[4] as bool? ?? true,
    );
  }

  @override
  void write(BinaryWriter writer, OwlState obj) {
    writer.writeByte(5);
    writer.writeByte(0);
    writer.write(obj.moodLevel);
    writer.writeByte(1);
    writer.write(obj.totalCareScore);
    writer.writeByte(2);
    writer.write(obj.lastUpdated);
    writer.writeByte(3);
    writer.write(obj.evolutionStage);
    writer.writeByte(4);
    writer.write(obj.evolutionCelebrationShown);
  }
}

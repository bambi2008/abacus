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

  OwlState({
    required this.moodLevel,
    required this.totalCareScore,
    required this.lastUpdated,
    required this.evolutionStage,
  });
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
    );
  }

  @override
  void write(BinaryWriter writer, OwlState obj) {
    writer.writeByte(4);
    writer.writeByte(0);
    writer.write(obj.moodLevel);
    writer.writeByte(1);
    writer.write(obj.totalCareScore);
    writer.writeByte(2);
    writer.write(obj.lastUpdated);
    writer.writeByte(3);
    writer.write(obj.evolutionStage);
  }
}

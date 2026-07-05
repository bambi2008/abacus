import 'package:hive/hive.dart';

/// One record per streak milestone ever earned (id = "streak_{day}"), so
/// earning-detection is a simple, idempotent box lookup. See
/// GamificationProvider.checkForNewMilestone and docs/technical-architecture.md.
class BadgeRecord {
  final String id;
  final int milestoneDay;
  final DateTime earnedAt;
  final bool celebrationShown;

  BadgeRecord({
    required this.id,
    required this.milestoneDay,
    required this.earnedAt,
    this.celebrationShown = false,
  });

  BadgeRecord copyWith({bool? celebrationShown}) {
    return BadgeRecord(
      id: id,
      milestoneDay: milestoneDay,
      earnedAt: earnedAt,
      celebrationShown: celebrationShown ?? this.celebrationShown,
    );
  }
}

class BadgeRecordAdapter extends TypeAdapter<BadgeRecord> {
  @override
  final int typeId = 3;

  @override
  BadgeRecord read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < numFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return BadgeRecord(
      id: fields[0] as String,
      milestoneDay: fields[1] as int,
      earnedAt: fields[2] as DateTime,
      celebrationShown: fields[3] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, BadgeRecord obj) {
    writer.writeByte(4);
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.milestoneDay);
    writer.writeByte(2);
    writer.write(obj.earnedAt);
    writer.writeByte(3);
    writer.write(obj.celebrationShown);
  }
}

import 'package:hive/hive.dart';

/// Local-only scaffold for a buddy-vs-buddy weekly mini-challenge —
/// `partnerLoggedDaysCount` stays null always in this version since there's
/// no backend to sync it (matches the existing buddy-streak invite stub's
/// honesty about needing real two-device sync later). See
/// docs/technical-architecture.md and the gamification plan.
class BuddyWeeklyChallenge {
  final String id;
  final DateTime weekStart;
  final int selfLoggedDaysCount;
  final String? partnerName;
  final int? partnerLoggedDaysCount;

  BuddyWeeklyChallenge({
    required this.id,
    required this.weekStart,
    required this.selfLoggedDaysCount,
    this.partnerName,
    this.partnerLoggedDaysCount,
  });
}

class BuddyWeeklyChallengeAdapter extends TypeAdapter<BuddyWeeklyChallenge> {
  @override
  final int typeId = 7;

  @override
  BuddyWeeklyChallenge read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < numFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return BuddyWeeklyChallenge(
      id: fields[0] as String,
      weekStart: fields[1] as DateTime,
      selfLoggedDaysCount: fields[2] as int,
      partnerName: fields[3] as String?,
      partnerLoggedDaysCount: fields[4] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, BuddyWeeklyChallenge obj) {
    writer.writeByte(5);
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.weekStart);
    writer.writeByte(2);
    writer.write(obj.selfLoggedDaysCount);
    writer.writeByte(3);
    writer.write(obj.partnerName);
    writer.writeByte(4);
    writer.write(obj.partnerLoggedDaysCount);
  }
}

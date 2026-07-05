import 'package:hive/hive.dart';

/// A deliberate, opt-in "I've logged everything I spent today" declaration
/// — the bonus-layer answer to "should the streak require 3-5 logs/day
/// instead of 1?" (2026-07-05 design discussion). Self-declared rather than
/// a fixed log-count threshold: a fixed count (e.g. "3+ expenses") would be
/// arbitrary and unfair on days where a user genuinely only spent once, and
/// there's no bank sync to verify true completeness against. Mirrors
/// NoSpendDayMark's honesty-based pattern — this doesn't gate the streak
/// (which deliberately stays a low-friction 1-log/day threshold), it only
/// feeds the owl's care score as an optional bonus for more engaged users.
/// See docs/technical-architecture.md and the gamification plan.
class CompleteLogDayMark {
  final DateTime date;
  final DateTime markedAt;

  CompleteLogDayMark({required this.date, required this.markedAt});
}

class CompleteLogDayMarkAdapter extends TypeAdapter<CompleteLogDayMark> {
  @override
  final int typeId = 8;

  @override
  CompleteLogDayMark read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < numFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return CompleteLogDayMark(
      date: fields[0] as DateTime,
      markedAt: fields[1] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CompleteLogDayMark obj) {
    writer.writeByte(2);
    writer.writeByte(0);
    writer.write(obj.date);
    writer.writeByte(1);
    writer.write(obj.markedAt);
  }
}

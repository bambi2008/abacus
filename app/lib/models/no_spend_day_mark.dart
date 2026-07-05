import 'package:hive/hive.dart';

/// A deliberate, opt-in "I chose not to spend today" win — distinct from
/// DailyLogCompletion.withinBudget (which is a cumulative month-to-date
/// signal computed only on days an expense is logged). A no-spend day is
/// most naturally true with zero expenses logged, so it can't reuse that
/// field. See docs/technical-architecture.md and the gamification plan.
class NoSpendDayMark {
  final DateTime date;
  final DateTime markedAt;

  NoSpendDayMark({required this.date, required this.markedAt});
}

class NoSpendDayMarkAdapter extends TypeAdapter<NoSpendDayMark> {
  @override
  final int typeId = 4;

  @override
  NoSpendDayMark read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < numFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return NoSpendDayMark(
      date: fields[0] as DateTime,
      markedAt: fields[1] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, NoSpendDayMark obj) {
    writer.writeByte(2);
    writer.writeByte(0);
    writer.write(obj.date);
    writer.writeByte(1);
    writer.write(obj.markedAt);
  }
}

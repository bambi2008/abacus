import 'package:hive/hive.dart';

/// One record per calendar day the user has ever logged an expense on.
/// Drives the streak calculation — see ExpenseProvider.currentStreak.
class DailyLogCompletion {
  final DateTime date;
  final bool loggedAnyExpense;
  final bool withinBudget;
  final bool usedStreakFreeze;

  DailyLogCompletion({
    required this.date,
    required this.loggedAnyExpense,
    required this.withinBudget,
    this.usedStreakFreeze = false,
  });
}

class DailyLogCompletionAdapter extends TypeAdapter<DailyLogCompletion> {
  @override
  final int typeId = 2;

  @override
  DailyLogCompletion read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < numFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return DailyLogCompletion(
      date: fields[0] as DateTime,
      loggedAnyExpense: fields[1] as bool,
      withinBudget: fields[2] as bool,
      usedStreakFreeze: fields[3] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, DailyLogCompletion obj) {
    writer.writeByte(4);
    writer.writeByte(0);
    writer.write(obj.date);
    writer.writeByte(1);
    writer.write(obj.loggedAnyExpense);
    writer.writeByte(2);
    writer.write(obj.withinBudget);
    writer.writeByte(3);
    writer.write(obj.usedStreakFreeze);
  }
}

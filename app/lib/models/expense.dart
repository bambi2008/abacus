import 'package:hive/hive.dart';

class Expense {
  final String id;
  final double amount;
  final String categoryId;
  final String note;
  final DateTime date;

  Expense({
    required this.id,
    required this.amount,
    required this.categoryId,
    required this.note,
    required this.date,
  });

  Expense copyWith({
    double? amount,
    String? categoryId,
    String? note,
    DateTime? date,
  }) {
    return Expense(
      id: id,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      note: note ?? this.note,
      date: date ?? this.date,
    );
  }
}

class ExpenseAdapter extends TypeAdapter<Expense> {
  @override
  final int typeId = 0;

  @override
  Expense read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < numFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return Expense(
      id: fields[0] as String,
      amount: (fields[1] as num).toDouble(),
      categoryId: fields[2] as String,
      note: fields[3] as String,
      date: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Expense obj) {
    writer.writeByte(5);
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.amount);
    writer.writeByte(2);
    writer.write(obj.categoryId);
    writer.writeByte(3);
    writer.write(obj.note);
    writer.writeByte(4);
    writer.write(obj.date);
  }
}

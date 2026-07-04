import 'package:hive/hive.dart';

class ExpenseCategory {
  final String id;
  final String name;
  final String emoji;
  final int colorValue;
  final double monthlyLimit;

  ExpenseCategory({
    required this.id,
    required this.name,
    required this.emoji,
    required this.colorValue,
    required this.monthlyLimit,
  });

  ExpenseCategory copyWith({String? name, String? emoji, int? colorValue, double? monthlyLimit}) {
    return ExpenseCategory(
      id: id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      colorValue: colorValue ?? this.colorValue,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
    );
  }
}

class CategoryAdapter extends TypeAdapter<ExpenseCategory> {
  @override
  final int typeId = 1;

  @override
  ExpenseCategory read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < numFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return ExpenseCategory(
      id: fields[0] as String,
      name: fields[1] as String,
      emoji: fields[2] as String,
      colorValue: fields[3] as int,
      monthlyLimit: (fields[4] as num).toDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, ExpenseCategory obj) {
    writer.writeByte(5);
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.name);
    writer.writeByte(2);
    writer.write(obj.emoji);
    writer.writeByte(3);
    writer.write(obj.colorValue);
    writer.writeByte(4);
    writer.write(obj.monthlyLimit);
  }
}

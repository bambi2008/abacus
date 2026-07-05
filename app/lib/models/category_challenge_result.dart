import 'package:hive/hive.dart';

/// One "boss battle" result per category per month, keyed by
/// "{categoryId}_{yyyy-mm}" for natural idempotency — see
/// GamificationProvider.evaluateMonthBoundaryIfNeeded.
class CategoryChallengeResult {
  final String id;
  final String categoryId;
  final int year;
  final int month;
  final double limit;
  final double actualSpend;
  final bool won;
  final DateTime evaluatedAt;
  final bool celebrationShown;

  CategoryChallengeResult({
    required this.id,
    required this.categoryId,
    required this.year,
    required this.month,
    required this.limit,
    required this.actualSpend,
    required this.won,
    required this.evaluatedAt,
    this.celebrationShown = false,
  });

  CategoryChallengeResult copyWith({bool? celebrationShown}) {
    return CategoryChallengeResult(
      id: id,
      categoryId: categoryId,
      year: year,
      month: month,
      limit: limit,
      actualSpend: actualSpend,
      won: won,
      evaluatedAt: evaluatedAt,
      celebrationShown: celebrationShown ?? this.celebrationShown,
    );
  }
}

class CategoryChallengeResultAdapter extends TypeAdapter<CategoryChallengeResult> {
  @override
  final int typeId = 5;

  @override
  CategoryChallengeResult read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < numFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return CategoryChallengeResult(
      id: fields[0] as String,
      categoryId: fields[1] as String,
      year: fields[2] as int,
      month: fields[3] as int,
      limit: (fields[4] as num).toDouble(),
      actualSpend: (fields[5] as num).toDouble(),
      won: fields[6] as bool,
      evaluatedAt: fields[7] as DateTime,
      celebrationShown: fields[8] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, CategoryChallengeResult obj) {
    writer.writeByte(9);
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.categoryId);
    writer.writeByte(2);
    writer.write(obj.year);
    writer.writeByte(3);
    writer.write(obj.month);
    writer.writeByte(4);
    writer.write(obj.limit);
    writer.writeByte(5);
    writer.write(obj.actualSpend);
    writer.writeByte(6);
    writer.write(obj.won);
    writer.writeByte(7);
    writer.write(obj.evaluatedAt);
    writer.writeByte(8);
    writer.write(obj.celebrationShown);
  }
}

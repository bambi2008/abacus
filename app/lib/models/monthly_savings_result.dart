import 'package:hive/hive.dart';

import '../config/constants.dart';

/// Persisted once per calendar month (idempotent by [id]) — mirrors
/// CategoryChallengeResult's pattern. Stores the computed total so the
/// celebration screen doesn't need to recompute historical spend after the
/// month has closed and new expenses may have been logged since.
class MonthlySavingsResult {
  final String id; // "yyyy-MM"
  final int year;
  final int month;
  final double totalSaved;
  final DateTime evaluatedAt;
  final bool celebrationShown;

  MonthlySavingsResult({
    required this.id,
    required this.year,
    required this.month,
    required this.totalSaved,
    required this.evaluatedAt,
    this.celebrationShown = false,
  });

  MonthlySavingsResult copyWith({bool? celebrationShown}) {
    return MonthlySavingsResult(
      id: id,
      year: year,
      month: month,
      totalSaved: totalSaved,
      evaluatedAt: evaluatedAt,
      celebrationShown: celebrationShown ?? this.celebrationShown,
    );
  }
}

class MonthlySavingsResultAdapter extends TypeAdapter<MonthlySavingsResult> {
  @override
  final int typeId = 9;

  @override
  MonthlySavingsResult read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < numFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return MonthlySavingsResult(
      id: fields[0] as String,
      year: fields[1] as int,
      month: fields[2] as int,
      totalSaved: fields[3] as double,
      evaluatedAt: fields[4] as DateTime,
      celebrationShown: fields[5] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, MonthlySavingsResult obj) {
    writer.writeByte(6);
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.year);
    writer.writeByte(2);
    writer.write(obj.month);
    writer.writeByte(3);
    writer.write(obj.totalSaved);
    writer.writeByte(4);
    writer.write(obj.evaluatedAt);
    writer.writeByte(5);
    writer.write(obj.celebrationShown);
  }
}

/// Pure comparison against real BLS benchmarks (see
/// NationalSpendingBenchmarks in config/constants.dart) — independently
/// unit tested since it's the credibility-bearing piece of the monthly
/// recap. [categorySpendByName] must include an entry for every category
/// the user currently tracks (spend can legitimately be 0.0), keyed by
/// name — a category that's simply *absent* from the map (deleted, never
/// added) is correctly excluded from the comparison rather than assumed to
/// be a full-benchmark "win," since Pocklume has no way to know whether the
/// user actually avoided that kind of spending or just isn't tracking it.
double computeMonthlySavings(Map<String, double> categorySpendByName) {
  double spendFor(Set<String> names) {
    var total = 0.0;
    var tracked = false;
    for (final entry in categorySpendByName.entries) {
      if (names.contains(entry.key)) {
        total += entry.value;
        tracked = true;
      }
    }
    return tracked ? total : double.nan;
  }

  double savedFor(Set<String> names, double benchmark) {
    final spend = spendFor(names);
    if (spend.isNaN) return 0; // none of these categories are tracked at all
    return (benchmark - spend).clamp(0, double.infinity);
  }

  return savedFor(
        NationalSpendingBenchmarks.diningAndSnacksCategoryNames,
        NationalSpendingBenchmarks.diningAndSnacksMonthly,
      ) +
      savedFor(
        NationalSpendingBenchmarks.clothingCategoryNames,
        NationalSpendingBenchmarks.clothingMonthly,
      ) +
      savedFor(
        NationalSpendingBenchmarks.entertainmentCategoryNames,
        NationalSpendingBenchmarks.entertainmentMonthly,
      );
}

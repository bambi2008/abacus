import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../config/constants.dart';
import '../models/category.dart';

class CategoryProvider extends ChangeNotifier {
  late Box<ExpenseCategory> _box;
  final _uuid = const Uuid();

  void load() {
    _box = Hive.box<ExpenseCategory>(HiveBoxes.categories);
  }

  List<ExpenseCategory> get all => _box.values.toList();

  ExpenseCategory? byId(String id) {
    try {
      return _box.values.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  double get totalMonthlyBudget => all.fold(0.0, (sum, c) => sum + c.monthlyLimit);

  bool get hasCategories => _box.isNotEmpty;

  /// Called once, during onboarding — seeds the categories the user picked
  /// from StarterCategories.presets. Deliberately not a zero-based setup;
  /// each starts with a modest default limit, editable later.
  Future<void> seedFromPresets(List<int> selectedIndices) async {
    for (final i in selectedIndices) {
      final (name, emoji, colorValue) = StarterCategories.presets[i];
      final category = ExpenseCategory(
        id: _uuid.v4(),
        name: name,
        emoji: emoji,
        colorValue: colorValue,
        monthlyLimit: 200.0,
      );
      await _box.put(category.id, category);
    }
    notifyListeners();
  }

  Future<void> add(String name, String emoji, int colorValue, double monthlyLimit) async {
    final category = ExpenseCategory(
      id: _uuid.v4(),
      name: name,
      emoji: emoji,
      colorValue: colorValue,
      monthlyLimit: monthlyLimit,
    );
    await _box.put(category.id, category);
    notifyListeners();
  }

  Future<void> update(ExpenseCategory category) async {
    await _box.put(category.id, category);
    notifyListeners();
  }

  Future<void> remove(String id) async {
    await _box.delete(id);
    notifyListeners();
  }
}

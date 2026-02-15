// category_list_notifier.dart
// 카테고리 목록 Riverpod Notifier
//
// [정책] createCategory 시 sort_order = 기존 개수 (맨 뒤)
// [정책] deleteCategory 시 habits.category_id → NULL (ON DELETE SET NULL)

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitcell/model/category.dart';
import 'package:habitcell/vm/habit_database_handler.dart';

/// CategoryListNotifier - 카테고리 CRUD
class CategoryListNotifier extends AsyncNotifier<List<Category>> {
  final HabitDatabaseHandler _dbHandler = HabitDatabaseHandler();

  @override
  Future<List<Category>> build() async {
    return await _dbHandler.getAllCategories();
  }

  Future<void> addCategory(Category category) async {
    await _dbHandler.insertCategory(category);
    ref.invalidateSelf();
  }

  Future<void> updateCategory(Category category) async {
    await _dbHandler.updateCategory(category);
    ref.invalidateSelf();
  }

  Future<void> deleteCategory(String id) async {
    await _dbHandler.deleteCategory(id);
    ref.invalidateSelf();
  }

  Future<void> createCategory({
    required String name,
    required int colorValue,
  }) async {
    final categories = await _dbHandler.getAllCategories();
    final sortOrder = categories.isEmpty ? 0 : categories.length;
    await _dbHandler.createCategory(
      name: name,
      colorValue: colorValue,
      sortOrder: sortOrder,
    );
    ref.invalidateSelf();
  }

  void reloadData() {
    ref.invalidateSelf();
  }
}

/// 카테고리 목록 Provider
final categoryListProvider =
    AsyncNotifierProvider<CategoryListNotifier, List<Category>>(CategoryListNotifier.new);

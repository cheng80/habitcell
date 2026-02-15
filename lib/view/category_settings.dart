// category_settings.dart
// 카테고리 관리 화면 (색상 + 이름, hivetodo TagSettings 참조)

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitcell/model/category.dart';
import 'package:habitcell/theme/app_colors.dart';
import 'package:habitcell/theme/config_ui.dart';
import 'package:habitcell/util/sheet_util.dart';
import 'package:habitcell/view/sheets/category_editor_sheet.dart';
import 'package:habitcell/view/widgets/category_tile.dart';
import 'package:habitcell/vm/category_list_notifier.dart';

/// 카테고리 관리 화면
class CategorySettings extends ConsumerWidget {
  const CategorySettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final categoriesAsync = ref.watch(categoryListProvider);

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        backgroundColor: p.background,
        iconTheme: IconThemeData(color: p.icon),
        title: Text(
          'categoryManage'.tr(),
          style: TextStyle(
            color: p.textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _showCategoryEditor(context, ref),
            icon: Icon(Icons.add, color: p.icon, size: 28),
          ),
        ],
      ),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return Center(
              child: Text(
                'categoryEmpty'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(color: p.textSecondary, fontSize: 16),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: categories.length,
            separatorBuilder: (context, index) => Divider(
              color: p.divider,
              height: 1,
              indent: ConfigUI.screenPaddingH,
              endIndent: ConfigUI.screenPaddingH,
            ),
            itemBuilder: (context, index) {
              final category = categories[index];
              return CategoryTile(
                category: category,
                onEdit: () => _showCategoryEditor(context, ref, category: category),
                onDelete: () => _confirmDelete(context, ref, category),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            '${'errorOccurred'.tr()}: $e',
            style: TextStyle(color: p.textPrimary),
          ),
        ),
      ),
    );
  }

  void _showCategoryEditor(BuildContext context, WidgetRef ref, {Category? category}) {
    final p = context.palette;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: p.sheetBackground,
      shape: defaultSheetShape,
      builder: (_) => CategoryEditorSheet(category: category),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Category category) {
    final p = context.palette;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.sheetBackground,
        title: Text('categoryDelete'.tr(), style: TextStyle(color: p.textOnSheet)),
        content: Text(
          'categoryDeleteConfirm'.tr(namedArgs: {'name': category.name}),
          style: TextStyle(color: p.iconOnSheet),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('cancel'.tr(), style: TextStyle(color: p.iconOnSheet)),
          ),
          TextButton(
            onPressed: () {
              ref.read(categoryListProvider.notifier).deleteCategory(category.id);
              Navigator.pop(ctx);
            },
            child: Text('delete'.tr(), style: TextStyle(color: p.accent)),
          ),
        ],
      ),
    );
  }
}

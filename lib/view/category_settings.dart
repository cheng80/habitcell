// category_settings.dart
// 카테고리 관리 화면 (색상 + 이름, hivetodo TagSettings 참조)

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitcell/model/category.dart';
import 'package:habitcell/model/habit_color.dart';
import 'package:habitcell/theme/app_colors.dart';
import 'package:habitcell/theme/config_ui.dart';
import 'package:habitcell/util/sheet_util.dart';
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
              return _CategoryTile(
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
      builder: (_) => _CategoryEditorSheet(category: category),
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

class _CategoryTile extends StatelessWidget {
  final Category category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryTile({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: ConfigUI.screenPaddingH,
        vertical: 4,
      ),
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: category.color,
          borderRadius: ConfigUI.tagCellRadius,
        ),
      ),
      title: Text(
        category.name,
        style: TextStyle(
          color: p.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          IconButton(
            onPressed: onEdit,
            icon: Icon(Icons.edit, color: p.textSecondary, size: 22),
          ),
          IconButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              onDelete();
            },
            icon: Icon(Icons.delete_outline, color: p.accent, size: 22),
          ),
        ],
      ),
    );
  }
}

class _CategoryEditorSheet extends ConsumerStatefulWidget {
  final Category? category;

  const _CategoryEditorSheet({this.category});

  @override
  ConsumerState<_CategoryEditorSheet> createState() => _CategoryEditorSheetState();
}

class _CategoryEditorSheetState extends ConsumerState<_CategoryEditorSheet> {
  late final TextEditingController _nameController;
  late Color _selectedColor;

  bool get _isEdit => widget.category != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _selectedColor = widget.category?.color ?? HabitColor.presets.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Padding(
      padding: EdgeInsets.only(
        left: ConfigUI.sheetPaddingH,
        right: ConfigUI.sheetPaddingH,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isEdit ? 'categoryEdit'.tr() : 'categoryAdd'.tr(),
            style: TextStyle(
              color: p.textOnSheet,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            maxLength: 10,
            style: TextStyle(color: p.textOnSheet, fontSize: 16),
            cursorColor: p.textOnSheet,
            decoration: InputDecoration(
              labelText: 'categoryName'.tr(),
              labelStyle: TextStyle(color: p.iconOnSheet),
              counterStyle: TextStyle(color: p.iconOnSheet),
              enabledBorder: OutlineInputBorder(
                borderRadius: ConfigUI.inputRadius,
                borderSide: BorderSide(color: p.iconOnSheet),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: ConfigUI.inputRadius,
                borderSide: BorderSide(
                  color: p.textOnSheet,
                  width: ConfigUI.focusBorderWidth,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'color'.tr(),
            style: TextStyle(
              color: p.iconOnSheet,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            spacing: 12,
            children: [
              Container(
                width: ConfigUI.minTouchTarget,
                height: ConfigUI.minTouchTarget,
                decoration: BoxDecoration(
                  color: _selectedColor,
                  borderRadius: ConfigUI.buttonRadius,
                  border: Border.all(
                    color: p.iconOnSheet,
                    width: ConfigUI.focusBorderWidth,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _showPresetPicker,
                icon: Icon(Icons.palette, size: 18, color: p.textOnSheet),
                label: Text('preset'.tr(), style: TextStyle(color: p.textOnSheet)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: p.iconOnSheet),
                  shape: RoundedRectangleBorder(
                    borderRadius: ConfigUI.inputRadius,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _showMaterialPicker,
                icon: Icon(Icons.color_lens, size: 18, color: p.textOnSheet),
                label: Text('allColors'.tr(), style: TextStyle(color: p.textOnSheet)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: p.iconOnSheet),
                  shape: RoundedRectangleBorder(
                    borderRadius: ConfigUI.inputRadius,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: p.textOnSheet,
                foregroundColor: p.sheetBackground,
                padding: const EdgeInsets.symmetric(vertical: 14),
                minimumSize: const Size(0, ConfigUI.minTouchTarget),
                shape: RoundedRectangleBorder(
                  borderRadius: ConfigUI.inputRadius,
                ),
              ),
              child: Text(
                _isEdit ? 'change'.tr() : 'save'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPresetPicker() {
    final p = context.palette;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.sheetBackground,
        title: Text('presetColors'.tr(), style: TextStyle(color: p.textOnSheet)),
        content: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: HabitColor.presets.map((color) {
            final isSelected = _selectedColor.value == color.value;
            return GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                setState(() => _selectedColor = color);
                Navigator.pop(ctx);
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: ConfigUI.inputRadius,
                  border: isSelected
                      ? Border.all(color: p.textOnSheet, width: 3)
                      : null,
                ),
                child: isSelected
                    ? Icon(Icons.check, color: p.sheetBackground, size: 20)
                    : null,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showMaterialPicker() {
    final p = context.palette;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.sheetBackground,
        title: Text('colorSelect'.tr(), style: TextStyle(color: p.textOnSheet)),
        content: MaterialPicker(
          pickerColor: _selectedColor,
          onColorChanged: (color) {
            HapticFeedback.mediumImpact();
            setState(() => _selectedColor = color);
          },
          enableLabel: false,
        ),
      ),
    );
  }

  void _onSave() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    HapticFeedback.mediumImpact();
    final notifier = ref.read(categoryListProvider.notifier);

    if (_isEdit) {
      final updated = widget.category!.copyWith(
        name: name,
        colorValue: _selectedColor.value,
      );
      notifier.updateCategory(updated);
    } else {
      notifier.createCategory(
        name: name,
        colorValue: _selectedColor.value,
      );
    }

    Navigator.pop(context);
  }
}

// category_tile.dart
// 카테고리 목록 타일 (편집/삭제 버튼)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:habitcell/model/category.dart';
import 'package:habitcell/theme/app_colors.dart';
import 'package:habitcell/theme/config_ui.dart';

/// 카테고리 목록 타일
class CategoryTile extends StatelessWidget {
  final Category category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CategoryTile({
    super.key,
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

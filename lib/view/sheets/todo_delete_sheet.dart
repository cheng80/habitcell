// ============================================================================
// [view/sheets/todo_delete_sheet.dart] - 삭제 옵션 BottomSheet
// ============================================================================

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:habitcell/theme/app_colors.dart';
import 'package:habitcell/theme/config_ui.dart';

class TodoDeleteSheet extends StatelessWidget {
  final VoidCallback onDeleteOne;
  final VoidCallback onDeleteChecked;
  final VoidCallback onDeleteAll;

  const TodoDeleteSheet({
    super.key,
    required this.onDeleteOne,
    required this.onDeleteChecked,
    required this.onDeleteAll,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: 178 + MediaQuery.of(context).padding.bottom,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// [이 항목 삭제] - 해당 Todo만 삭제
          _buildSheetButton(
            context: context,
            label: "deleteThisItem".tr(),
            textColor: p.textOnSheet,
            margin: const EdgeInsets.only(
              left: ConfigUI.sheetPaddingH,
              right: ConfigUI.sheetPaddingH,
              top: 12,
            ),
            onTap: () {
              HapticFeedback.mediumImpact();
              onDeleteOne();
            },
          ),

          /// [완료 항목 삭제] - 완료된 Todo만 일괄 삭제
          _buildSheetButton(
            context: context,
            label: "deleteCompleted".tr(),
            textColor: p.textOnSheet,
            margin: const EdgeInsets.symmetric(
              horizontal: ConfigUI.sheetPaddingH,
              vertical: 4,
            ),
            onTap: () {
              HapticFeedback.mediumImpact();
              onDeleteChecked();
            },
          ),

          /// [전체 삭제] - 모든 Todo 삭제 (빨간색 경고)
          _buildSheetButton(
            context: context,
            label: "deleteAll".tr(),
            textColor: p.accent,
            margin: const EdgeInsets.symmetric(
              horizontal: ConfigUI.sheetPaddingH,
              vertical: 4,
            ),
            onTap: () {
              HapticFeedback.mediumImpact();
              onDeleteAll();
            },
          ),
        ],
      ),
    );
  }
}

/// 2번 Soft UI: 시트 버튼 - 둥근 모서리 + 연한 배경으로 터치 영역 표시
Widget _buildSheetButton({
  required BuildContext context,
  required String label,
  required Color textColor,
  required EdgeInsets margin,
  required VoidCallback onTap,
}) {
  final p = context.palette;
  return GestureDetector(
    onTap: onTap,
    child: Container(
      margin: margin,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      height: ConfigUI.sheetButtonHeight,
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: p.textOnSheet.withValues(alpha: 0.08),
        borderRadius: ConfigUI.buttonRadius,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: textColor,
          fontSize: 16,
        ),
      ),
    ),
  );
}

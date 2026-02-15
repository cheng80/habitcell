// edit_sheet_header.dart
// TodoEditSheet 상단 헤더 (타이틀 + CANCEL/SAVE 버튼)

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitcell/theme/app_colors.dart';
import 'package:habitcell/theme/config_ui.dart';
import 'package:habitcell/vm/edit_sheet_notifier.dart';

/// [EditSheetHeader] - TodoEditSheet 상단 헤더
class EditSheetHeader extends ConsumerWidget {
  final bool isUpdate;
  final VoidCallback? onSave;

  const EditSheetHeader({
    super.key,
    required this.isUpdate,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final isEmpty = ref.watch(isContentEmptyProvider);
    final label = isUpdate ? "change".tr() : "save".tr();

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: ConfigUI.sheetPaddingH),
      height: 60,
      color: Colors.transparent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            isUpdate ? "updateTodo".tr() : "createTodo".tr(),
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: p.textOnSheet,
              fontSize: 18,
            ),
          ),
          Row(
            spacing: 20,
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  Navigator.of(context).pop();
                },
                child: Text(
                  "cancel".tr(),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: p.iconOnSheet,
                    fontSize: 14,
                  ),
                ),
              ),
              GestureDetector(
                onTap: isEmpty ? null : onSave,
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: isEmpty ? p.iconOnSheet : p.accent,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

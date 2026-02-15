// edit_sheet_content_field.dart
// TodoEditSheet content 입력 필드

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitcell/theme/app_colors.dart';
import 'package:habitcell/theme/config_ui.dart';
import 'package:habitcell/view/sheets/todo_edit_sheet/edit_form_field.dart';
import 'package:habitcell/vm/edit_sheet_notifier.dart';

/// [EditSheetContentField] - content 입력 필드
class EditSheetContentField extends ConsumerWidget {
  final TextEditingController controller;

  const EditSheetContentField({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final isEmpty = ref.watch(isContentEmptyProvider);

    return EditFormField(
      label: "content".tr(),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: ConfigUI.inputRadius,
          border: Border.all(
            color: p.textOnSheet,
            width: ConfigUI.focusBorderWidth,
          ),
        ),
        child: TextFormField(
          controller: controller,
          maxLength: 100,
          minLines: 3,
          maxLines: 5,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: p.textOnSheet,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            errorText: isEmpty ? 'contentRequired'.tr() : null,
            errorStyle: TextStyle(
              color: p.accent,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

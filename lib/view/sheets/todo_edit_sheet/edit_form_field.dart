// edit_form_field.dart
// TodoEditSheet 공통 폼 필드 래퍼 (레이블 + 자식 위젯)

import 'package:flutter/material.dart';
import 'package:tagdo/theme/app_colors.dart';
import 'package:tagdo/theme/config_ui.dart';

/// [EditFormField] - 레이블 + 입력 위젯 조합
class EditFormField extends StatelessWidget {
  final String label;
  final Widget child;

  const EditFormField({
    super.key,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: ConfigUI.sheetPaddingH),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 16, bottom: 8),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: p.iconOnSheet,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

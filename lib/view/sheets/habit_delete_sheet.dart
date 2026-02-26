// habit_delete_sheet.dart
// HabitDeleteSheet - 습관 삭제 확인 BottomSheet

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:habitcell/theme/app_theme_colors.dart';
import 'package:habitcell/util/config_ui.dart';
import 'package:habitcell/util/sheet_util.dart';

/// HabitDeleteSheet - 습관 삭제 확인
class HabitDeleteSheet extends StatelessWidget {
  final String habitTitle;
  final VoidCallback onDelete;

  const HabitDeleteSheet({
    super.key,
    required this.habitTitle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.appTheme;
    final tablet = isTablet(context);

    return Container(
      padding: EdgeInsets.all(tablet ? 32 : ConfigUI.sheetPaddingH),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'habitDelete'.tr(),
            style: TextStyle(
              color: p.textPrimary,
              fontSize: ConfigUI.fontSizeTitle,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'habitDeleteMessage'.tr(namedArgs: {'name': habitTitle}),
            style: TextStyle(color: p.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            spacing: 12,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('cancel'.tr()),
              ),
              FilledButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  onDelete();
                  Navigator.of(context).pop();
                },
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: Text('delete'.tr()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

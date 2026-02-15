// edit_sheet_due_date_field.dart
// TodoEditSheet 마감일 선택 필드 (DatePicker + TimePicker)

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tagdo/theme/app_colors.dart';
import 'package:tagdo/theme/config_ui.dart';
import 'package:tagdo/view/sheets/todo_edit_sheet/edit_form_field.dart';
import 'package:tagdo/vm/edit_sheet_notifier.dart';

/// [EditSheetDueDateField] - 마감일 선택 (탭 시 DatePicker + TimePicker)
class EditSheetDueDateField extends ConsumerWidget {
  final Future<void> Function() onPickDate;

  const EditSheetDueDateField({
    super.key,
    required this.onPickDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final dueDate = ref.watch(editDueDateProvider);

    return EditFormField(
      label: "dueDate".tr(),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: ConfigUI.inputRadius,
          border: Border.all(
            color: p.textOnSheet,
            width: ConfigUI.focusBorderWidth,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPickDate,
            borderRadius: ConfigUI.inputRadius,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 20,
                    color: p.iconOnSheet,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      dueDate != null ? _formatDueDate(context, dueDate) : "notSet".tr(),
                      style: TextStyle(
                        color: dueDate != null
                            ? p.textOnSheet
                            : p.iconOnSheet,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  if (dueDate != null)
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        ref.read(editDueDateProvider.notifier).clear();
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.close,
                          size: 18,
                          color: p.iconOnSheet,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _formatDueDate(BuildContext context, DateTime d) {
    final localeStr = _localeToString(context.locale);
    final format = DateFormat.yMMMd(localeStr).add_jm();
    return format.format(d);
  }

  static String _localeToString(Locale locale) {
    if (locale.countryCode != null) {
      final s = '${locale.languageCode}_${locale.countryCode}';
      if (s == 'zh_CN' || s == 'zh_TW') return s;
      if (locale.languageCode == 'ko') return 'ko_KR';
      if (locale.languageCode == 'en') return 'en_US';
      if (locale.languageCode == 'ja') return 'ja_JP';
      return s;
    }
    return locale.languageCode == 'ko'
        ? 'ko_KR'
        : locale.languageCode == 'ja'
            ? 'ja_JP'
            : locale.languageCode;
  }
}

// language_picker_sheet.dart
// 다국어 선택 바텀시트

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:habitcell/theme/app_colors.dart';
import 'package:habitcell/util/sheet_util.dart';

/// 다국어 선택 바텀시트 표시
void showLanguagePickerSheet(BuildContext context) {
  final p = context.palette;
  showModalBottomSheet(
    context: context,
    backgroundColor: p.sheetBackground,
    shape: defaultSheetShape,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LangTile(locale: const Locale('ko'), label: 'langKo'.tr()),
          _LangTile(locale: const Locale('en'), label: 'langEn'.tr()),
          _LangTile(locale: const Locale('ja'), label: 'langJa'.tr()),
          _LangTile(
            locale: const Locale('zh', 'CN'),
            label: 'langZhCN'.tr(),
          ),
          _LangTile(
            locale: const Locale('zh', 'TW'),
            label: 'langZhTW'.tr(),
          ),
        ],
      ),
    ),
  );
}

class _LangTile extends StatelessWidget {
  final Locale locale;
  final String label;

  const _LangTile({
    required this.locale,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isSelected = context.locale == locale;
    return ListTile(
      leading: Icon(
        isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
        color: isSelected ? p.accent : p.icon,
      ),
      title: Text(label, style: TextStyle(color: p.textOnSheet)),
      onTap: () {
        context.setLocale(locale);
        Navigator.pop(context);
      },
    );
  }
}

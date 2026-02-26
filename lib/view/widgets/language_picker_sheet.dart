// language_picker_sheet.dart
// 다국어 선택 바텀시트

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:habitcell/theme/app_theme_colors.dart';
import 'package:habitcell/util/config_ui.dart';
import 'package:habitcell/util/sheet_util.dart';

/// 다국어 선택 바텀시트 표시
void showLanguagePickerSheet(BuildContext context) {
  final p = context.appTheme;
  final rootContext = Navigator.of(context, rootNavigator: true).context;
  showModalBottomSheet(
    context: rootContext,
    useRootNavigator: true,
    backgroundColor: p.sheetBackground,
    shape: defaultSheetShape,
    constraints: sheetConstraints(rootContext, minHeightRatio: 0.3),
    builder: (ctx) {
      final tablet = isTablet(ctx);
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: tablet ? 24 : ConfigUI.paddingCard,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: tablet ? 32 : ConfigUI.sheetPaddingH,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'language'.tr(),
                    style: TextStyle(
                      color: p.textPrimary,
                      fontSize: tablet
                          ? ConfigUI.fontSizeTitle
                          : ConfigUI.fontSizeSubtitle,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: tablet ? 16 : 8),
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
    },
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
    final p = context.appTheme;
    final tablet = isTablet(context);
    final isSelected = context.locale == locale;
    return ListTile(
      contentPadding: EdgeInsets.symmetric(
        horizontal: tablet ? 32 : 16,
        vertical: tablet ? 4 : 0,
      ),
      leading: Icon(
        isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
        color: isSelected ? p.accent : p.icon,
        size: tablet ? 28 : 24,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: p.textOnSheet,
          fontSize: tablet ? ConfigUI.fontSizeBody : null,
        ),
      ),
      onTap: () {
        context.setLocale(locale);
        Navigator.pop(context);
      },
    );
  }
}

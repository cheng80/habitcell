// app_drawer.dart
// 앱 사이드 메뉴 (설정)

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitcell/service/in_app_review_service.dart';
import 'package:habitcell/theme/app_colors.dart';
import 'package:habitcell/util/common_util.dart';
import 'package:habitcell/theme/config_ui.dart';
import 'package:habitcell/util/sheet_util.dart';
import 'package:habitcell/vm/theme_notifier.dart';
import 'package:habitcell/vm/wakelock_notifier.dart';
import 'package:habitcell/view/category_settings.dart';
import 'package:habitcell/vm/pre_reminder_notifier.dart';

/// AppDrawer - 설정 및 부가 기능
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final themeMode = ref.watch(themeNotifierProvider);
    final isDark =
        themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    return Drawer(
      backgroundColor: p.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                ConfigUI.screenPaddingH, 24, ConfigUI.screenPaddingH, 16,
              ),
              child: Row(
                spacing: 12,
                children: [
                  Icon(Icons.settings, color: p.icon, size: 28),
                  Text(
                    'settings'.tr(),
                    style: TextStyle(
                      color: p.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: p.divider, height: 1),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: ConfigUI.screenPaddingH,
                vertical: 4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'darkMode'.tr(),
                    style: TextStyle(color: p.textPrimary, fontSize: 16),
                  ),
                  Switch(
                    value: isDark,
                    activeThumbColor: p.chipSelectedBg,
                    activeTrackColor: p.chipUnselectedBg,
                    inactiveThumbColor: p.textMeta,
                    inactiveTrackColor: p.chipUnselectedBg,
                    onChanged: (_) {
                      HapticFeedback.mediumImpact();
                      ref.read(themeNotifierProvider.notifier).toggleTheme();
                    },
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: ConfigUI.screenPaddingH,
                vertical: 4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'screenWakeLock'.tr(),
                    style: TextStyle(color: p.textPrimary, fontSize: 16),
                  ),
                  Switch(
                    value: ref.watch(wakelockNotifierProvider),
                    activeThumbColor: p.chipSelectedBg,
                    activeTrackColor: p.chipUnselectedBg,
                    inactiveThumbColor: p.textMeta,
                    inactiveTrackColor: p.chipUnselectedBg,
                    onChanged: (_) {
                      HapticFeedback.mediumImpact();
                      ref.read(wakelockNotifierProvider.notifier).toggle();
                    },
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: ConfigUI.screenPaddingH,
                vertical: 4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'preReminder'.tr(),
                    style: TextStyle(color: p.textPrimary, fontSize: 16),
                  ),
                  Switch(
                    value: ref.watch(preReminderNotifierProvider),
                    activeThumbColor: p.chipSelectedBg,
                    activeTrackColor: p.chipUnselectedBg,
                    inactiveThumbColor: p.textMeta,
                    inactiveTrackColor: p.chipUnselectedBg,
                    onChanged: (_) {
                      HapticFeedback.mediumImpact();
                      ref.read(preReminderNotifierProvider.notifier).toggle();
                    },
                  ),
                ],
              ),
            ),

            Divider(color: p.divider, height: 1),

            ListTile(
              leading: Icon(Icons.language, color: p.icon),
              title: Text(
                'language'.tr(),
                style: TextStyle(color: p.textPrimary, fontSize: 16),
              ),
              trailing: Icon(Icons.chevron_right, color: p.textSecondary),
              onTap: () {
                Navigator.pop(context);
                _showLanguagePicker(context);
              },
            ),

            ListTile(
              leading: Icon(Icons.star_outline, color: p.icon),
              title: Text(
                'rateApp'.tr(),
                style: TextStyle(color: p.textPrimary, fontSize: 16),
              ),
              trailing: Icon(Icons.open_in_new, color: p.textSecondary, size: 20),
              onTap: () async {
                Navigator.pop(context);
                final ok = await InAppReviewService().openStoreListing();
                if (context.mounted && !ok) {
                  showCommonSnackBar(
                    context,
                    message: '평점 기능은 앱 출시 후 이용 가능합니다.',
                  );
                }
              },
            ),

            ListTile(
              leading: Icon(Icons.category_outlined, color: p.icon),
              title: Text(
                'categoryManage'.tr(),
                style: TextStyle(color: p.textPrimary, fontSize: 16),
              ),
              trailing: Icon(Icons.chevron_right, color: p.textSecondary),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CategorySettings()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

void _showLanguagePicker(BuildContext context) {
  final p = context.palette;
  showModalBottomSheet(
    context: context,
    backgroundColor: p.sheetBackground,
    shape: defaultSheetShape,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _langTile(ctx, const Locale('ko'), 'langKo'.tr()),
          _langTile(ctx, const Locale('en'), 'langEn'.tr()),
          _langTile(ctx, const Locale('ja'), 'langJa'.tr()),
          _langTile(ctx, const Locale('zh', 'CN'), 'langZhCN'.tr()),
          _langTile(ctx, const Locale('zh', 'TW'), 'langZhTW'.tr()),
        ],
      ),
    ),
  );
}

Widget _langTile(BuildContext context, Locale locale, String label) {
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


// app_drawer.dart
// 앱 사이드 메뉴 (설정)
//
// [구성] 테마, 다국어, 화면꺼짐, 미리 알림, 잔디 테마, 카테고리, 평점, (개발) 더미/삭제/알람상태
// [정책] 스낵바: showOverlaySnackBar 사용 (드로어 위에 표시, rootNavigatorKey 오버레이)
// [정책] 더미 삽입/전체 삭제 시 heatmapDataProvider, habitStatsProvider 무효화

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitcell/service/in_app_review_service.dart';
import 'package:habitcell/theme/app_theme_colors.dart';
import 'package:habitcell/util/common_util.dart';
import 'package:habitcell/util/config_ui.dart';
import 'package:habitcell/vm/habit_list_notifier.dart';
import 'package:habitcell/vm/heatmap_data_provider.dart';
import 'package:habitcell/vm/habit_stats_provider.dart';
import 'package:habitcell/vm/heatmap_theme_notifier.dart';
import 'package:habitcell/vm/theme_notifier.dart';
import 'package:habitcell/vm/wakelock_notifier.dart';
import 'package:habitcell/util/app_storage.dart';
import 'package:habitcell/view/backup_settings.dart';
import 'package:habitcell/view/category_settings.dart';
import 'package:habitcell/view/widgets/heatmap_theme_picker_sheet.dart';
import 'package:habitcell/view/widgets/language_picker_sheet.dart';
import 'package:habitcell/vm/pre_reminder_notifier.dart';
import 'package:habitcell/service/notification_service.dart' show NotificationService;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:showcaseview/showcaseview.dart';

/// AppDrawer - 설정 및 부가 기능
class AppDrawer extends ConsumerStatefulWidget {
  const AppDrawer({super.key, this.onReplayTutorial, this.menuShowcaseKey});

  final VoidCallback? onReplayTutorial;
  final GlobalKey? menuShowcaseKey;

  @override
  ConsumerState<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends ConsumerState<AppDrawer> {
  bool _showDevButtons = false;

  Future<void> _onInsertDummyData(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(habitListProvider.notifier);
    final navigator = Navigator.of(context);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('dummyDataInsert'.tr()),
        content: Text('dummyDataInsertMessage'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('confirm'.tr()),
          ),
        ],
      ),
    );
    if (!context.mounted || ok != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(ConfigUI.paddingEmptyState),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('dummyDataInserting'.tr()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    try {
      await notifier.insertDummyData();
      ref.invalidate(heatmapDataProvider);
      ref.invalidate(habitStatsProvider);
      if (navigator.mounted) {
        navigator.pop(); // loading dialog
        navigator.pop(); // drawer
      }
      final ctx = rootNavigatorKey.currentContext ?? context;
      if (ctx.mounted) {
        showOverlaySnackBar(ctx, message: 'dummyDataInserted'.tr());
      }
    } catch (e, st) {
      debugPrint('[AppDrawer] insertDummyData error: $e\n$st');
      if (navigator.mounted) {
        navigator.pop(); // loading dialog
        navigator.pop(); // drawer
      }
      final ctx = rootNavigatorKey.currentContext ?? context;
      if (ctx.mounted) {
        showOverlaySnackBar(ctx, message: '${'errorOccurred'.tr()}: $e');
      }
    }
  }

  Future<void> _onAlarmStatusCheck(BuildContext context, WidgetRef ref) async {
    final habitsAsync = ref.read(habitListProvider);
    final habits = habitsAsync.value ?? [];
    final notiService = NotificationService();

    final lines = <String>['=== 등록된 알람 ==='];
    var habitAlarmCount = 0;
    for (final item in habits) {
      final h = item.habit;
      if (h.deadlineReminderTime != null) {
        habitAlarmCount++;
        lines.add('- ${h.title}: 마감 ${h.deadlineReminderTime}');
      }
    }
    if (habitAlarmCount == 0) {
      lines.add('[습관 알람] 없음');
    } else {
      lines.insert(1, '[습관 알람 $habitAlarmCount개]');
    }

    final pending = await notiService.getPendingNotifications();
    lines.add('');
    lines.add('[예약된 푸시 ${pending.length}개]');
    for (final p in pending) {
      String? dueStr;
      if (p.payload != null && p.payload!.isNotEmpty) {
        try {
          final dt = DateTime.parse(p.payload!);
          dueStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
        } catch (_) {}
      }
      lines.add('- ID ${p.id}: ${p.title ?? ''}${dueStr != null ? ' @ $dueStr' : ''}');
    }
    if (pending.isEmpty) {
      lines.add('없음');
    }

    final fullText = lines.join('\n');
    debugPrint(fullText);

    final summary = habitAlarmCount > 0 || pending.isNotEmpty
        ? '습관 알람 $habitAlarmCount개, 예약 푸시 ${pending.length}개 (콘솔에 상세 출력)'
        : '등록된 알람 없음';
    showOverlaySnackBar(
      context,
      message: summary,
      duration: const Duration(seconds: 3),
    );
  }

  Future<void> _onDeleteAllData(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(habitListProvider.notifier);
    final navigator = Navigator.of(context);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('deleteAllData'.tr()),
        content: Text('deleteAllDataMessage'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('delete'.tr()),
          ),
        ],
      ),
    );
    if (!context.mounted || ok != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(ConfigUI.paddingEmptyState),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('deleteAllDataDeleting'.tr()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    try {
      await notifier.deleteAllHabitsAndLogs();
      await NotificationService().cancelAllNotifications();
      ref.invalidate(heatmapDataProvider);
      ref.invalidate(habitStatsProvider);
      if (navigator.mounted) {
        navigator.pop(); // loading dialog
        navigator.pop(); // drawer
      }
      final ctx = rootNavigatorKey.currentContext ?? context;
      if (ctx.mounted) {
        showOverlaySnackBar(ctx, message: 'deleteAllDataDone'.tr());
      }
    } catch (e, st) {
      debugPrint('[AppDrawer] deleteAllData error: $e\n$st');
      if (navigator.mounted) {
        navigator.pop(); // loading dialog
        navigator.pop(); // drawer
      }
      final ctx = rootNavigatorKey.currentContext ?? context;
      if (ctx.mounted) {
        showOverlaySnackBar(ctx, message: '${'errorOccurred'.tr()}: $e');
      }
    }
  }

  Widget _buildMenuHeader(AppThemeColorsHelper p) {
    final content = Padding(
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
    );
    final key = widget.menuShowcaseKey;
    if (key != null) {
      return Showcase(
        key: key,
        description: 'tutorial_step_5'.tr(),
        tooltipBackgroundColor: p.sheetBackground,
        textColor: p.textOnSheet,
        tooltipBorderRadius: ConfigUI.cardRadius,
        disableDefaultTargetGestures: true,
        child: content,
      );
    }
    return content;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.appTheme;
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
            GestureDetector(
              onLongPress: () {
                HapticFeedback.mediumImpact();
                setState(() => _showDevButtons = !_showDevButtons);
              },
              child: _buildMenuHeader(p),
            ),
            Divider(color: p.divider, height: 1),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
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
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'preReminderHint'.tr(),
                            style: TextStyle(
                              color: p.textMeta,
                              fontSize: 12,
                            ),
                          ),
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
                      showLanguagePickerSheet(context);
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
                  if (widget.onReplayTutorial != null)
                    ListTile(
                      leading: Icon(Icons.school_outlined, color: p.icon),
                      title: Text(
                        'tutorial_replay'.tr(),
                        style: TextStyle(color: p.textPrimary, fontSize: 16),
                      ),
                      trailing: Icon(Icons.chevron_right, color: p.textSecondary),
                      onTap: () {
                        Navigator.pop(context);
                        AppStorage.resetTutorialCompleted();
                        widget.onReplayTutorial!();
                      },
                    ),
                  ListTile(
                    leading: Icon(Icons.grid_on_outlined, color: p.icon),
                    title: Text(
                      'heatmapTheme'.tr(),
                      style: TextStyle(color: p.textPrimary, fontSize: 16),
                    ),
                    trailing: Icon(Icons.chevron_right, color: p.textSecondary),
                    onTap: () {
                      final notifier = ref.read(heatmapThemeNotifierProvider.notifier);
                      final current = ref.read(heatmapThemeNotifierProvider);
                      Navigator.pop(context);
                      showHeatmapThemePickerSheet(context, notifier, current);
                    },
                  ),
                  Divider(color: p.divider, height: 1),
                  ListTile(
                    leading: Icon(Icons.cloud_outlined, color: p.icon),
                    title: Text(
                      'backupAndRestore'.tr(),
                      style: TextStyle(color: p.textPrimary, fontSize: 16),
                    ),
                    trailing: Icon(Icons.chevron_right, color: p.textSecondary),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BackupSettings()),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.alarm_outlined, color: p.icon),
                    title: Text(
                      'alarmStatusCheck'.tr(),
                      style: TextStyle(color: p.textPrimary, fontSize: 16),
                    ),
                    trailing: Icon(Icons.info_outline, color: p.textSecondary, size: 20),
                    onTap: () => _onAlarmStatusCheck(context, ref),
                  ),
                  if (_showDevButtons) ...[
                    Divider(color: p.divider, height: 1),
                    ListTile(
                      leading: Icon(Icons.data_object, color: p.icon),
                      title: Text(
                        'dummyDataInsert'.tr(),
                        style: TextStyle(color: p.textPrimary, fontSize: 16),
                      ),
                      onTap: () => _onInsertDummyData(context, ref),
                    ),
                    ListTile(
                      leading: Icon(Icons.delete_sweep, color: p.icon),
                      title: Text(
                        'deleteAllData'.tr(),
                        style: TextStyle(color: p.textPrimary, fontSize: 16),
                      ),
                      onTap: () => _onDeleteAllData(context, ref),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                ConfigUI.screenPaddingH, 12, ConfigUI.screenPaddingH, 16,
              ),
              child: FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                  final v = snapshot.data;
                  final text = v != null
                      ? '${'appVersion'.tr()} ${v.version}+${v.buildNumber}'
                      : 'appVersion'.tr();
                  return Text(
                    text,
                    style: TextStyle(
                      color: p.textMeta,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}


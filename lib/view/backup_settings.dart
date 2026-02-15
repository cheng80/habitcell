// backup_settings.dart
// 백업/복구 전용 설정 화면 (Drawer에서 분리)

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitcell/service/backup_service.dart';
import 'package:habitcell/service/notification_service.dart'
    show DeadlineReminderItem, NotificationService;
import 'package:habitcell/theme/app_colors.dart';
import 'package:habitcell/theme/config_ui.dart';
import 'package:habitcell/util/app_storage.dart';
import 'package:habitcell/util/common_util.dart';
import 'package:habitcell/view/widgets/email_registration_card.dart';
import 'package:habitcell/view/widgets/restore_option_card.dart';
import 'package:habitcell/view/widgets/server_backup_status_card.dart';
import 'package:habitcell/vm/habit_database_handler.dart';
import 'package:habitcell/vm/habit_list_notifier.dart';
import 'package:habitcell/vm/heatmap_data_provider.dart';
import 'package:habitcell/vm/habit_stats_provider.dart';
import 'package:intl/intl.dart';

/// 백업 설정 화면 (자동 백업, 지금 백업, 복구)
class BackupSettings extends ConsumerStatefulWidget {
  const BackupSettings({super.key});

  @override
  ConsumerState<BackupSettings> createState() => _BackupSettingsState();
}

class _BackupSettingsState extends ConsumerState<BackupSettings> {
  RecoveryStatus? _recoveryStatus;
  bool _isLoadingStatus = true;

  @override
  void initState() {
    super.initState();
    _loadRecoveryStatus();
  }

  Future<void> _loadRecoveryStatus() async {
    setState(() => _isLoadingStatus = true);
    final status = await BackupService().fetchRecoveryStatus();
    if (mounted) {
      setState(() {
        _recoveryStatus = status;
        _isLoadingStatus = false;
      });
    }
  }

  // ─── 포맷 유틸 ────────────────────────────────────────────────
  String _formatLastBackup(String? iso) {
    if (iso == null || iso.isEmpty) return 'lastBackupNever'.tr();
    try {
      final dt = DateTime.parse(iso);
      return '${'lastBackup'.tr()} ${DateFormat('yyyy-MM-dd HH:mm').format(dt)}';
    } catch (_) {
      return 'lastBackupNever'.tr();
    }
  }

  // ─── 다이얼로그: 자동 백업 안내 ──────────────────────────────
  Future<void> _showAutoBackupNoticeDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('autoBackup'.tr()),
        content: Text('autoBackupNotice'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('confirm'.tr()),
          ),
        ],
      ),
    );
  }

  // ─── 다이얼로그: 쿨다운 설정 ─────────────────────────────────
  Future<void> _showCooldownDialog(BuildContext context) async {
    final current = AppStorage.getCooldownMinutes();
    final choice = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('backupCooldown'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('backupCooldownHint'.tr(),
                style: TextStyle(
                    color: context.palette.textMeta, fontSize: 12)),
            const SizedBox(height: 8),
            ...([1, 5, 10].map((m) => ListTile(
                  dense: true,
                  title: Text('$m min'),
                  trailing: current == m
                      ? Icon(Icons.check,
                          color: context.palette.primary, size: 20)
                      : null,
                  onTap: () => Navigator.pop(ctx, m),
                ))),
          ],
        ),
      ),
    );
    if (choice != null) {
      await AppStorage.setCooldownMinutes(choice);
      if (mounted) {
        setState(() {});
        showOverlaySnackBar(context,
            message: '${'backupCooldown'.tr()}: $choice min');
      }
    }
  }

  // ─── 쿨다운 초기화 ───────────────────────────────────────────
  Future<void> _onClearBackupAttempt(BuildContext context) async {
    await AppStorage.clearLastBackupAttemptAt();
    if (mounted) {
      setState(() {});
      showOverlaySnackBar(context, message: 'clearBackupAttempt'.tr());
    }
  }

  // ─── 지금 백업 ────────────────────────────────────────────────
  Future<void> _onBackupNow(BuildContext context) async {
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
                  Text('backupInProgress'.tr()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    final result = await BackupService().backup(trigger: 'manual');
    if (!mounted) return;
    Navigator.pop(context);
    final ctx = rootNavigatorKey.currentContext ?? context;
    if (ctx != null && ctx.mounted) {
      if (result.success) {
        setState(() {});
        showOverlaySnackBar(ctx, message: 'backupSuccess'.tr());
      } else {
        showOverlaySnackBar(
          ctx,
          message: '${'backupFail'.tr()}: ${result.errorMessage}',
        );
      }
    }
  }

  // ─── 복구 ─────────────────────────────────────────────────────
  Future<void> _onRestore(BuildContext context, WidgetRef ref) async {
    debugPrint('[BackupSettings] _onRestore: 복구 시작');
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
                  Text('restoreFetching'.tr()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    final fetchResult = await BackupService().fetchLatestBackup();
    if (!mounted) return;
    Navigator.pop(context);

    if (fetchResult.payload == null) {
      debugPrint('[BackupSettings] _onRestore: 백업 없음 (404/403 또는 오류)');
      final ctx = rootNavigatorKey.currentContext ?? context;
      if (ctx != null && ctx.mounted) {
        final msg = fetchResult.errorHint == 'email_required'
            ? 'restoreEmailRequired'.tr()
            : 'restoreNotFound'.tr();
        showOverlaySnackBar(ctx, message: msg);
      }
      return;
    }

    final payload = fetchResult.payload!;
    debugPrint('[BackupSettings] _onRestore: 백업 발견, 확인 대화상자 표시');
    final p = context.palette;
    final choice = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('restore'.tr()),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'restoreConfirm'.tr(),
                style: TextStyle(color: p.textPrimary, fontSize: 14),
              ),
              const SizedBox(height: 16),
              RestoreOptionCard(
                icon: Icons.save_outlined,
                title: 'restoreOptionBackupFirst'.tr(),
                subtitle: 'restoreOptionBackupFirstHint'.tr(),
                onTap: () => Navigator.pop(ctx, 1),
                palette: p,
              ),
              const SizedBox(height: 8),
              RestoreOptionCard(
                icon: Icons.cloud_download_outlined,
                title: 'restoreOptionDirect'.tr(),
                onTap: () => Navigator.pop(ctx, 2),
                palette: p,
              ),
              const SizedBox(height: 8),
              RestoreOptionCard(
                icon: Icons.close,
                title: 'cancel'.tr(),
                onTap: () => Navigator.pop(ctx, 3),
                palette: p,
                isCancel: true,
              ),
            ],
          ),
        ),
      ),
    );

    if (choice == null || choice == 3) {
      debugPrint('[BackupSettings] _onRestore: 사용자 취소');
      return;
    }

    if (choice == 1) {
      debugPrint('[BackupSettings] _onRestore: 현재 상태 백업 후 복구 선택');
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
                    Text('backupInProgress'.tr()),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      final backupResult =
          await BackupService().backup(trigger: 'restore_pre');
      if (!mounted) return;
      Navigator.pop(context);

      if (!backupResult.success) {
        final continueRestore = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('restoreBackupFailed'.tr()),
            content: Text('restoreBackupFailedContinue'.tr()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('cancel'.tr()),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('restore'.tr()),
              ),
            ],
          ),
        );
        if (!mounted) return;
        if (continueRestore != true) {
          debugPrint('[BackupSettings] _onRestore: 백업 실패 후 사용자 취소');
          return;
        }
      }
    } else {
      debugPrint('[BackupSettings] _onRestore: 바로 복구 선택');
    }

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
                  Text('restoreInProgress'.tr()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    debugPrint('[BackupSettings] _onRestore: restore() 호출 중...');
    final result = await BackupService().restore(payload);
    if (!mounted) return;
    Navigator.pop(context);

    debugPrint(
        '[BackupSettings] _onRestore: 결과 success=${result.success}');
    final ctx = rootNavigatorKey.currentContext ?? context;
    if (ctx != null && ctx.mounted) {
      if (result.success) {
        ref.invalidate(habitListProvider);
        ref.invalidate(heatmapDataProvider);
        ref.invalidate(habitStatsProvider);
        _scheduleDeadlineRemindersAfterRestore();
        showOverlaySnackBar(ctx, message: 'restoreSuccess'.tr());
      } else {
        showOverlaySnackBar(
          ctx,
          message: '${'restoreFail'.tr()}: ${result.errorMessage}',
        );
      }
    }
  }

  Future<void> _scheduleDeadlineRemindersAfterRestore() async {
    try {
      final list = await HabitDatabaseHandler().getHabitsWithTodayCount();
      final items = list
          .map((h) => DeadlineReminderItem(
                h.habit.id,
                h.habit.title,
                h.habit.deadlineReminderTime,
                h.isCompleted,
              ))
          .toList();
      await NotificationService().scheduleDeadlineReminders(items);
    } catch (_) {}
  }

  // ─── 위젯 빌더: 백업 액션 섹션 ────────────────────────────────
  List<Widget> _buildBackupActionSection(
      BuildContext context, WidgetRef ref, AppColorScheme p) {
    return [
      Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ConfigUI.screenPaddingH,
          vertical: 4,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'autoBackup'.tr(),
                  style: TextStyle(color: p.textPrimary, fontSize: 16),
                ),
                IconButton(
                  icon: Icon(Icons.info_outline,
                      color: p.textSecondary, size: 20),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () => _showAutoBackupNoticeDialog(context),
                ),
              ],
            ),
            Switch(
              value: AppStorage.getAutoBackupEnabled(),
              activeThumbColor: p.chipSelectedBg,
              activeTrackColor: p.chipUnselectedBg,
              inactiveThumbColor: p.textMeta,
              inactiveTrackColor: p.chipUnselectedBg,
              onChanged: (v) async {
                HapticFeedback.mediumImpact();
                AppStorage.setAutoBackupEnabled(v);
                if (v && !AppStorage.getAutoBackupAnnounced()) {
                  AppStorage.setAutoBackupAnnounced(true);
                  if (mounted) await _showAutoBackupNoticeDialog(context);
                }
                if (mounted) setState(() {});
              },
            ),
          ],
        ),
      ),
      ListTile(
        leading: Icon(Icons.cloud_upload_outlined, color: p.icon),
        title: Text(
          'backupNow'.tr(),
          style: TextStyle(color: p.textPrimary, fontSize: 16),
        ),
        subtitle: Text(
          _formatLastBackup(AppStorage.getLastBackupAt()),
          style: TextStyle(color: p.textMeta, fontSize: 12),
        ),
        onTap: () => _onBackupNow(context),
      ),
      ListTile(
        leading: Icon(Icons.cloud_download_outlined, color: p.icon),
        title: Text(
          'restore'.tr(),
          style: TextStyle(color: p.textPrimary, fontSize: 16),
        ),
        subtitle: Text(
          'restoreSameDeviceHint'.tr(),
          style: TextStyle(color: p.textMeta, fontSize: 12),
        ),
        onTap: () => _onRestore(context, ref),
      ),
    ];
  }

  // ─── 위젯 빌더: 개발/설정 섹션 ───────────────────────────────
  List<Widget> _buildDevSettingsSection(
      BuildContext context, AppColorScheme p) {
    return [
      Divider(color: p.divider, height: 1),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          'storageRefresh'.tr(),
          style: TextStyle(
              color: p.textMeta, fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
      ListTile(
        leading: Icon(Icons.timer_outlined, color: p.icon),
        title: Text(
          'backupCooldown'.tr(),
          style: TextStyle(color: p.textPrimary, fontSize: 16),
        ),
        subtitle: Text(
          '${AppStorage.getCooldownMinutes()} min',
          style: TextStyle(color: p.textMeta, fontSize: 12),
        ),
        onTap: () => _showCooldownDialog(context),
      ),
      ListTile(
        leading: Icon(Icons.refresh_outlined, color: p.icon),
        title: Text(
          'clearBackupAttempt'.tr(),
          style: TextStyle(color: p.textPrimary, fontSize: 16),
        ),
        subtitle: Text(
          'clearBackupAttemptHint'.tr(),
          style: TextStyle(color: p.textMeta, fontSize: 12),
        ),
        onTap: () => _onClearBackupAttempt(context),
      ),
    ];
  }

  // ─── build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        backgroundColor: p.background,
        iconTheme: IconThemeData(color: p.icon),
        title: Text(
          'backupAndRestore'.tr(),
          style: TextStyle(
            color: p.textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          EmailRegistrationCard(
            recoveryStatus: _recoveryStatus,
            isLoadingStatus: _isLoadingStatus,
            onStatusReloaded: _loadRecoveryStatus,
          ),
          if (!_isLoadingStatus)
            ServerBackupStatusCard(recoveryStatus: _recoveryStatus),
          ..._buildBackupActionSection(context, ref, p),
          ..._buildDevSettingsSection(context, p),
        ],
      ),
    );
  }
}

// server_backup_status_card.dart
// 서버 백업 상태 표시 카드 위젯

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:habitcell/service/backup_service.dart';
import 'package:habitcell/theme/app_theme_colors.dart';
import 'package:habitcell/util/config_ui.dart';
import 'package:intl/intl.dart';

/// 서버 백업 존재 여부 + 마지막 백업 시각을 표시하는 카드
class ServerBackupStatusCard extends StatelessWidget {
  final RecoveryStatus? recoveryStatus;

  const ServerBackupStatusCard({
    super.key,
    required this.recoveryStatus,
  });

  String _formatBackupAt(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso);
      return DateFormat('yyyy-MM-dd HH:mm').format(dt);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.appTheme;
    final hasBackup = recoveryStatus?.hasBackup ?? false;
    final lastAt = recoveryStatus?.lastBackupAt;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ConfigUI.screenPaddingH,
        vertical: 8,
      ),
      child: Card(
        color: p.cardBackground,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                hasBackup
                    ? Icons.cloud_done_outlined
                    : Icons.cloud_off_outlined,
                size: 16,
                color: hasBackup ? p.icon : p.textMeta,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  hasBackup
                      ? '${'backupOnServer'.tr()}${_formatBackupAt(lastAt)}'
                      : 'noBackupOnServerHint'.tr(),
                  style: TextStyle(
                    color: hasBackup ? p.textSecondary : p.textMeta,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

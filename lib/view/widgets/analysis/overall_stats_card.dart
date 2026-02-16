// overall_stats_card.dart
// 분석 탭 전체 통계 카드 (Streak, 7일/30일 달성)

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:habitcell/model/habit_stats.dart';
import 'package:habitcell/theme/app_theme_colors.dart';
import 'package:habitcell/util/config_ui.dart';
import 'package:habitcell/view/widgets/analysis/stat_item.dart';

/// 전체 통계 카드
class OverallStatsCard extends StatelessWidget {
  final OverallStats stats;
  final AppThemeColorsHelper palette;

  const OverallStatsCard({
    super.key,
    required this.stats,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return Container(
      padding: const EdgeInsets.all(ConfigUI.screenPaddingH),
      decoration: BoxDecoration(
        color: p.cardBackground,
        borderRadius: ConfigUI.cardRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'statsOverall'.tr(),
            style: TextStyle(
              color: p.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'statsStreak'.tr(),
            style: TextStyle(
              color: p.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${stats.streak}${'daysUnit'.tr()}',
            style: TextStyle(
              color: p.primary,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'statsOverallHint'.tr(),
            style: TextStyle(color: p.textMeta, fontSize: 11),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: StatItem(
                  label: 'stats7d'.tr(),
                  value: '${stats.achieved7}/7',
                  palette: p,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatItem(
                  label: 'stats30d'.tr(),
                  value: '${stats.achieved30}/30',
                  palette: p,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

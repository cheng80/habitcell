// stats_per_habit_cards.dart
// 습관별 통계 카드 목록

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:habitcell/model/category.dart';
import 'package:habitcell/model/habit_stats.dart';
import 'package:habitcell/theme/app_colors.dart';
import 'package:habitcell/theme/config_ui.dart';
import 'package:habitcell/view/widgets/analysis/stat_item.dart';
import 'package:habitcell/view/widgets/habit_heatmap.dart';

/// 습관별 통계 카드 목록
class StatsPerHabitCards extends StatelessWidget {
  final OverallStats stats;
  final List<Category> categories;
  final AppColorScheme palette;

  const StatsPerHabitCards({
    super.key,
    required this.stats,
    required this.categories,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return Column(
      children: stats.habitStats.map((hs) {
        final rate7 = hs.achieved7 > 0 ? (hs.achieved7 / 7 * 100).round() : 0;
        final rate30 = hs.achieved30 > 0 ? (hs.achieved30 / 30 * 100).round() : 0;
        final category = hs.habit.categoryId != null
            ? categories.where((c) => c.id == hs.habit.categoryId).firstOrNull
            : null;
        final baseColor = category?.color ?? const Color(0xFF9E9E9E);
        final emptyColor = p.divider.withValues(alpha: 0.5);
        final levelColors = levelColorsFromBase(baseColor, emptyColor);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(ConfigUI.paddingCard),
          decoration: BoxDecoration(
            color: p.cardBackground,
            borderRadius: ConfigUI.cardRadius,
            border: Border.all(color: p.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${hs.habit.title} (${category?.name ?? 'categoryNone'.tr()})',
                style: TextStyle(
                  color: p.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: StatItem(
                      label: 'stats7d'.tr(),
                      value: '$rate7%',
                      palette: p,
                    ),
                  ),
                  Expanded(
                    child: StatItem(
                      label: 'stats30d'.tr(),
                      value: '$rate30%',
                      palette: p,
                    ),
                  ),
                  Expanded(
                    child: StatItem(
                      label: 'statsStreak'.tr(),
                      value: '${hs.streak}${'daysUnit'.tr()}',
                      palette: p,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CompactHabitHeatmap(
                dayAchievements: hs.dayAchievements,
                emptyColor: emptyColor,
                levelColors: levelColors,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

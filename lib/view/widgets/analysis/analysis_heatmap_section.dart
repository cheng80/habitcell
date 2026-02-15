// analysis_heatmap_section.dart
// 분석 탭 전체 히트맵 섹션

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitcell/model/habit_stats.dart';
import 'package:habitcell/theme/app_colors.dart';
import 'package:habitcell/theme/config_ui.dart';
import 'package:habitcell/view/widgets/habit_heatmap.dart';
import 'package:habitcell/vm/heatmap_theme_notifier.dart';

/// 분석 탭 전체 히트맵 섹션
class AnalysisHeatmapSection extends StatelessWidget {
  final AsyncValue<List<DayAchievement>> heatmapAsync;
  final HeatmapTheme theme;
  final HeatmapRange heatmapRange;
  final AppColorScheme palette;

  const AnalysisHeatmapSection({
    super.key,
    required this.heatmapAsync,
    required this.theme,
    required this.heatmapRange,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final emptyColor = p.divider.withValues(alpha: 0.5);
    final colors = getHeatmapColors(theme, emptyColor);

    final pad = MediaQuery.sizeOf(context).width > 400
        ? ConfigUI.paddingCard
        : ConfigUI.screenPaddingHCompact;
    return Container(
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: p.cardBackground,
        borderRadius: ConfigUI.cardRadius,
        border: Border.all(color: p.divider),
      ),
      child: heatmapAsync.when(
        data: (list) => LayoutBuilder(
          builder: (context, constraints) => HabitHeatmap(
            dayAchievements: list,
            emptyColor: colors.empty,
            levelColors: colors.levels,
            range: heatmapRange,
            availableWidth: constraints.maxWidth,
          ),
        ),
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(ConfigUI.paddingEmptyState),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (e, _) => Center(
          child: Text(
            '${'errorOccurred'.tr()}: $e',
            style: TextStyle(color: p.textSecondary),
          ),
        ),
      ),
    );
  }
}

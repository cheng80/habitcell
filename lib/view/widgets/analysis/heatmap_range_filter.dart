// heatmap_range_filter.dart
// 분석 탭 히트맵 기간 필터 칩

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:habitcell/theme/app_theme_colors.dart';
import 'package:habitcell/model/habit_stats.dart';
import 'package:habitcell/util/config_ui.dart';

/// 히트맵 기간 필터 (주/월/년/전체)
class HeatmapRangeFilter extends StatelessWidget {
  final HeatmapRange current;
  final ValueChanged<HeatmapRange> onChanged;
  final AppThemeColorsHelper palette;

  const HeatmapRangeFilter({
    super.key,
    required this.current,
    required this.onChanged,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: HeatmapRange.values.map((r) {
        final isSelected = current == r;
        return GestureDetector(
          onTap: () {
            if (!isSelected) onChanged(r);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: ConfigUI.chipPaddingHCompact,
              vertical: ConfigUI.chipPaddingV,
            ),
            decoration: BoxDecoration(
              color: isSelected ? p.primary.withValues(alpha: 0.2) : p.cardBackground,
              borderRadius: ConfigUI.cardRadius,
              border: Border.all(color: isSelected ? p.primary : p.divider),
            ),
            child: Text(
              _rangeLabel(r),
              style: TextStyle(
                color: isSelected ? p.primary : p.textSecondary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _rangeLabel(HeatmapRange r) {
    return switch (r) {
      HeatmapRange.week => 'heatmapRangeWeek'.tr(),
      HeatmapRange.month => 'heatmapRangeMonth'.tr(),
      HeatmapRange.year => 'heatmapRangeYear'.tr(),
      HeatmapRange.all => 'heatmapRangeAll'.tr(),
    };
  }
}

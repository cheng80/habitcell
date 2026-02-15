// analysis_screen.dart
// 분석 탭 - 히트맵, Streak, 통계
//
// [구성] 전체 통계 카드 → 히트맵(기간 필터) → 습관별 통계 카드
// [색상] 전체 히트맵=Drawer 테마색, 습관별 카드=카테고리 색상, 없음=회색(#9E9E9E)
// [의존] habitStatsProvider, heatmapDataProvider(HeatmapRange), heatmapThemeNotifier

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitcell/theme/app_colors.dart';
import 'package:habitcell/theme/config_ui.dart';
import 'package:habitcell/util/common_util.dart';
import 'package:habitcell/model/category.dart';
import 'package:habitcell/view/widgets/habit_heatmap.dart';
import 'package:habitcell/vm/category_list_notifier.dart';
import 'package:habitcell/model/habit_stats.dart';
import 'package:habitcell/vm/habit_stats_provider.dart';
import 'package:habitcell/vm/heatmap_data_provider.dart';
import 'package:habitcell/vm/heatmap_range_notifier.dart';
import 'package:habitcell/vm/heatmap_theme_notifier.dart';

/// 분석 화면 - 통계, Streak, 히트맵
class AnalysisScreen extends ConsumerWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final statsAsync = ref.watch(habitStatsProvider);
    final heatmapRange = ref.watch(heatmapRangeProvider);
    final heatmapAsync = ref.watch(heatmapDataProvider(heatmapRange));
    final heatmapTheme = ref.watch(heatmapThemeNotifierProvider);

    ref.listen<AsyncValue<OverallStats>>(habitStatsProvider, (previous, next) {
      if (next is AsyncError) {
        showCommonSnackBar(
          context,
          message: '${'errorOccurred'.tr()}: ${next.error}',
          action: SnackBarAction(
            label: 'retry'.tr(),
            onPressed: () => ref.invalidate(habitStatsProvider),
          ),
        );
      }
    });

    return statsAsync.when(
      data: (stats) {
        if (stats.habitStats.isEmpty) {
          return _buildEmptyState(p);
        }
        final categories = ref.watch(categoryListProvider).value ?? [];
        final paddingH = MediaQuery.sizeOf(context).width > 400
            ? ConfigUI.screenPaddingH
            : ConfigUI.screenPaddingHCompact;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(paddingH, 16, paddingH, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildOverallStats(p, stats),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'heatmapTitle'.tr(),
                    style: TextStyle(
                      color: p.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  _HeatmapRangeFilter(
                    current: heatmapRange,
                    onChanged: (r) => ref.read(heatmapRangeProvider.notifier).setRange(r),
                    palette: p,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'heatmapHint'.tr(),
                style: TextStyle(color: p.textMeta, fontSize: 11),
              ),
              const SizedBox(height: 12),
              _buildHeatmap(context, p, heatmapAsync, heatmapTheme, heatmapRange),
              const SizedBox(height: 24),
              Text(
                'statsPerHabit'.tr(),
                style: TextStyle(
                  color: p.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'statsPerHabitHint'.tr(),
                style: TextStyle(color: p.textMeta, fontSize: 11),
              ),
              const SizedBox(height: 12),
              _buildStatsCards(p, stats, categories),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 16,
          children: [
            Text('${'errorOccurred'.tr()}: $err', style: TextStyle(color: p.textPrimary)),
            ElevatedButton(
              onPressed: () => ref.invalidate(habitStatsProvider),
              child: Text('retry'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildOverallStats(AppColorScheme p, OverallStats stats) {
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
              child: _StatItem(
                label: 'stats7d'.tr(),
                value: '${stats.achieved7}/7',
                palette: p,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _StatItem(
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

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final AppColorScheme palette;

  const _StatItem({
    required this.label,
    required this.value,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: palette.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: palette.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

Widget _buildStatsCards(
  AppColorScheme p,
  OverallStats stats,
  List<Category> categories,
) {
  return Column(
    children: stats.habitStats.map((hs) {
      final rate7 = hs.achieved7 > 0 ? (hs.achieved7 / 7 * 100).round() : 0;
      final rate30 = hs.achieved30 > 0 ? (hs.achieved30 / 30 * 100).round() : 0;
      final category = hs.habit.categoryId != null
          ? categories.where((c) => c.id == hs.habit.categoryId).firstOrNull
          : null;
      // 없음 카테고리는 무채색(회색)으로, 파란색 계열 히트맵과 구분
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
                  child: _StatItem(
                    label: 'stats7d'.tr(),
                    value: '$rate7%',
                    palette: p,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    label: 'stats30d'.tr(),
                    value: '$rate30%',
                    palette: p,
                  ),
                ),
                Expanded(
                  child: _StatItem(
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

Widget _buildHeatmap(
  BuildContext context,
  AppColorScheme p,
  AsyncValue<List<DayAchievement>> heatmapAsync,
  HeatmapTheme theme,
  HeatmapRange heatmapRange,
) {
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
          padding: const EdgeInsets.all(ConfigUI.paddingEmptyState),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) => Center(
        child: Text('${'errorOccurred'.tr()}: $e', style: TextStyle(color: p.textSecondary)),
      ),
    ),
  );
}

class _HeatmapRangeFilter extends StatelessWidget {
  final HeatmapRange current;
  final ValueChanged<HeatmapRange> onChanged;
  final AppColorScheme palette;

  const _HeatmapRangeFilter({
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
                horizontal: ConfigUI.chipPaddingHCompact, vertical: ConfigUI.chipPaddingV),
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

Widget _buildEmptyState(AppColorScheme p) {
  return Center(
    child: Padding(
        padding: const EdgeInsets.all(ConfigUI.paddingEmptyState),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 12,
        children: [
          Icon(Icons.analytics_outlined, size: 64, color: p.textSecondary),
          Text(
            'statsEmpty'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(color: p.textSecondary, fontSize: 16),
          ),
        ],
      ),
    ),
  );
}

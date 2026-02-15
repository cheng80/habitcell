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
import 'package:habitcell/view/widgets/analysis/analysis_heatmap_section.dart';
import 'package:habitcell/view/widgets/analysis/heatmap_range_filter.dart';
import 'package:habitcell/view/widgets/analysis/overall_stats_card.dart';
import 'package:habitcell/view/widgets/analysis/stats_per_habit_cards.dart';
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
              OverallStatsCard(stats: stats, palette: p),
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
                  HeatmapRangeFilter(
                    current: heatmapRange,
                    onChanged: (r) =>
                        ref.read(heatmapRangeProvider.notifier).setRange(r),
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
              AnalysisHeatmapSection(
                heatmapAsync: heatmapAsync,
                theme: heatmapTheme,
                heatmapRange: heatmapRange,
                palette: p,
              ),
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
              StatsPerHabitCards(
                stats: stats,
                categories: categories,
                palette: p,
              ),
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
            Text(
              '${'errorOccurred'.tr()}: $err',
              style: TextStyle(color: p.textPrimary),
            ),
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

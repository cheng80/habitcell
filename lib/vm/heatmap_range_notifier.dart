// heatmap_range_notifier.dart
// 히트맵 기간 선택 상태 (week/month/year/all)
//
// [기본값] HeatmapRange.year
// [연쇄] heatmapDataProvider(HeatmapRange)가 watch → 기간 변경 시 데이터 재조회

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitcell/model/habit_stats.dart';

class HeatmapRangeNotifier extends Notifier<HeatmapRange> {
  @override
  HeatmapRange build() => HeatmapRange.year;

  void setRange(HeatmapRange range) => state = range;
}

final heatmapRangeProvider =
    NotifierProvider<HeatmapRangeNotifier, HeatmapRange>(HeatmapRangeNotifier.new);

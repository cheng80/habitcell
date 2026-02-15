// heatmap_data_provider.dart
// 히트맵 데이터 Provider (스냅샷 기반)
//
// [데이터 소스]
// - 년/전체: heatmap_daily_snapshots 테이블 (날짜별 달성률 사전 계산)
// - 주/월: 스냅샷 또는 실시간 로그 조합
// [level 정의] 0=미달성, 1~4=달성 강도 (achieved/total 비율로 4단계)

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitcell/model/habit_stats.dart';
import 'package:habitcell/util/date_util.dart';
import 'package:habitcell/vm/habit_database_handler.dart';
import 'package:habitcell/vm/habit_list_notifier.dart';

final heatmapDataProvider =
    FutureProvider.family<List<DayAchievement>, HeatmapRange>((ref, range) async {
  ref.watch(habitListProvider);
  return _loadHeatmapData(range);
});

Future<List<DayAchievement>> _loadHeatmapData(HeatmapRange range) async {
  final handler = HabitDatabaseHandler();
  final today = dateToday();
  final todayDt = DateTime.parse(today);

  // 기간별 날짜 범위 정책
  String startDate;
  String endDate;
  switch (range) {
    case HeatmapRange.week:
      startDate = addDays(today, -6); // 7일 (오늘 포함)
      endDate = today;
      break;
    case HeatmapRange.month:
      startDate = firstDayOfMonth(todayDt.year, todayDt.month);
      endDate = lastDayOfMonth(todayDt.year, todayDt.month);
      break;
    case HeatmapRange.year:
      startDate = addDays(today, -364); // 약 1년
      endDate = today;
      break;
    case HeatmapRange.all:
      startDate = addDays(today, -3650); // 약 10년
      endDate = today;
      break;
  }

  final snapshots = await handler.getHeatmapSnapshots(startDate, endDate);
  final list = <DayAchievement>[];
  for (final row in snapshots) {
    list.add(DayAchievement(
      row['date'] as String,
      row['level'] as int,
    ));
  }

  // 스냅샷에 오늘이 없으면 실시간 계산 후 추가 (당일 데이터 반영)
  final hasToday = list.any((d) => d.date == today);
  if (!hasToday) {
    final habits = await handler.getAllHabits();
    if (habits.isNotEmpty) {
      final logs = await handler.getLogsInDateRange(today, today);
      final logByHabit = {for (final l in logs) l.habitId: l};
      var achieved = 0;
      for (final h in habits) {
        if ((logByHabit[h.id]?.count ?? 0) >= h.dailyTarget) achieved++;
      }
      final total = habits.length;
      // achieved/total 비율을 1~4 구간으로 매핑 (0이면 level 0)
      final level = total == 0
          ? 0
          : achieved == 0
              ? 0
              : ((achieved / total) * 4).ceil().clamp(1, 4);
      list.add(DayAchievement(today, level));
      list.sort((a, b) => a.date.compareTo(b.date));
    }
  }

  return list;
}

// habit_stats_provider.dart
// 습관 통계 Provider (카드용 - 현재 습관만)
//
// [정책]
// - achieved7/30: 해당 기간 내 count >= daily_target인 날의 개수
// - streak: 오늘부터 역순으로 "달성"이 끊길 때까지의 연속 일수
// - 전체 streak: "모든 습관이 그날 달성"한 날만 카운트
// - DayAchievement.level: 0=미달성, 1=달성, 2~4=초과달성 강도 (target 초과 비율로 계산)

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitcell/model/habit.dart';
import 'package:habitcell/model/habit_daily_log.dart';
import 'package:habitcell/model/habit_stats.dart';
import 'package:habitcell/util/date_util.dart';
import 'package:habitcell/vm/habit_database_handler.dart';
import 'package:habitcell/vm/habit_list_notifier.dart';

/// 전체 통계 Provider (habitList 변경 시 자동 재계산)
final habitStatsProvider = FutureProvider<OverallStats>((ref) async {
  ref.watch(habitListProvider);
  return _loadOverallStats();
});

Future<OverallStats> _loadOverallStats() async {
  final handler = HabitDatabaseHandler();
  final allHabits = await handler.getAllHabitsIncludingDeleted();
  final habits = allHabits.where((h) => !h.isDeleted).toList();
  if (habits.isEmpty) {
    return const OverallStats(
      achieved7: 0,
      achieved30: 0,
      streak: 0,
      habitStats: [],
    );
  }

  final today = dateToday();
  final startDate = addDays(today, -365);
  final logs = await handler.getLogsInDateRange(startDate, today);

  final habitLogMap = <String, List<HabitDailyLog>>{};
  for (final log in logs) {
    habitLogMap.putIfAbsent(log.habitId, () => []).add(log);
  }

  final habitStatsList = <HabitStats>[];
  for (final habit in habits) {
    final habitLogs = habitLogMap[habit.id] ?? [];
    final stats = _calcHabitStats(habit, habitLogs, today);
    habitStatsList.add(stats);
  }

  final allDays = dateRange(startDate, today);
  var achieved7 = 0;
  var achieved30 = 0;
  var streak = 0;

  // 최근 7일/30일: 날짜 리스트 끝에서 역순으로 슬라이스
  final last7 = allDays.length >= 7 ? allDays.sublist(allDays.length - 7) : allDays;
  final last30 = allDays.length >= 30 ? allDays.sublist(allDays.length - 30) : allDays;

  // 해당 날짜에 존재했던 습관만 기준으로 "전부 달성" 판단 (히트맵과 동일 정책)
  for (final d in last7) {
    if (_isAllAchievedOnDate(d, allHabits, habitLogMap)) achieved7++;
  }
  for (final d in last30) {
    if (_isAllAchievedOnDate(d, allHabits, habitLogMap)) achieved30++;
  }

  // streak: 어제부터 역순으로, "전부 달성"이 끊기는 날까지 (오늘은 아직 지나지 않은 날이라 제외)
  for (var i = allDays.length - 2; i >= 0; i--) {
    if (_isAllAchievedOnDate(allDays[i], allHabits, habitLogMap)) {
      streak++;
    } else {
      break;
    }
  }

  return OverallStats(
    achieved7: achieved7,
    achieved30: achieved30,
    streak: streak,
    habitStats: habitStatsList,
  );
}

HabitStats _calcHabitStats(
  Habit habit,
  List<HabitDailyLog> logs,
  String today,
) {
  final logByDate = {for (final l in logs) l.date: l};
  final target = habit.dailyTarget;

  final dayAchievements = <DayAchievement>[];
  final startDate = addDays(today, -365);
  final range = dateRange(startDate, today);

  for (final date in range) {
    final log = logByDate[date];
    final count = log?.count ?? 0;
    final achieved = count >= target;
    int level;
    if (!achieved) {
      level = 0;
    } else if (count <= target) {
      level = 1; // 정확히 달성
    } else {
      // 초과 달성: (count-target)/target 구간당 +1, 최대 level 4
      level = (2 + ((count - target) / target).floor().clamp(0, 2)).toInt();
      level = level.clamp(1, 4);
    }
    dayAchievements.add(DayAchievement(date, level));
  }

  final last7 = range.length >= 7 ? range.sublist(range.length - 7) : range;
  final last30 = range.length >= 30 ? range.sublist(range.length - 30) : range;

  var achieved7 = 0;
  var achieved30 = 0;
  for (final d in last7) {
    if ((logByDate[d]?.count ?? 0) >= target) achieved7++;
  }
  for (final d in last30) {
    if ((logByDate[d]?.count ?? 0) >= target) achieved30++;
  }

  var streak = 0;
  // 어제부터 역순 (오늘은 아직 지나지 않은 날이라 제외)
  for (var i = range.length - 2; i >= 0; i--) {
    if ((logByDate[range[i]]?.count ?? 0) >= target) {
      streak++;
    } else {
      break;
    }
  }

  return HabitStats(
    habit: habit,
    achieved7: achieved7,
    achieved30: achieved30,
    streak: streak,
    dayAchievements: dayAchievements,
  );
}

/// 해당 날짜에 "그날 존재했던" 모든 습관이 달성(count >= daily_target)했는지
/// (나중에 추가된 습관은 과거 날짜에서 제외, 히트맵과 동일 정책)
bool _isAllAchievedOnDate(
  String date,
  List<Habit> allHabits,
  Map<String, List<HabitDailyLog>> habitLogMap,
) {
  final activeHabits = allHabits.where((h) => HabitDatabaseHandler.wasActiveOnDate(h, date)).toList();
  if (activeHabits.isEmpty) return false;
  for (final habit in activeHabits) {
    final logs = habitLogMap[habit.id];
    final log = logs?.where((l) => l.date == date).firstOrNull;
    final count = log?.count ?? 0;
    if (count < habit.dailyTarget) return false;
  }
  return true;
}

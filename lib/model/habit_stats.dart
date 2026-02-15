// habit_stats.dart
// 통계 관련 모델 - DayAchievement, HabitStats, OverallStats, HeatmapRange
//
// [level 정의] 0=미달성, 1=달성, 2~4=초과달성 강도 (count/target 비율)
// [streak] 어제부터 역순으로 "달성"이 끊길 때까지의 연속 일수 (오늘 제외)
// [achieved7/30] 해당 기간 내 달성한 날의 개수 (일수 아님)

import 'package:habitcell/model/habit.dart';

/// 날짜별 달성 상태 (히트맵용)
class DayAchievement {
  final String date; // YYYY-MM-DD
  final int level; // 0: 미달성, 1: 달성, 2~4: 초과 달성 강도
  const DayAchievement(this.date, this.level);
}

/// 습관별 통계
class HabitStats {
  final Habit habit;
  final int achieved7; // 최근 7일 중 달성일
  final int achieved30; // 최근 30일 중 달성일
  final int streak; // 연속 달성일 (어제부터 역산, 오늘 제외)
  final List<DayAchievement> dayAchievements; // 날짜순
  const HabitStats({
    required this.habit,
    required this.achieved7,
    required this.achieved30,
    required this.streak,
    required this.dayAchievements,
  });
}

/// 전체 통계 (현재 존재하는 습관만)
class OverallStats {
  final int achieved7; // 최근 7일 중 "전부 달성"한 날
  final int achieved30; // 최근 30일 중 "전부 달성"한 날
  final int streak; // 연속 "전부 달성" 일수 (어제부터 역산, 오늘 제외)
  final List<HabitStats> habitStats;
  const OverallStats({
    required this.achieved7,
    required this.achieved30,
    required this.streak,
    required this.habitStats,
  });
}

/// 히트맵 기간
enum HeatmapRange { week, month, year, all }

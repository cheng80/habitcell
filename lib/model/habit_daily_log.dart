// habit_daily_log.dart
// 일별 습관 기록 모델 - docs/habit/habit_app_db_schema_master_v_1_0.md 기반

/// 습관 일별 로그
/// habit_id + date(YYYY-MM-DD) 기준 하루 1행
class HabitDailyLog {
  final String id;
  final String habitId;
  final String date; // YYYY-MM-DD
  final int count;
  final bool isCompleted;
  final bool isDeleted;
  final bool isDirty;
  final String createdAt;
  final String updatedAt;

  const HabitDailyLog({
    required this.id,
    required this.habitId,
    required this.date,
    this.count = 0,
    this.isCompleted = false,
    this.isDeleted = false,
    this.isDirty = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// count >= dailyTarget 이면 달성
  bool isAchieved(int dailyTarget) => count >= dailyTarget;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'habit_id': habitId,
      'date': date,
      'count': count,
      'is_completed': isCompleted ? 1 : 0,
      'is_deleted': isDeleted ? 1 : 0,
      'is_dirty': isDirty ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory HabitDailyLog.fromMap(Map<String, dynamic> map) {
    return HabitDailyLog(
      id: map['id'] as String,
      habitId: map['habit_id'] as String,
      date: map['date'] as String,
      count: map['count'] as int? ?? 0,
      isCompleted: (map['is_completed'] as int? ?? 0) == 1,
      isDeleted: (map['is_deleted'] as int? ?? 0) == 1,
      isDirty: (map['is_dirty'] as int? ?? 1) == 1,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }
}

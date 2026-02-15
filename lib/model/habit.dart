// habit.dart
// 습관 모델 - docs/habit/habit_app_db_schema_master_v_1_0.md 기반

/// 습관 데이터 모델
/// SQLite habits 테이블과 매핑
class Habit {
  final String id;
  final String title;
  final int dailyTarget;
  final int sortOrder;
  final String? categoryId;
  final String? reminderTime; // HH:mm 리마인드
  final String? deadlineReminderTime; // HH:mm 마감 알림 (미달성 시)
  final bool isActive;
  final bool isDeleted;
  final bool isDirty;
  final String createdAt;
  final String updatedAt;

  const Habit({
    required this.id,
    required this.title,
    this.dailyTarget = 1,
    this.sortOrder = 0,
    this.categoryId,
    this.reminderTime,
    this.deadlineReminderTime,
    this.isActive = true,
    this.isDeleted = false,
    this.isDirty = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Habit copyWith({
    String? id,
    String? title,
    int? dailyTarget,
    int? sortOrder,
    String? categoryId,
    bool clearCategoryId = false,
    String? reminderTime,
    String? deadlineReminderTime,
    bool clearDeadlineReminderTime = false,
    bool? isActive,
    bool? isDeleted,
    bool? isDirty,
    String? createdAt,
    String? updatedAt,
  }) {
    return Habit(
      id: id ?? this.id,
      title: title ?? this.title,
      dailyTarget: dailyTarget ?? this.dailyTarget,
      sortOrder: sortOrder ?? this.sortOrder,
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
      reminderTime: reminderTime ?? this.reminderTime,
      deadlineReminderTime: clearDeadlineReminderTime
          ? null
          : (deadlineReminderTime ?? this.deadlineReminderTime),
      isActive: isActive ?? this.isActive,
      isDeleted: isDeleted ?? this.isDeleted,
      isDirty: isDirty ?? this.isDirty,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'daily_target': dailyTarget,
      'sort_order': sortOrder,
      'category_id': categoryId,
      'reminder_time': reminderTime,
      'deadline_reminder_time': deadlineReminderTime,
      'is_active': isActive ? 1 : 0,
      'is_deleted': isDeleted ? 1 : 0,
      'is_dirty': isDirty ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'] as String,
      title: map['title'] as String,
      dailyTarget: map['daily_target'] as int? ?? 1,
      sortOrder: map['sort_order'] as int? ?? 0,
      categoryId: map['category_id'] as String?,
      reminderTime: map['reminder_time'] as String?,
      deadlineReminderTime: map['deadline_reminder_time'] as String?,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      isDeleted: (map['is_deleted'] as int? ?? 0) == 1,
      isDirty: (map['is_dirty'] as int? ?? 1) == 1,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }
}

// habit_list_notifier.dart
// 습관 목록 Riverpod Notifier - HabitDatabaseHandler 기반
//
// [역할] 습관 CRUD, +1/-1 (오늘 count), 완료 토글, 순서 변경
// [정책] createHabit 시 sort_order = 기존 최대값+1 (맨 뒤 추가)
// [정책] deleteHabit → 소프트 삭제, habitListProvider 무효화로 heatmap/stats 연쇄 갱신

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitcell/model/habit.dart';
import 'package:habitcell/service/backup_service.dart';
import 'package:habitcell/vm/habit_database_handler.dart';

/// HabitListNotifier - Riverpod AsyncNotifier 기반 ViewModel
///
/// 습관 목록 + 오늘 count를 비동기로 관리합니다.
/// state는 AsyncValue<List<HabitWithTodayCount>>로, 로딩/데이터/에러 3가지 상태를 포함합니다.
class HabitListNotifier extends AsyncNotifier<List<HabitWithTodayCount>> {
  final HabitDatabaseHandler _dbHandler = HabitDatabaseHandler();

  @override
  Future<List<HabitWithTodayCount>> build() async {
    return await _dbHandler.getHabitsWithTodayCount();
  }

  /// 새 습관 생성
  Future<void> createHabit({
    required String title,
    int dailyTarget = 1,
    String? categoryId,
    String? deadlineReminderTime,
  }) async {
    final habits = await _dbHandler.getAllHabits();
    final sortOrder = habits.isEmpty ? 0 : habits.map((h) => h.sortOrder).reduce((a, b) => a > b ? a : b) + 1;
    await _dbHandler.createHabit(
      title: title,
      dailyTarget: dailyTarget,
      sortOrder: sortOrder,
      categoryId: categoryId,
      deadlineReminderTime: deadlineReminderTime,
    );
    ref.invalidateSelf();
    BackupService().autoBackupIfNeeded(trigger: 'createHabit');
  }

  /// 습관 수정
  Future<void> updateHabit(Habit habit) async {
    await _dbHandler.updateHabit(habit);
    ref.invalidateSelf();
    BackupService().autoBackupIfNeeded(trigger: 'updateHabit');
  }

  /// 습관 삭제 (소프트 삭제)
  Future<void> deleteHabit(String id) async {
    await _dbHandler.deleteHabit(id);
    ref.invalidateSelf();
    BackupService().autoBackupIfNeeded(trigger: 'deleteHabit');
  }

  /// 오늘 count +1
  Future<void> incrementCount(String habitId) async {
    await _dbHandler.incrementCount(habitId);
    ref.invalidateSelf();
    BackupService().autoBackupIfNeeded(trigger: 'incrementCount');
  }

  /// 오늘 count -1 (0 미만 방지)
  Future<void> decrementCount(String habitId) async {
    await _dbHandler.decrementCount(habitId);
    ref.invalidateSelf();
    BackupService().autoBackupIfNeeded(trigger: 'decrementCount');
  }

  /// 오늘 완료 토글 (count >= target일 때만)
  Future<void> toggleCompleted(String habitId) async {
    await _dbHandler.toggleCompleted(habitId);
    ref.invalidateSelf();
    BackupService().autoBackupIfNeeded(trigger: 'toggleCompleted');
  }

  /// 순서 변경
  Future<void> reorderHabits(List<String> habitIds) async {
    await _dbHandler.reorderHabits(habitIds);
    ref.invalidateSelf();
    BackupService().autoBackupIfNeeded(trigger: 'reorderHabits');
  }

  /// 수동 새로고침
  void reloadData() {
    ref.invalidateSelf();
  }

  /// 개발용: 더미 데이터 삽입
  Future<void> insertDummyData() async {
    await _dbHandler.insertDummyData();
    ref.invalidateSelf();
  }

  /// 개발용: 모든 습관 및 로그 일괄 삭제
  Future<void> deleteAllHabitsAndLogs() async {
    await _dbHandler.deleteAllHabitsAndLogs();
    ref.invalidateSelf();
  }
}

/// 습관 목록 Provider (습관 + 오늘 count)
final habitListProvider =
    AsyncNotifierProvider<HabitListNotifier, List<HabitWithTodayCount>>(HabitListNotifier.new);

// app_storage.dart
// GetStorage 기반 앱 설정 헬퍼

import 'package:get_storage/get_storage.dart';

/// AppStorage - 앱 설정을 저장/조회하는 정적 헬퍼
///
/// GetStorage 접근을 한 곳으로 모아 관리한다.
/// 추후 설정 항목이 늘어나면 여기에 키/메서드를 추가한다.
class AppStorage {
  static GetStorage get _storage => GetStorage();

  // ─── 테마 ─────────────────────────────────────
  static const String _keyTheme = 'theme_mode';

  /// 저장된 테마 모드 문자열 조회 (light / dark / system)
  static String? getThemeMode() => _storage.read<String>(_keyTheme);

  /// 테마 모드 저장
  static Future<void> saveThemeMode(String mode) =>
      _storage.write(_keyTheme, mode);

  // ─── 스토어 리뷰 (in_app_review) ─────────────────
  static const String _keyFirstLaunchDate = 'first_launch_date';
  static const String _keyTodoCompletedCount = 'todo_completed_count';
  static const String _keyReviewRequested = 'review_requested';

  /// 첫 실행일 (ISO8601 문자열). 없으면 null → 최초 1회 저장
  static String? getFirstLaunchDate() =>
      _storage.read<String>(_keyFirstLaunchDate);

  /// 첫 실행일 저장 (앱 최초 실행 시 1회)
  static Future<void> saveFirstLaunchDate(DateTime date) =>
      _storage.write(_keyFirstLaunchDate, date.toIso8601String());

  /// 완료한 할 일 누적 횟수
  static int getTodoCompletedCount() =>
      _storage.read<int>(_keyTodoCompletedCount) ?? 0;

  /// 완료 횟수 증가
  static Future<void> incrementTodoCompletedCount() async {
    final n = getTodoCompletedCount() + 1;
    await _storage.write(_keyTodoCompletedCount, n);
  }

  /// 리뷰 요청 이미 했는지
  static bool getReviewRequested() =>
      _storage.read<bool>(_keyReviewRequested) ?? false;

  /// 리뷰 요청 완료 표시
  static Future<void> setReviewRequested() =>
      _storage.write(_keyReviewRequested, true);

  // ─── 튜토리얼 (showcaseview) ─────────────────────
  static const String _keyTutorialCompleted = 'tutorial_completed';

  /// 튜토리얼 완료/스킵 여부 (앱 최초 실행 시 false)
  static bool getTutorialCompleted() =>
      _storage.read<bool>(_keyTutorialCompleted) ?? false;

  /// 튜토리얼 완료 표시
  static Future<void> setTutorialCompleted() =>
      _storage.write(_keyTutorialCompleted, true);

  /// 튜토리얼 다시 보기용 초기화
  static Future<void> resetTutorialCompleted() =>
      _storage.write(_keyTutorialCompleted, false);

  /// 튜토리얼용 할 일 생성 여부 (앱 최초 실행 시 1회)
  static const String _keyTutorialTodoCreated = 'tutorial_todo_created';

  static bool getTutorialTodoCreated() =>
      _storage.read<bool>(_keyTutorialTodoCreated) ?? false;

  static Future<void> setTutorialTodoCreated() =>
      _storage.write(_keyTutorialTodoCreated, true);

  // ─── 화면 꺼짐 방지 (wakelock_plus) ─────────────────
  static const String _keyWakelock = 'wakelock_enabled';

  /// 화면 꺼짐 방지 여부 (기본값 false)
  static bool getWakelockEnabled() =>
      _storage.read<bool>(_keyWakelock) ?? false;

  static Future<void> setWakelockEnabled(bool enabled) =>
      _storage.write(_keyWakelock, enabled);

  // ─── 미리 알림 (점심/저녁 푸시) ─────────────────
  static const String _keyPreReminder = 'pre_reminder_enabled';

  /// 미리 알림 ON/OFF (기본값 true)
  static bool getPreReminderEnabled() =>
      _storage.read<bool>(_keyPreReminder) ?? true;

  static Future<void> setPreReminderEnabled(bool enabled) =>
      _storage.write(_keyPreReminder, enabled);

  // ─── 히트맵 테마 ─────────────────────────────────
  static const String _keyHeatmapTheme = 'heatmap_theme';

  /// 잔디 색상 테마 (github, ocean, sunset, lavender, mint, rose, monochrome)
  static String getHeatmapTheme() =>
      _storage.read<String>(_keyHeatmapTheme) ?? 'github';

  static Future<void> saveHeatmapTheme(String theme) =>
      _storage.write(_keyHeatmapTheme, theme);
}

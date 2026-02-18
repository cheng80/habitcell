// habit_database_handler.dart
// SQLite 기반 습관 DB CRUD - docs/habit/sqlite_schema_v1.md 기반
//
// [핵심 정책]
// - habits: 소프트 삭제(is_deleted), sort_order로 표시 순서
// - habit_daily_logs: (habit_id, date) 유니크, count >= daily_target → 달성
// - heatmap_daily_snapshots: 날짜별 "해당 시점에 존재했던 습관" 기준 달성률 (과거 데이터 정확도)
// - 카테고리: habits.category_id NULL = "없음", 삭제 시 SET NULL

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'package:habitcell/model/category.dart';
import 'package:habitcell/model/habit.dart';
import 'package:habitcell/model/habit_daily_log.dart';
import 'package:habitcell/service/notification_service.dart';
import 'package:habitcell/util/app_locale.dart';
import 'package:habitcell/util/app_storage.dart';

/// 습관 + 오늘 count + 완료 여부 (홈 화면용)
class HabitWithTodayCount {
  final Habit habit;
  final int todayCount;
  final bool isCompleted;
  const HabitWithTodayCount(this.habit, this.todayCount, {this.isCompleted = false});
}

/// 습관 앱 SQLite DB Handler
/// habits, habit_daily_logs, heatmap_daily_snapshots CRUD
class HabitDatabaseHandler {
  static Database? _db;
  static const String _dbName = 'habitcell.db';
  static const _uuid = Uuid();

  /// DB 인스턴스 (싱글톤)
  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, _dbName);
    debugPrint('[HabitDB] db file: $path');
    return openDatabase(
      path,
      version: 6,
      onCreate: (db, version) async {
        await db.execute('PRAGMA foreign_keys = ON');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS categories (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            color_value INTEGER NOT NULL DEFAULT 0xFF9E9E9E,
            sort_order INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_categories_sort ON categories(sort_order)');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS habits (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            daily_target INTEGER NOT NULL DEFAULT 1,
            sort_order INTEGER NOT NULL DEFAULT 0,
            category_id TEXT DEFAULT NULL,
            deadline_reminder_time TEXT DEFAULT NULL,
            is_active INTEGER NOT NULL DEFAULT 1,
            is_deleted INTEGER NOT NULL DEFAULT 0,
            is_dirty INTEGER NOT NULL DEFAULT 1,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL
          )
        ''');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_habits_active ON habits(is_active)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_habits_updated ON habits(updated_at)');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS habit_daily_logs (
            id TEXT PRIMARY KEY,
            habit_id TEXT NOT NULL,
            date TEXT NOT NULL,
            count INTEGER NOT NULL DEFAULT 0,
            is_completed INTEGER NOT NULL DEFAULT 0,
            is_deleted INTEGER NOT NULL DEFAULT 0,
            is_dirty INTEGER NOT NULL DEFAULT 1,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY (habit_id) REFERENCES habits(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('CREATE UNIQUE INDEX IF NOT EXISTS uk_habit_date ON habit_daily_logs(habit_id, date)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_logs_updated ON habit_daily_logs(updated_at)');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS heatmap_daily_snapshots (
            date TEXT PRIMARY KEY,
            achieved INTEGER NOT NULL DEFAULT 0,
            total INTEGER NOT NULL DEFAULT 0,
            level INTEGER NOT NULL DEFAULT 0,
            updated_at TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE habit_daily_logs ADD COLUMN is_completed INTEGER NOT NULL DEFAULT 0');
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE habits ADD COLUMN deadline_reminder_time TEXT DEFAULT NULL');
        }
        if (oldVersion < 6) {
          await db.execute('DROP TABLE IF EXISTS app_settings');
        }
        if (oldVersion < 5) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS heatmap_daily_snapshots (
              date TEXT PRIMARY KEY,
              achieved INTEGER NOT NULL DEFAULT 0,
              total INTEGER NOT NULL DEFAULT 0,
              level INTEGER NOT NULL DEFAULT 0,
              updated_at TEXT NOT NULL
            )
          ''');
        }
        if (oldVersion < 4) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS categories (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              color_value INTEGER NOT NULL DEFAULT 0xFF9E9E9E,
              sort_order INTEGER NOT NULL DEFAULT 0
            )
          ''');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_categories_sort ON categories(sort_order)');
          await db.execute('ALTER TABLE habits ADD COLUMN category_id TEXT DEFAULT NULL');
        }
      },
    );
  }

  static String _nowUtc() => DateTime.now().toUtc().toIso8601String();

  /// 습관 앱 기본 카테고리 색상 (건강, 집중, 독서 등)
  static const List<Color> _defaultCategoryColors = [
    Colors.green,       // 건강
    Colors.blue,        // 집중
    Colors.indigo,      // 독서
    Colors.red,         // 운동
    Colors.purpleAccent,// 명상
    Colors.teal,        // 수면
    Colors.lime,        // 식습관
    Colors.lightBlue,   // 학습
    Colors.pink,        // 취미
    Colors.brown,       // 기타
  ];

  /// locale별 기본 카테고리 이름 (습관 앱에 맞춤)
  static const Map<String, List<String>> _defaultCategoryNamesByLocale = {
    'ko': ['건강', '집중', '독서', '운동', '명상', '수면', '식습관', '학습', '취미', '기타'],
    'en': ['Health', 'Focus', 'Reading', 'Exercise', 'Meditation', 'Sleep', 'Diet', 'Study', 'Hobby', 'Others'],
    'ja': ['健康', '集中', '読書', '運動', '瞑想', '睡眠', '食習慣', '学習', '趣味', 'その他'],
    'zh_CN': ['健康', '专注', '阅读', '运动', '冥想', '睡眠', '饮食', '学习', '爱好', '其他'],
    'zh_TW': ['健康', '專注', '閱讀', '運動', '冥想', '睡眠', '飲食', '學習', '嗜好', '其他'],
  };

  static List<String> _getDefaultCategoryNamesForLocale(Locale? locale) {
    if (locale != null) {
      final key = locale.countryCode != null
          ? '${locale.languageCode}_${locale.countryCode}'
          : locale.languageCode;
      final names = _defaultCategoryNamesByLocale[key];
      if (names != null) return names;
    }
    return _defaultCategoryNamesByLocale['ko']!;
  }

  // ========== habits ==========

  Future<List<Habit>> getAllHabits() async {
    final db = await database;
    final rows = await db.query(
      'habits',
      where: 'is_deleted = ?',
      whereArgs: [0],
      orderBy: 'sort_order ASC',
    );
    return rows.map((r) => Habit.fromMap(r)).toList();
  }

  /// 삭제 포함 전체 습관 (히트맵 스냅샷용)
  Future<List<Habit>> getAllHabitsIncludingDeleted() async {
    final db = await database;
    final rows = await db.query(
      'habits',
      orderBy: 'sort_order ASC',
    );
    return rows.map((r) => Habit.fromMap(r)).toList();
  }

  /// habits + 오늘 날짜 count 병합 (홈 화면용)
  Future<List<HabitWithTodayCount>> getHabitsWithTodayCount() async {
    final habits = await getAllHabits();
    final today = _dateToday();
    final db = await database;
    final logRows = await db.query(
      'habit_daily_logs',
      columns: ['habit_id', 'count', 'is_completed'],
      where: 'date = ? AND is_deleted = ?',
      whereArgs: [today, 0],
    );
    final countMap = <String, int>{};
    final completedMap = <String, bool>{};
    for (final r in logRows) {
      final id = r['habit_id'] as String;
      countMap[id] = r['count'] as int;
      completedMap[id] = (r['is_completed'] as int? ?? 0) == 1;
    }
    return habits
        .map((h) => HabitWithTodayCount(h, countMap[h.id] ?? 0, isCompleted: completedMap[h.id] ?? false))
        .toList();
  }

  Future<Habit?> getHabitById(String id) async {
    final db = await database;
    final rows = await db.query('habits', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Habit.fromMap(rows.first);
  }

  Future<void> insertHabit(Habit habit) async {
    final db = await database;
    await db.insert('habits', habit.toMap());
  }

  Future<void> updateHabit(Habit habit) async {
    final db = await database;
    await db.update(
      'habits',
      habit.toMap(),
      where: 'id = ?',
      whereArgs: [habit.id],
    );
    final today = _dateToday();
    final log = await getLogByHabitAndDate(habit.id, today);
    final isCompleted = log?.isCompleted ?? false;
    await NotificationService().scheduleDeadlineReminderForHabit(
      habit.id,
      habit.title,
      habit.deadlineReminderTime,
      isCompletedToday: isCompleted,
    );
  }

  /// 기존 습관 sort_order를 +1 시프트 (새 습관을 맨 위에 넣기 전 호출)
  Future<void> shiftSortOrdersForInsertAtTop() async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE habits SET sort_order = sort_order + 1 WHERE is_deleted = ?',
      [0],
    );
  }

  /// 순서 변경 (habitIds 순서대로 sort_order 갱신)
  Future<void> reorderHabits(List<String> habitIds) async {
    if (habitIds.isEmpty) return;
    final now = _nowUtc();
    final db = await database;
    for (var i = 0; i < habitIds.length; i++) {
      await db.update(
        'habits',
        {'sort_order': i, 'is_dirty': 1, 'updated_at': now},
        where: 'id = ?',
        whereArgs: [habitIds[i]],
      );
    }
  }

  /// 소프트 삭제
  Future<void> deleteHabit(String id) async {
    final now = _nowUtc();
    final db = await database;
    await db.update(
      'habits',
      {'is_deleted': 1, 'is_dirty': 1, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [id],
    );
    await NotificationService().cancelDeadlineReminderForHabit(id);
  }

  Future<Habit> createHabit({
    required String title,
    int dailyTarget = 1,
    int sortOrder = 0,
    String? categoryId,
    String? deadlineReminderTime,
    String? createdAtForDummy,
  }) async {
    final now = _nowUtc();
    final created = createdAtForDummy ?? now;
    final habit = Habit(
      id: _uuid.v4(),
      title: title,
      dailyTarget: dailyTarget,
      sortOrder: sortOrder,
      categoryId: categoryId,
      deadlineReminderTime: deadlineReminderTime,
      createdAt: created,
      updatedAt: now,
    );
    await insertHabit(habit);
    if (createdAtForDummy == null) {
      await NotificationService().scheduleDeadlineReminderForHabit(
      habit.id,
      habit.title,
      habit.deadlineReminderTime,
      isCompletedToday: false,
    );
    }
    return habit;
  }

  // ========== categories ==========

  Future<List<Category>> getAllCategories() async {
    final db = await database;
    final rows = await db.query(
      'categories',
      orderBy: 'sort_order ASC',
    );
    final list = rows.map((r) => Category.fromMap(r)).toList();
    if (list.isEmpty) {
      await _initDefaultCategories(db);
      final newRows = await db.query(
        'categories',
        orderBy: 'sort_order ASC',
      );
      return newRows.map((r) => Category.fromMap(r)).toList();
    }
    return list;
  }

  /// 튜토리얼용 기본 습관 (앱 최초 설치 시에만 1회, 복구와 무관)
  /// - 물마시기 6회, 건강 카테고리, 마감 21:00
  Future<void> ensureDefaultTutorialHabit(Locale? locale) async {
    if (AppStorage.getTutorialHabitCreated()) return;

    final habits = await getAllHabits();
    if (habits.isNotEmpty) return;

    final categories = await getAllCategories();
    if (categories.isEmpty) return;
    final healthCategory = categories.first; // 건강 (sort_order 0)

    final title = _getDefaultTutorialHabitTitle(locale);
    await createHabit(
      title: title,
      dailyTarget: 6,
      sortOrder: 0,
      categoryId: healthCategory.id,
      deadlineReminderTime: '21:00',
    );
    await AppStorage.setTutorialHabitCreated();
    debugPrint('[HabitDB] 튜토리얼용 기본 습관 생성: $title');
  }

  static const Map<String, String> _defaultTutorialHabitTitlesByLocale = {
    'ko': '물마시기 (튜토리얼)',
    'en': 'Drink water (Tutorial)',
    'ja': '水を飲む（チュートリアル）',
    'zh_CN': '喝水（教程）',
    'zh_TW': '喝水（教學）',
  };

  static String _getDefaultTutorialHabitTitle(Locale? locale) {
    if (locale != null) {
      final key = locale.countryCode != null
          ? '${locale.languageCode}_${locale.countryCode}'
          : locale.languageCode;
      final title = _defaultTutorialHabitTitlesByLocale[key];
      if (title != null) return title;
    }
    return _defaultTutorialHabitTitlesByLocale['ko']!;
  }

  /// 카테고리 비어 있을 때 기본 카테고리 생성 (초기 locale 적용)
  Future<void> _initDefaultCategories(Database db) async {
    final names = _getDefaultCategoryNamesForLocale(appLocaleForInit);
    for (var i = 0; i < names.length && i < _defaultCategoryColors.length; i++) {
      final category = Category(
        id: _uuid.v4(),
        name: names[i],
        colorValue: _defaultCategoryColors[i].value,
        sortOrder: i,
      );
      await db.insert('categories', category.toMap());
    }
  }

  Future<Category?> getCategoryById(String id) async {
    final db = await database;
    final rows = await db.query('categories', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Category.fromMap(rows.first);
  }

  Future<void> insertCategory(Category category) async {
    final db = await database;
    await db.insert('categories', category.toMap());
  }

  Future<void> updateCategory(Category category) async {
    final db = await database;
    await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<void> deleteCategory(String id) async {
    final db = await database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
    // habits의 category_id를 NULL로 설정 (ON DELETE SET NULL 대체 - SQLite는 ALTER 제약)
    await db.update(
      'habits',
      {'category_id': null, 'is_dirty': 1, 'updated_at': _nowUtc()},
      where: 'category_id = ?',
      whereArgs: [id],
    );
  }

  Future<Category> createCategory({
    required String name,
    required int colorValue,
    int sortOrder = 0,
  }) async {
    final now = _nowUtc();
    final category = Category(
      id: _uuid.v4(),
      name: name,
      colorValue: colorValue,
      sortOrder: sortOrder,
    );
    await insertCategory(category);
    return category;
  }

  /// 카테고리 순서 변경
  Future<void> reorderCategories(List<String> categoryIds) async {
    if (categoryIds.isEmpty) return;
    final db = await database;
    for (var i = 0; i < categoryIds.length; i++) {
      await db.update(
        'categories',
        {'sort_order': i},
        where: 'id = ?',
        whereArgs: [categoryIds[i]],
      );
    }
  }

  // ========== habit_daily_logs ==========

  Future<HabitDailyLog?> getLogByHabitAndDate(String habitId, String date) async {
    final db = await database;
    final rows = await db.query(
      'habit_daily_logs',
      where: 'habit_id = ? AND date = ? AND is_deleted = ?',
      whereArgs: [habitId, date, 0],
    );
    if (rows.isEmpty) return null;
    return HabitDailyLog.fromMap(rows.first);
  }

  Future<List<HabitDailyLog>> getLogsByHabitId(String habitId) async {
    final db = await database;
    final rows = await db.query(
      'habit_daily_logs',
      where: 'habit_id = ? AND is_deleted = ?',
      whereArgs: [habitId, 0],
      orderBy: 'date DESC',
    );
    return rows.map((r) => HabitDailyLog.fromMap(r)).toList();
  }

  /// 날짜 범위 내 모든 습관의 일별 로그 조회 (통계/히트맵용)
  /// [startDate], [endDate]: YYYY-MM-DD
  Future<List<HabitDailyLog>> getLogsInDateRange(
    String startDate,
    String endDate,
  ) async {
    final db = await database;
    final rows = await db.query(
      'habit_daily_logs',
      where: 'date >= ? AND date <= ? AND is_deleted = ?',
      whereArgs: [startDate, endDate, 0],
      orderBy: 'date ASC',
    );
    return rows.map((r) => HabitDailyLog.fromMap(r)).toList();
  }

  /// upsert: habit_id + date 기준으로 count 갱신
  Future<void> upsertLog(String habitId, String date, int count) async {
    final now = _nowUtc();
    final db = await database;
    final existing = await getLogByHabitAndDate(habitId, date);

    if (existing != null) {
      await db.update(
        'habit_daily_logs',
        {
          'count': count,
          'is_dirty': 1,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [existing.id],
      );
    } else {
      final log = HabitDailyLog(
        id: _uuid.v4(),
        habitId: habitId,
        date: date,
        count: count,
        createdAt: now,
        updatedAt: now,
      );
      await db.insert('habit_daily_logs', log.toMap());
    }

    // habit is_dirty 갱신
    await db.update(
      'habits',
      {'is_dirty': 1, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [habitId],
    );
  }

  /// 오늘 로그 +1
  Future<void> incrementCount(String habitId) async {
    final today = _dateToday();
    final existing = await getLogByHabitAndDate(habitId, today);
    final newCount = (existing?.count ?? 0) + 1;
    await upsertLog(habitId, today, newCount);
  }

  /// 오늘 로그 -1 (0 미만 방지)
  Future<void> decrementCount(String habitId) async {
    final today = _dateToday();
    final existing = await getLogByHabitAndDate(habitId, today);
    final current = existing?.count ?? 0;
    if (current > 0) {
      await upsertLog(habitId, today, current - 1);
    }
  }

  /// 오늘 완료 토글 (count >= target일 때만)
  /// 완료 시 인앱 리뷰용 habit_achieved_count 증가
  Future<void> toggleCompleted(String habitId) async {
    final today = _dateToday();
    final existing = await getLogByHabitAndDate(habitId, today);
    if (existing == null) return;
    final habit = await getHabitById(habitId);
    if (habit == null || existing.count < habit.dailyTarget) return;
    final becomingCompleted = !existing.isCompleted;
    final now = _nowUtc();
    final db = await database;
    await db.update(
      'habit_daily_logs',
      {
        'is_completed': becomingCompleted ? 1 : 0,
        'is_dirty': 1,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [existing.id],
    );
    await db.update(
      'habits',
      {'is_dirty': 1, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [habitId],
    );
    if (becomingCompleted) {
      await AppStorage.incrementHabitAchievedCount();
      debugPrint('[Notification] 습관 완료 → 마감 예약 취소: $habitId (${habit.title})');
      await NotificationService().cancelDeadlineReminderForHabit(habitId);
    } else {
      await NotificationService().scheduleDeadlineReminderForHabit(
        habitId,
        habit.title,
        habit.deadlineReminderTime,
        isCompletedToday: false,
      );
    }
  }

  static String _dateToday() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  // ========== heatmap_daily_snapshots ==========
  // 년/전체 히트맵은 날짜별 "그날 존재했던 습관" 기준으로 달성률 계산해야 함.
  // (나중에 추가된 습관은 과거 날짜에 포함 안 함, 삭제된 습관은 삭제일 이전만 포함)

  /// 해당 날짜에 습관이 "활성"이었는지 (created_at <= date, 삭제 전)
  /// 전체 연속 달성 계산 시 해당 날짜에 존재했던 습관만 포함하기 위해 사용
  ///
  /// created_at/updated_at은 UTC ISO8601 형식이므로 로컬 날짜로 변환 후 비교
  /// (한국 UTC+9에서 오후 3시 이후 생성 시 UTC 날짜가 하루 뒤가 되는 문제 방지)
  static bool wasActiveOnDate(Habit h, String date) {
    final created = _utcToLocalDate(h.createdAt);
    if (created.compareTo(date) > 0) return false;
    if (!h.isDeleted) return true;
    final updated = _utcToLocalDate(h.updatedAt);
    return updated.compareTo(date) > 0;
  }

  /// UTC ISO8601 타임스탬프 → 로컬 YYYY-MM-DD 변환
  /// 파싱 실패 시 앞 10자(YYYY-MM-DD) 그대로 반환
  static String _utcToLocalDate(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp).toLocal();
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return timestamp.length >= 10 ? timestamp.substring(0, 10) : timestamp;
    }
  }

  /// 날짜별 달성률 계산 후 스냅샷 저장
  /// 1) 해당 날짜에 존재했던 습관(_wasActiveOnDate) 기준으로 achieved/total 계산
  /// 2) activeHabits 비어 있으면: 그날 로그가 있는 습관만 사용 (마이그레이션/백필용)
  /// 3) level: achieved/total 비율을 1~4로 매핑 (0%→0, 1~25%→1, ...)
  Future<void> computeAndSaveHeatmapSnapshot(String date) async {
    final allHabits = await getAllHabitsIncludingDeleted();
    var activeHabits = allHabits.where((h) => wasActiveOnDate(h, date)).toList();

    if (activeHabits.isEmpty) {
      final logs = await getLogsInDateRange(date, date);
      if (logs.isEmpty) return;
      final habitIds = logs.map((l) => l.habitId).toSet().toList();
      activeHabits = allHabits.where((h) => habitIds.contains(h.id)).toList();
      if (activeHabits.isEmpty) return;
    }

    final logs = await getLogsInDateRange(date, date);
    final logByHabit = {for (final l in logs) l.habitId: l};

    var achieved = 0;
    for (final h in activeHabits) {
      final log = logByHabit[h.id];
      if ((log?.count ?? 0) >= h.dailyTarget) achieved++;
    }
    final total = activeHabits.length;
    final level = total == 0
        ? 0
        : achieved == 0
            ? 0
            : ((achieved / total) * 4).ceil().clamp(1, 4);

    await upsertHeatmapSnapshot(date, achieved, total, level);
  }

  Future<void> upsertHeatmapSnapshot(String date, int achieved, int total, int level) async {
    final now = _nowUtc();
    final db = await database;
    await db.insert(
      'heatmap_daily_snapshots',
      {
        'date': date,
        'achieved': achieved,
        'total': total,
        'level': level,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getHeatmapSnapshots(String startDate, String endDate) async {
    final db = await database;
    final rows = await db.query(
      'heatmap_daily_snapshots',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date ASC',
    );
    return rows;
  }

  /// 앱 실행 시 어제까지 누락된 스냅샷 생성 (최대 365일 역순)
  /// 스냅샷이 이미 있는 날을 만나면 중단 (연속 구간만 채움)
  Future<void> ensureYesterdaySnapshot() async {
    final db = await database;
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    var d = yesterday;
    for (var i = 0; i < 365; i++) {
      final dateStr =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final rows = await db.query(
        'heatmap_daily_snapshots',
        where: 'date = ?',
        whereArgs: [dateStr],
      );
      if (rows.isNotEmpty) break;
      await computeAndSaveHeatmapSnapshot(dateStr);
      d = d.subtract(const Duration(days: 1));
    }
  }

  /// 개발용: 모든 습관 및 로그 일괄 삭제
  Future<void> deleteAllHabitsAndLogs() async {
    final db = await database;
    await db.delete('habit_daily_logs');
    await db.delete('heatmap_daily_snapshots');
    await db.delete('habits');
  }

  /// 백업 payload로 전체 복구 (트랜잭션)
  /// payload: categories, habits, logs, heatmap_snapshots, settings
  Future<void> restoreFromPayload(Map<String, dynamic> payload) async {
    final db = await database;
    final now = _nowUtc();

    await db.transaction((txn) async {
      await txn.delete('habit_daily_logs');
      await txn.delete('habits');
      await txn.delete('categories');
      await txn.delete('heatmap_daily_snapshots');

      final categories = payload['categories'] as List<dynamic>? ?? [];
      for (final c in categories) {
        final m = c as Map<String, dynamic>;
        await txn.insert('categories', {
          'id': m['id'],
          'name': m['name'],
          'color_value': m['color_value'] ?? 0xFF9E9E9E,
          'sort_order': m['sort_order'] ?? 0,
        });
      }

      final habits = payload['habits'] as List<dynamic>? ?? [];
      for (final h in habits) {
        final m = h as Map<String, dynamic>;
        await txn.insert('habits', {
          'id': m['id'],
          'title': m['title'],
          'daily_target': m['daily_target'] ?? 1,
          'sort_order': m['sort_order'] ?? 0,
          'category_id': m['category_id'],
          'deadline_reminder_time': m['deadline_reminder_time'],
          'is_active': m['is_active'] ?? 1,
          'is_deleted': m['is_deleted'] ?? 0,
          'is_dirty': m['is_dirty'] ?? 1,
          'created_at': m['created_at'],
          'updated_at': m['updated_at'],
        });
      }

      final logs = payload['logs'] as List<dynamic>? ?? [];
      for (final l in logs) {
        final m = l as Map<String, dynamic>;
        await txn.insert('habit_daily_logs', {
          'id': m['id'],
          'habit_id': m['habit_id'],
          'date': m['date'],
          'count': m['count'] ?? 0,
          'is_completed': m['is_completed'] ?? 0,
          'is_deleted': m['is_deleted'] ?? 0,
          'is_dirty': m['is_dirty'] ?? 1,
          'created_at': m['created_at'],
          'updated_at': m['updated_at'],
        });
      }

      final snapshots = payload['heatmap_snapshots'] as List<dynamic>? ?? [];
      for (final s in snapshots) {
        final m = s as Map<String, dynamic>;
        await txn.insert('heatmap_daily_snapshots', {
          'date': m['date'],
          'achieved': m['achieved'] ?? 0,
          'total': m['total'] ?? 0,
          'level': m['level'] ?? 0,
          'updated_at': now,
        });
      }
    });
  }

  /// 개발용: 현재 날짜 기준 1년 반(548일)치 더미 데이터 삽입
  /// [알고리즘] achievedPerDay: 사인파 + 노이즈로 0~nHabits 분포 생성
  /// [정책] toAchieve개 습관만 달성, 나머지는 target 미만으로 설정
  /// [정책] 카테고리: 0~9=해당 카테고리, -1=없음(미분류)
  /// [정책] 재삽입 시 결과를 고정하기 위해 기존 습관/로그/히트맵 스냅샷을 먼저 초기화
  static const int _dummyDataDays = 548; // 1.5년

  Future<void> insertDummyData() async {
    final rand = Random();
    final today = _dateToday();
    final todayDt = DateTime.parse(today);
    final db = await database;

    // 더미 재삽입 시 이전 데이터가 섞이면 "전체 연속 달성"이 0으로 깨질 수 있으므로
    // 습관/로그/스냅샷을 먼저 정리해 항상 동일한 검증 데이터셋을 만든다.
    await db.transaction((txn) async {
      await txn.delete('habit_daily_logs');
      await txn.delete('heatmap_daily_snapshots');
      await txn.delete('habits');
    });

    final categories = await getAllCategories();
    final categoryIds = categories.map((c) => c.id).toList();

    final startDate = todayDt.subtract(Duration(days: _dummyDataDays - 1));
    final createdAtStr =
        '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}T00:00:00.000Z';

    final dummyHabits = [
      ('물 8잔 마시기', 8, 0),   // 건강
      ('25분 집중 타임', 1, 1),  // 집중
      ('30분 독서', 1, 2),      // 독서
      ('10분 스트레칭', 1, 3),  // 운동
      ('명상 5분', 1, 4),      // 명상
      ('수면 7시간', 1, 5),     // 수면
      ('식단 기록', 1, 6),      // 식습관
      ('영어 단어 10개', 1, 7), // 학습
      ('그림 그리기', 1, 8),    // 취미
      ('기타 실천', 1, 9),      // 기타
      ('미분류 습관', 1, -1),   // 없음
    ];

    // 날짜별 달성 습관 수: 사인파 + 노이즈로 그라데이션
    // d=0: 오늘, d=1: 어제. 어제~5일 전(d=1~5) 전체 달성 → 연속 5일 검증용
    // d=7,8,9,10 일부 전체 달성 → 최근 7/30일 통계 검증용
    final nHabits = dummyHabits.length;
    final achievedPerDay = List<int>.generate(_dummyDataDays, (d) {
      final wave = (nHabits * 0.4 + nHabits * 0.4 * (1 + sin(d * 0.02))).round();
      final noise = rand.nextInt(3) - 1;
      var v = (wave + noise).clamp(0, nHabits);
      if (d >= 1 && d <= 5) v = nHabits; // 어제~5일 전: 전체 달성 (연속 5일)
      if (d >= 7 && d <= 10 && d % 2 == 1) v = nHabits; // 7,9일 전: 전체 달성
      return v;
    });

    final habits = <String, int>{}; // habitId -> dailyTarget
    for (var i = 0; i < dummyHabits.length; i++) {
      final (title, target, catIdx) = dummyHabits[i];
      final categoryId = catIdx >= 0 && catIdx < categoryIds.length
          ? categoryIds[catIdx]
          : null;
      final habit = await createHabit(
        title: title,
        dailyTarget: target,
        sortOrder: i,
        categoryId: categoryId,
        createdAtForDummy: createdAtStr,
      );
      habits[habit.id] = target;
    }

    final habitIds = habits.keys.toList();
    final n = habitIds.length;

    for (var d = 0; d < _dummyDataDays; d++) {
      final date = todayDt.subtract(Duration(days: d));
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final toAchieve = achievedPerDay[d].clamp(0, n);

      // toAchieve개 습관을 달성, 나머지는 미달성
      final indices = List.generate(n, (i) => i)..shuffle(rand);
      for (var i = 0; i < n; i++) {
        final habitId = habitIds[indices[i]];
        final target = habits[habitId]!;
        final count = i < toAchieve
            ? target + (rand.nextDouble() < 0.3 ? rand.nextInt(2) : 0)
            : rand.nextInt(target).clamp(0, target > 0 ? target - 1 : 0);
        await upsertLog(habitId, dateStr, count);
      }
    }

    // 히트맵 스냅샷 생성 (년/전체 뷰용)
    for (var d = 0; d < _dummyDataDays; d++) {
      final date = todayDt.subtract(Duration(days: d));
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      await computeAndSaveHeatmapSnapshot(dateStr);
    }
  }

}

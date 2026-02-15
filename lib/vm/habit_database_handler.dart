// habit_database_handler.dart
// SQLite 기반 습관 DB CRUD - docs/habit/sqlite_schema_v1.md 기반

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'package:habitcell/model/category.dart';
import 'package:habitcell/model/habit.dart';
import 'package:habitcell/model/habit_daily_log.dart';
import 'package:habitcell/util/app_locale.dart';

/// 습관 + 오늘 count + 완료 여부 (홈 화면용)
class HabitWithTodayCount {
  final Habit habit;
  final int todayCount;
  final bool isCompleted;
  const HabitWithTodayCount(this.habit, this.todayCount, {this.isCompleted = false});
}

/// 습관 앱 SQLite DB Handler
/// habits, habit_daily_logs, app_settings CRUD
class HabitDatabaseHandler {
  static Database? _db;
  static const String _dbName = 'habitcell.db';
  static const _uuid = Uuid();

  /// DB 인스턴스 (싱글톤)
  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, _dbName);
    return openDatabase(
      path,
      version: 4,
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
            reminder_time TEXT DEFAULT NULL,
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
          CREATE TABLE IF NOT EXISTS app_settings (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL,
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
      orderBy: 'sort_order ASC, updated_at DESC',
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
  }

  Future<Habit> createHabit({
    required String title,
    int dailyTarget = 1,
    int sortOrder = 0,
    String? categoryId,
    String? reminderTime,
    String? deadlineReminderTime,
  }) async {
    final now = _nowUtc();
    final habit = Habit(
      id: _uuid.v4(),
      title: title,
      dailyTarget: dailyTarget,
      sortOrder: sortOrder,
      categoryId: categoryId,
      reminderTime: reminderTime,
      deadlineReminderTime: deadlineReminderTime,
      createdAt: now,
      updatedAt: now,
    );
    await insertHabit(habit);
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
  Future<void> toggleCompleted(String habitId) async {
    final today = _dateToday();
    final existing = await getLogByHabitAndDate(habitId, today);
    if (existing == null) return;
    final habit = await getHabitById(habitId);
    if (habit == null || existing.count < habit.dailyTarget) return;
    final now = _nowUtc();
    final db = await database;
    await db.update(
      'habit_daily_logs',
      {
        'is_completed': existing.isCompleted ? 0 : 1,
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
  }

  static String _dateToday() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  // ========== app_settings ==========

  Future<String?> getSetting(String key) async {
    final db = await database;
    final rows = await db.query('app_settings', where: 'key = ?', whereArgs: [key]);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> setSetting(String key, String value) async {
    final now = _nowUtc();
    final db = await database;
    await db.insert(
      'app_settings',
      {'key': key, 'value': value, 'updated_at': now},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}

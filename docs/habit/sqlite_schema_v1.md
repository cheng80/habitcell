# SQLite 스키마 v1 (확정)

> **Local-first**: SQLite가 데이터 원본(Source of Truth). MySQL/FastAPI는 후순위.

---

## 1. 설계 원칙

- 모든 PK: UUID (TEXT)
- 소프트 삭제: `is_deleted`
- 변경 감지: `is_dirty` (백업 트리거용, 추후 활용)
- 타임스탬프: `created_at`, `updated_at` — ISO8601 문자열(UTC)
- 외래키: `PRAGMA foreign_keys = ON`

---

## 2. DDL (최종)

```sql
PRAGMA foreign_keys = ON;

-- categories: 습관 카테고리 (건강, 집중, 독서 등)
CREATE TABLE IF NOT EXISTS categories (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  color_value INTEGER NOT NULL DEFAULT 0xFF9E9E9E,
  sort_order INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX IF NOT EXISTS idx_categories_sort ON categories(sort_order);

-- habits: 습관
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
);
CREATE INDEX idx_habits_active ON habits(is_active);
CREATE INDEX idx_habits_updated ON habits(updated_at);

-- habit_daily_logs: 일별 수행 기록
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
);
CREATE UNIQUE INDEX uk_habit_date ON habit_daily_logs(habit_id, date);
CREATE INDEX idx_logs_updated ON habit_daily_logs(updated_at);

-- heatmap_daily_snapshots: 날짜별 달성률 스냅샷 (히트맵용)
CREATE TABLE IF NOT EXISTS heatmap_daily_snapshots (
  date TEXT PRIMARY KEY,
  achieved INTEGER NOT NULL DEFAULT 0,
  total INTEGER NOT NULL DEFAULT 0,
  level INTEGER NOT NULL DEFAULT 0,
  updated_at TEXT NOT NULL
);
```

---

## 3. 테이블 상세

### 3.1 categories

| 컬럼 | 타입 | 설명 |
|------|------|------|
| id | TEXT | PK, UUID |
| name | TEXT | 카테고리 이름 |
| color_value | INTEGER | 색상 값 (0xAARRGGBB) |
| sort_order | INTEGER | 정렬 순서 |

### 3.2 habits

| 컬럼 | 타입 | 설명 |
|------|------|------|
| id | TEXT | PK, UUID |
| title | TEXT | 습관 이름 |
| daily_target | INTEGER | 일일 목표 횟수 (기본 1) |
| sort_order | INTEGER | 정렬 순서 |
| category_id | TEXT | FK → categories(id), NULL = 없음 |
| deadline_reminder_time | TEXT | 마감 알림 시간 (HH:mm, nullable) |
| is_active | INTEGER | 활성 여부 (1/0) |
| is_deleted | INTEGER | 소프트 삭제 (1/0) |
| is_dirty | INTEGER | 변경 후 미백업 (1/0) |
| created_at | TEXT | 생성 시각 (ISO8601 UTC) |
| updated_at | TEXT | 수정 시각 (ISO8601 UTC) |

### 3.3 habit_daily_logs

| 컬럼 | 타입 | 설명 |
|------|------|------|
| id | TEXT | PK, UUID |
| habit_id | TEXT | FK → habits(id) |
| date | TEXT | 날짜 (YYYY-MM-DD) |
| count | INTEGER | 수행 횟수 |
| is_completed | INTEGER | 달성 여부 (count >= daily_target 시 1) |
| is_deleted | INTEGER | 소프트 삭제 (1/0) |
| is_dirty | INTEGER | 변경 후 미백업 (1/0) |
| created_at | TEXT | 생성 시각 |
| updated_at | TEXT | 수정 시각 |

- **유니크**: (habit_id, date) — 하루 1행

### 3.4 heatmap_daily_snapshots

| 컬럼 | 타입 | 설명 |
|------|------|------|
| date | TEXT | PK, 날짜 (YYYY-MM-DD) |
| achieved | INTEGER | 달성한 습관 수 |
| total | INTEGER | 해당 시점 활성 습관 수 |
| level | INTEGER | 달성률 기반 레벨 (0~4) |
| updated_at | TEXT | 수정 시각 |

- **용도**: 과거 날짜의 "해당 시점에 존재했던 습관" 기준 달성률 (히트맵 정확도)

---

## 4. 마이그레이션 (onUpgrade)

| oldVersion | 변경 |
|------------|------|
| < 2 | habit_daily_logs에 is_completed 추가 |
| < 3 | habits에 deadline_reminder_time 추가 |
| < 4 | categories 테이블 생성, habits에 category_id 추가 |
| < 5 | heatmap_daily_snapshots 테이블 생성 |
| < 6 | app_settings 테이블 삭제 (기기 설정은 AppStorage 사용, 백업 제외) |

---

## 5. 구현 참조

- Handler: `lib/vm/habit_database_handler.dart` (canonical DDL 및 마이그레이션)
- 모델: `lib/model/habit.dart`, `lib/model/habit_daily_log.dart`, `lib/model/category.dart`
- 스키마 상수: `lib/db/habit_db_schema.dart` (간략 버전, categories/heatmap 제외)

---

## 6. 기기 설정 (SQLite 외부)

- 테마, 잔디 색상, 미리 알림, 화면 꺼짐, device_uuid, 백업 관련 설정은 **AppStorage(GetStorage)**에 저장
- 백업 payload에 포함하지 않음 (기기별 설정으로 복구 시점에 새 기기 기준 적용)

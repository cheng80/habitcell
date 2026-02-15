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

-- 스키마 버전 (마이그레이션용)
-- app_settings에 schema_version=1 저장

CREATE TABLE habits (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  daily_target INTEGER NOT NULL DEFAULT 1,
  sort_order INTEGER NOT NULL DEFAULT 0,
  reminder_time TEXT DEFAULT NULL,
  is_active INTEGER NOT NULL DEFAULT 1,
  is_deleted INTEGER NOT NULL DEFAULT 0,
  is_dirty INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE INDEX idx_habits_active ON habits(is_active);
CREATE INDEX idx_habits_updated ON habits(updated_at);

CREATE TABLE habit_daily_logs (
  id TEXT PRIMARY KEY,
  habit_id TEXT NOT NULL,
  date TEXT NOT NULL,
  count INTEGER NOT NULL DEFAULT 0,
  is_deleted INTEGER NOT NULL DEFAULT 0,
  is_dirty INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (habit_id) REFERENCES habits(id) ON DELETE CASCADE
);

CREATE UNIQUE INDEX uk_habit_date ON habit_daily_logs(habit_id, date);
CREATE INDEX idx_logs_updated ON habit_daily_logs(updated_at);

CREATE TABLE app_settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
```

---

## 3. 테이블 상세

### 3.1 habits

| 컬럼 | 타입 | 설명 |
|------|------|------|
| id | TEXT | PK, UUID |
| title | TEXT | 습관 이름 |
| daily_target | INTEGER | 일일 목표 횟수 (기본 1) |
| sort_order | INTEGER | 정렬 순서 |
| reminder_time | TEXT | 리마인드 시간 (HH:mm, nullable) |
| is_active | INTEGER | 활성 여부 (1/0) |
| is_deleted | INTEGER | 소프트 삭제 (1/0) |
| is_dirty | INTEGER | 변경 후 미백업 (1/0) |
| created_at | TEXT | 생성 시각 (ISO8601 UTC) |
| updated_at | TEXT | 수정 시각 (ISO8601 UTC) |

### 3.2 habit_daily_logs

| 컬럼 | 타입 | 설명 |
|------|------|------|
| id | TEXT | PK, UUID |
| habit_id | TEXT | FK → habits(id) |
| date | TEXT | 날짜 (YYYY-MM-DD) |
| count | INTEGER | 수행 횟수 |
| is_deleted | INTEGER | 소프트 삭제 (1/0) |
| is_dirty | INTEGER | 변경 후 미백업 (1/0) |
| created_at | TEXT | 생성 시각 |
| updated_at | TEXT | 수정 시각 |

- **유니크**: (habit_id, date) — 하루 1행

### 3.3 app_settings (key-value)

| key | 용도 |
|-----|------|
| schema_version | 스키마 버전 (마이그레이션) |
| device_uuid | 기기 식별자 (백업/복구 시 사용, 추후) |
| heatmap_theme | 잔디 색상 테마 (github, ocean, sunset 등) |
| auto_backup_enabled | 자동 백업 ON/OFF |
| cooldown_minutes | 백업 쿨다운(분) |
| last_backup_at | 마지막 백업 시각 |
| deadline_reminder_enabled | 마감 알림(21:00) ON/OFF |

---

## 4. 구현 참조

- DDL: `lib/db/habit_db_schema.dart`
- Handler: `lib/vm/habit_database_handler.dart`
- 모델: `lib/model/habit.dart`, `lib/model/habit_daily_log.dart`

---

## 5. 후순위 (현재 미구현)

- MySQL 스키마 (백업 저장소)
- FastAPI (백업/복구 API)
- device_uuid, 백업 관련 app_settings — 로컬 전용 완성 후 추가

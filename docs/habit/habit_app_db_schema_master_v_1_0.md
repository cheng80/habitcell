# Habit App DB Schema Master v1.0

> **SQLite 확정 문서**: `sqlite_schema_v1.md` 참조.  
> 본 문서는 MySQL(서버 백업) 포함 전체 설계 참고용. **MySQL/FastAPI는 후순위.**

---

# 1. 아키텍처 개요

## 1.1 설계 철학

- Local-first: SQLite가 데이터 원본(Source of Truth)
- 서버(MySQL)는 최신 스냅샷 1개만 저장하는 백업 저장소
- 로그인 없음
- 이메일은 백업/복구 수단으로만 사용
- 실시간 동기화 없음
- 데이터 병합 없음 (복구는 교체 방식)

---

# 2. SQLite 스키마 (Client)

## 2.1 설계 원칙

- 모든 PK는 UUID (TEXT)
- 소프트 삭제(is\_deleted)
- 변경 감지(is\_dirty)
- updated\_at은 ISO8601 문자열(UTC)
- 외래키 사용 (PRAGMA foreign\_keys = ON)

---

## 2.2 테이블 정의

```sql
PRAGMA foreign_keys = ON;

BEGIN;

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

COMMIT;
```

---

# 3. 스냅샷 Payload 구조

백업 시 SQLite 전체 상태를 JSON으로 직렬화하여 서버에 업로드한다.

```json
{
  "schema_version": 1,
  "device_uuid": "string",
  "exported_at": "ISO8601",
  "settings": { ... },
  "habits": [ ... ],
  "logs": [ ... ]
}
```

---

# 4. MySQL 스키마 (Server Backup)

## 4.1 설계 원칙

- 최신 백업 1개만 저장
- device\_uuid 기준 관리
- 이메일은 선택 등록
- 코드 인증은 해시 저장

---

## 4.2 DDL

```sql
CREATE DATABASE IF NOT EXISTS habit_app_db
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE habit_app_db;

CREATE TABLE devices (
  device_uuid CHAR(36) PRIMARY KEY,
  email VARCHAR(255) DEFAULT NULL,
  email_verified_at DATETIME DEFAULT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE email_verifications (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  device_uuid CHAR(36) NOT NULL,
  email VARCHAR(255) NOT NULL,
  code_hash CHAR(64) NOT NULL,
  expires_at DATETIME NOT NULL,
  attempt_count INT NOT NULL DEFAULT 0,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_email(email),
  FOREIGN KEY (device_uuid) REFERENCES devices(device_uuid) ON DELETE CASCADE
);

CREATE TABLE backups (
  device_uuid CHAR(36) PRIMARY KEY,
  payload_json LONGTEXT NOT NULL,
  checksum CHAR(64) NOT NULL,
  payload_updated_at DATETIME NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (device_uuid) REFERENCES devices(device_uuid) ON DELETE CASCADE
);
```

---

# 5. Upsert 패턴 (MySQL)

```sql
INSERT INTO backups (device_uuid, payload_json, checksum, payload_updated_at)
VALUES (%s, %s, %s, %s)
ON DUPLICATE KEY UPDATE
  payload_json = VALUES(payload_json),
  checksum = VALUES(checksum),
  payload_updated_at = VALUES(payload_updated_at),
  updated_at = CURRENT_TIMESTAMP;
```

---

# 6. 복구 절차

1. 서버에서 payload 다운로드
2. SQLite 트랜잭션 시작
3. 기존 habits/logs 삭제
4. payload 데이터 재삽입
5. 트랜잭션 커밋

복구는 병합이 아닌 교체 방식이다.

---

# 7. 데이터 흐름 요약

로컬 기록 → SQLite 저장 → is\_dirty = 1 자동/수동 백업 트리거 → JSON 스냅샷 생성 → MySQL backups 업서트 복구 → MySQL 최신 payload 조회 → SQLite 교체

---

# 8. 구현 필수 체크리스트

- device\_uuid 생성 및 로컬 저장
- is\_dirty 기반 자동 백업 트리거 구현
- 백업 쿨다운 적용
- 이메일 6자리 코드 인증 구현
- payload checksum 생성
- 복구 시 덮어쓰기 경고 UX 제공

---

# 9. 향후 확장 (현재 제외)

- 백업 버전 히스토리
- 다기기 병합 동기화
- 서버 원본 구조로 승격
- FCM 기반 푸시 시스템

---

(End of Document)


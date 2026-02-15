# 습관 앱 통합 마스터 문서 v1.0 (Local-first + Snapshot Backup)

> 목적: 본 문서 **하나만** 보고도(사람/AI 모두) Flutter + SQLite + FastAPI + MySQL 기반 MVP 구현이 가능하도록, 기획/기술/DB/정책을 통합 정리한다.
>
> **SQLite 상세 스키마**: `sqlite_schema_v1.md`, `habit_app_db_schema_master_v_1_0.md` 참조.

---

## 0. 이번 통합에서의 핵심 변경점 (V2 명세 → 현재 기획)

### 폐기(또는 후순위)
- 실시간 동기화(Pull & Push) 흐름
- 소셜 로그인(Google/Firebase Auth, Apple Sign-in)
- 계정 시스템(프로필/세션/로그아웃 시 로컬 초기화 등)
- 서버를 ‘사용자 데이터 원본’으로 취급하는 구조

### 유지
- Local-first(오프라인 즉시 기록)
- UUID 기반 ID 체계
- 습관(Habit) / 일별 로그(HabitDailyLog) 중심 데이터 모델
- 히트맵(깃허브 잔디 모티브) + Streak + 기본 통계
- 로컬 알림 정책(FCM 미사용)

### 새로 확정
- **서버(MySQL)는 최신 스냅샷 1개를 저장하는 백업 저장소**
- **로그인 없음**
- **이메일은 ‘백업/복구 수단’으로만 선택 수집** (등록 시 6자리 인증)
- **수동 백업 + 자동 백업 옵션**
- 자동 백업 ON 시: “복구 시 일부 최신 데이터 유실 가능” 고지
- 복구 시: 덮어쓰기 경고 + “현재 상태 백업 후 복구” 옵션 제공

---

## 1. 개요 및 목표

### 1.1 개요
- 로컬(SQLite)에서 즉시 기록/조회가 가능한 습관 관리 앱
- 서버(FastAPI + MySQL)는 **스냅샷 백업/복구** 기능을 제공

### 1.2 목표
- 반응성: 모든 기록은 오프라인에서도 지연 없이 수행
- 안정성: 기기 변경/재설치 시 백업을 통해 복구 가능
- 단순성: 계정/동기화 없이도 바로 사용 가능
- 차별성: GitHub 잔디 히트맵 + 통계(데이터 기반 습관 분석)

---

## 2. 제품 범위 (MVP)

### 2.1 필수 기능
1) 습관 생성/편집/삭제(소프트 삭제)
2) 일별 수행 횟수 기록(+1/-1)
3) 달성 상태 판단(count >= daily_target)
4) 히트맵(월/연) + streak + 최근 7/30일 달성률
5) 로컬 알림(리마인드 + 마감 알림) 및 자동 취소
6) 수동 백업
7) 자동 백업 옵션(이벤트 기반)
8) 이메일 등록 및 6자리 인증(백업/복구 기능 이용 시)
9) 복구(스냅샷 교체) + 덮어쓰기 경고 + “현재 상태 백업 후 복구”

### 2.2 제외/비목표
- 다기기 실시간 동기화/병합
- 서버에서의 데이터 편집
- 버전 히스토리(여러 백업 버전 보관)
- 소셜 로그인/Apple 로그인

---

## 3. 인증/계정 정책 (현재 기획)

### 3.1 로그인 없음
- 앱의 사용은 로그인 없이 100% 가능

### 3.2 이메일은 선택(백업/복구 수단)
- 백업 기능을 처음 활성화할 때 이메일 입력을 요구
- 이메일 입력 즉시 6자리 코드 발송 → 인증 완료 후 이메일 등록 완료
- 이메일은 마케팅/프로필/로그인 목적 사용 금지

### 3.3 개인정보 고지
- 개인정보처리방침 URL은 iOS 필수 전제로 항상 제공
- 백업 기능 진입 시 이메일 수집 목적/범위 고지

---

## 4. 데이터 설계 및 ID 체계

### 4.1 UUID 원칙
- Habit/HabitDailyLog 등 주요 엔티티 PK는 클라이언트(UUID, CHAR(36))
- 장점: 오프라인 생성 가능, 서버 매핑 불필요

### 4.2 로컬 전용 메타
- is_dirty: 로컬 변경 후 서버 백업이 필요한 상태
- updated_at: 로컬에서 갱신(ISO8601, UTC 권장)
- is_deleted: 소프트 삭제

> 동기화는 하지 않지만, is_dirty/updated_at/is_deleted는 **자동 백업 트리거**와 **스냅샷 생성**에 유용하므로 유지한다.

---

## 5. 핵심 기능 상세

### 5.1 Category
- 필드: id(UUID), name, color_value, sort_order
- 용도: 습관 분류 (건강, 집중, 독서 등)
- habits.category_id → categories.id (NULL = 없음)

### 5.2 Habit
- 필드(권장):
  - id(UUID)
  - title
  - daily_target (int)
  - sort_order (int)
  - category_id (nullable, FK → categories)
  - deadline_reminder_time (HH:mm, nullable) — 마감 알림 시간
  - is_active, is_deleted, is_dirty
  - created_at, updated_at

- 정렬: sort_order를 저장하여 기기 변경 후에도 유지
- 삭제: is_deleted=true로 표시 후 UI에서 숨김. (물리 삭제는 선택)

### 5.3 HabitDailyLog
- 구조: habit_id + date(YYYY-MM-DD) 기준 하루 1행
- count: 수행 횟수
- 달성: count >= daily_target → is_completed=1
- 필드(권장):
  - id(UUID) 또는 복합키(habit_id,date)
  - habit_id, date, count
  - is_completed (bool) — 달성 여부
  - is_deleted, is_dirty
  - created_at, updated_at

### 5.4 히트맵/통계
- 히트맵: 날짜별 달성 여부(또는 달성 강도) 표시
- heatmap_daily_snapshots: 과거 날짜의 "해당 시점 활성 습관" 기준 달성률 (정확도 보장)
- streak: 연속 달성일 계산
- 최근 7/30일 달성률

---

## 6. 알림 정책 (로컬 알림 전용)

### 6.1 Pre-reminder
- 점심·저녁에 오늘 습관 리마인드 (Drawer 토글)

### 6.2 마감 알림(옵션)
- 습관별 deadline_reminder_time(HH:mm) 설정 시, 미달성 시 해당 시각에 알림

### 6.3 자동 취소
- 당일 목표 달성 순간, 해당 습관의 당일 예약 알림 및 마감 알림을 취소

---

## 7. 백업/복구 시스템 (스냅샷)

### 7.1 기본 원칙
- 로컬이 원본
- 서버는 최신 스냅샷 1개 저장(업서트)
- 백업 데이터는 앱이 생성한 JSON payload 1개(또는 2~3개 분리)로 저장

### 7.2 수동 백업
- 설정 > 백업에서 “지금 백업하기” 버튼
- 성공 시 “마지막 백업 시간” 표시

### 7.3 자동 백업
- 설정 토글 ON/OFF
- 트리거(이벤트 기반, 다음 중 2개 필수):
  1) 기록 완료(홈에서 +1/-1 후 확정)
  2) 앱 백그라운드 전환(pause)

- 조건:
  - is_dirty == true 일 때만 실행
  - cooldown(기본 10분) 이내 중복 실행 금지
  - 네트워크 불가 시 스킵( is_dirty 유지 )

### 7.4 유실 가능 고지(필수)
- 자동 백업 ON 시 1회 팝업:
  - “자동 백업은 특정 시점에 수행됩니다. 마지막 백업 이후의 변경은 복구 시 포함되지 않을 수 있습니다.”
- 설정 화면에 상시 1줄 표시:
  - “마지막 백업: YYYY-MM-DD HH:mm”

### 7.5 복구(스냅샷 교체)
- 서버 최신 백업을 다운로드 후 로컬 DB를 교체
- 복구 실행 직전 경고 + 선택지:
  1) 현재 상태 백업 후 복구 (수동 백업 1회 실행 후 복구)
  2) 바로 복구
  3) 취소

- “다른 기기에서 복구” 케이스:
  - 복구는 현 기기의 로컬 데이터를 덮어쓸 수 있으므로 위 선택지를 항상 제공

---

## 8. 이메일 등록(복구 수단) 플로우

### 8.1 등록 시점
- 사용자가 ‘백업 기능’을 최초로 사용하려고 할 때

### 8.2 플로우
1) 이메일 입력
2) 서버에서 6자리 코드 발송
3) 코드 입력
4) 인증 성공 시: (device_uuid ↔ email) 연결

---

## 9. 서버 기술 규격 (FastAPI + MySQL)

### 9.1 서버 목표
- 백업/복구 API 제공
- 이메일 인증(6자리)
- 업서트 기반 멱등성

### 9.2 구현 규칙
- FastAPI
- MySQL
- Upsert: INSERT ... ON DUPLICATE KEY UPDATE
- Payload는 JSON(TEXT/LONGTEXT) 저장 + checksum 저장 권장

---

## 10. API 명세 (MVP)

> 모든 요청은 device_uuid(UUID)를 기본 식별로 사용한다.

### 10.1 이메일 인증
- POST /v1/recovery/email/request
  - body: { device_uuid, email }
  - action: 6자리 코드 발송

- POST /v1/recovery/email/verify
  - body: { device_uuid, email, code }
  - action: 코드 검증 후 연결 확정

### 10.2 백업
- POST /v1/backups
  - body: { device_uuid, payload_json, checksum, client_updated_at }
  - action: 최신 백업 업서트

- GET /v1/backups/latest?device_uuid=...
  - action: 최신 백업 조회

### 10.3 복구용 조회(이메일 기반)
- GET /v1/backups/latest-by-email?email=...
  - action: 이메일로 연결된 device_uuid(또는 최신 백업) 조회
  - 주의: 악용 방지를 위해 **이메일 인증 세션(짧은 토큰)** 또는 verify 직후 한정 토큰 권장

---

## 11. MySQL 스키마 수정 방향 (기존 DDL에서의 변경 가이드)

> 사용자(user) 계정 중심 스키마는 현재 기획과 맞지 않으므로 백업 중심으로 단순화한다.

### 11.1 제거/축소 대상
- users 테이블(소셜 로그인/프로필 목적) → 제거 또는 사용 중단
- habit/habit_log를 서버 원본으로 두는 구조 → 제거 또는 백업 payload로 대체

### 11.2 신규/핵심 테이블(권장)
1) device
- device_uuid (PK)
- email (nullable)
- email_verified_at (nullable)
- created_at, updated_at

2) backup
- device_uuid (PK 또는 UNIQUE)
- payload_json (LONGTEXT)
- checksum (CHAR(64) 등)
- payload_updated_at (DATETIME)
- created_at, updated_at

3) email_verification
- email
- device_uuid
- code_hash
- expires_at
- attempt_count
- created_at

> 실제 컬럼명/타입은 업로드된 DDL 기반으로 최종 확정한다.

---

## 12. 클라이언트 저장소

### 12.1 SQLite
- categories — 습관 카테고리
- habits — 습관 (category_id, deadline_reminder_time 포함)
- habit_daily_logs — 일별 기록 (is_completed 포함)
- heatmap_daily_snapshots — 날짜별 달성률 스냅샷 (히트맵 년/전체용)

> **참고**: 기기 설정은 SQLite에 저장하지 않음. app_settings 테이블은 제거됨.

### 12.2 경량 저장소(GetStorage / AppStorage)
- theme_mode — 테마 (light/dark/system)
- heatmap_theme — 잔디 색상 테마
- pre_reminder_enabled — 미리 알림(점심·저녁) ON/OFF
- wakelock_enabled — 화면 꺼짐 방지
- device_uuid — 기기 식별자 (백업/복구)
- last_backup_at — 마지막 백업 시각
- auto_backup_enabled — 자동 백업 ON/OFF
- cooldown_minutes — 백업 쿨다운(분)

---

## 13. UI/UX (Todo와 차별화 포인트)

- 홈: 습관 리스트 + 오늘 수행 카운터(+/-) + 달성 시 즉시 시각 변화
- 분석: GitHub 잔디 히트맵(핵심 차별)
- 설정: 백업(수동/자동), 이메일 등록, 마지막 백업 시간, 복구

---

## 14. 예외 처리

- 네트워크 단절: 백업 스킵, is_dirty 유지, 다음 트리거에서 재시도
- 백업 실패: 사용자에게 비침투적 안내(토스트) + 설정 화면에서 상태 확인
- 복구 실패: 로컬 데이터 유지, 재시도 안내

---

## 15. MVP 성공 기준

- 오프라인에서 기록이 즉시 반영
- 자동 백업 토글 동작 및 고지 UX가 명확
- 복구 시 덮어쓰기 위험이 명확하게 안내되고 선택 가능
- 서버 백업을 통해 재설치/기기 변경 시 데이터 복구 가능

---

## 16. 구현 체크리스트 (개발자가 바로 실행할 수 있는 수준)

- [x] device_uuid 생성/보관(GetStorage)
- [x] SQLite 스키마 생성(습관/로그/카테고리/히트맵)
- [x] 히트맵 계산(주/월/년/전체)
- [x] 자동 백업 트리거(백그라운드 전환) + cooldown
- [x] 스냅샷 payload 생성(categories, habits, logs, heatmap_snapshots)
- [x] FastAPI: 이메일 코드 발송/검증
- [x] FastAPI: 백업 업서트/다운로드
- [x] 복구: 다운로드 → 로컬 DB 교체
- [x] 복구 UX: (현재 상태 백업 후 복구 / 바로 복구 / 취소)
- [x] 개인정보/고지: 백업 진입 시 이메일 목적 고지 + 자동 백업 고지


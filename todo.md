# TODO - Habit App 구현 항목

> docs/habit (master_habit_app_spec_v_1_0.md, habit_app_db_schema_master_v_1_0.md) 기준으로 세분화

---

## 0. 프로젝트 전환 (TagDo → Habit App)

### 0.1 앱 기본 정보
- [x] pubspec.yaml: name `habitcell`, description HabitCell
- [x] Android: applicationId `com.cheng80.habitcell`
- [x] iOS: Bundle ID `com.cheng80.habitcell`
- [x] Android: `kotlin/com/cheng80/habitcell/` 패키지 경로
- [x] README.md: HabitCell 전환 반영

### 0.2 기존 TagDo 코드 정리
- [ ] Todo/Tag 관련 코드 제거 또는 보존 결정
- [ ] Hive 관련 import/초기화 제거 (SQLite 전환 후)
- [ ] Drawer 메뉴: 태그 관리 → 습관 관리 등으로 변경

---

## 1. 데이터 레이어 (Hive → SQLite)

### 1.1 의존성
- [ ] pubspec.yaml: hive, hive_flutter 제거
- [ ] pubspec.yaml: sqflite, path 추가 (이미 있음 확인)
- [ ] path_provider 추가 (필요 시 DB 경로)

### 1.2 SQLite 스키마 생성
- [ ] `habit_app_db_schema_master_v_1_0.md` 기반 SQLite DDL 작성
- [ ] habits 테이블: id(UUID), title, daily_target, sort_order, reminder_time, is_active, is_deleted, is_dirty, created_at, updated_at
- [ ] habit_daily_logs 테이블: id, habit_id, date, count, is_deleted, is_dirty, created_at, updated_at
- [ ] app_settings 테이블: key, value, updated_at
- [ ] PRAGMA foreign_keys = ON 적용
- [ ] 인덱스 생성 (idx_habits_active, idx_habits_updated, uk_habit_date, idx_logs_updated)

### 1.3 모델 클래스
- [ ] Habit 모델 생성 (id, title, daily_target, sort_order, reminder_time, is_active, is_deleted, is_dirty, created_at, updated_at)
- [ ] HabitDailyLog 모델 생성 (id, habit_id, date, count, is_deleted, is_dirty, created_at, updated_at)
- [ ] AppSetting 모델 또는 Map<String, String> 활용

### 1.4 DB Handler
- [ ] DatabaseHandler → HabitDatabaseHandler (또는 SQLite 전용 Handler로 교체)
- [ ] habits CRUD: insert, update, delete(소프트), getAll, getById
- [ ] habit_daily_logs CRUD: upsert(habit_id, date), getByHabitAndDate, getByHabitId
- [ ] app_settings: get, set
- [ ] DB 초기화 (앱 최초 실행 시 스키마 생성)

---

## 2. Flutter - 핵심 기능

### 2.1 습관 CRUD
- [ ] 습관 생성: Habit 생성 UI + Handler.insert
- [ ] 습관 편집: title, daily_target, reminder_time, sort_order 수정
- [ ] 습관 삭제: is_deleted=true (소프트 삭제)
- [ ] 습관 목록: is_deleted=false만 조회, sort_order 정렬
- [ ] is_active 토글 (필요 시)

### 2.2 일별 기록 (+1/-1)
- [ ] 홈 화면: 습관별 오늘 카운트 표시
- [ ] +1 버튼: habit_daily_logs count 증가 (upsert)
- [ ] -1 버튼: count 감소 (0 미만 방지)
- [ ] 달성 판단: count >= daily_target 시 시각적 표시
- [ ] is_dirty 플래그: 변경 시 1로 설정

### 2.3 히트맵 (GitHub 잔디 모티브)
- [ ] 월별 히트맵 위젯
- [ ] 연간 히트맵 위젯
- [ ] 날짜별 달성 여부: count >= daily_target → 달성, 미달성 → 회색
- [ ] 색상 레벨: 미달성(회색) / 달성(테마색) / 초과 달성(더 진한 테마색)
- [ ] **잔디 색상 테마 (사용자 선택)**
  - [ ] HeatmapTheme enum: github, ocean, sunset, lavender, mint, rose, monochrome
  - [ ] HeatmapThemeColors: empty(미달성) + levels[4](달성 강도)
  - [ ] 테마별 색상 정의 (GitHub녹색, Ocean파랑, Sunset주황, Lavender보라, Mint민트, Rose로즈, Monochrome회색)
  - [ ] app_settings 또는 GetStorage: heatmap_theme 키로 저장
  - [ ] 설정 화면: "잔디 색상 테마" 선택 UI (미리보기 썸네일)
  - [ ] 다크 모드 대응: 배경/회색 톤 조정

### 2.4 Streak 및 통계
- [ ] 연속 달성일(streak) 계산 로직
- [ ] 최근 7일 달성률
- [ ] 최근 30일 달성률
- [ ] 통계 화면 또는 분석 탭

### 2.5 로컬 알림
- [ ] reminder_time: 습관별 HH:mm에 로컬 알림 예약
- [ ] 마감 알림 옵션: 미달성 습관이 있는 날 21:00 같은 고정 시각
- [ ] 달성 시 자동 취소: 당일 목표 달성 시 해당 습관 알림 + 마감 알림 취소
- [ ] flutter_local_notifications 연동 (기존 NotificationService 활용/수정)

---

## 3. Flutter - 백업/복구

### 3.1 device_uuid
- [ ] device_uuid 생성 (uuid 패키지 또는 UUID v4)
- [ ] GetStorage에 device_uuid 저장
- [ ] 앱 최초 실행 시 1회 생성

### 3.2 GetStorage 키 (경량 저장소)
- [ ] device_uuid
- [ ] last_backup_at
- [ ] last_backup_attempt_at
- [ ] auto_backup_enabled
- [ ] cooldown_minutes

### 3.3 수동 백업
- [ ] 설정 > 백업: "지금 백업하기" 버튼
- [ ] 스냅샷 payload 생성 (schema_version, device_uuid, exported_at, settings, habits, logs)
- [ ] POST /v1/backups API 호출
- [ ] 성공 시 "마지막 백업: YYYY-MM-DD HH:mm" 표시

### 3.4 자동 백업
- [ ] 설정 토글: auto_backup_enabled
- [ ] 트리거 1: 기록 완료(+1/-1 확정) 시 is_dirty==true일 때
- [ ] 트리거 2: 앱 백그라운드 전환(pause) 시
- [ ] cooldown(기본 10분) 이내 중복 실행 금지
- [ ] 네트워크 불가 시 스킵, is_dirty 유지

### 3.5 자동 백업 고지
- [ ] 자동 백업 ON 시 1회 팝업: "마지막 백업 이후 변경은 복구 시 포함되지 않을 수 있습니다"
- [ ] 설정 화면 상시: "마지막 백업: YYYY-MM-DD HH:mm"

### 3.6 이메일 등록 (6자리 인증)
- [ ] 백업 기능 최초 사용 시 이메일 입력 요구
- [ ] 이메일 입력 → POST /v1/recovery/email/request
- [ ] 6자리 코드 입력 UI
- [ ] POST /v1/recovery/email/verify
- [ ] 인증 성공 시 device↔email 연결
- [ ] 개인정보/고지: 백업 진입 시 이메일 수집 목적/범위 고지

### 3.7 복구
- [ ] GET /v1/backups/latest?device_uuid=... 호출
- [ ] payload 다운로드
- [ ] 복구 직전 경고 + 선택지:
  - [ ] 1) 현재 상태 백업 후 복구
  - [ ] 2) 바로 복구
  - [ ] 3) 취소
- [ ] SQLite 트랜잭션: 기존 habits/logs 삭제 → payload 재삽입 → 커밋

---

## 4. FastAPI 백엔드

### 4.1 MySQL 스키마
- [ ] habit_app_db 생성 (utf8mb4)
- [ ] devices 테이블
- [ ] email_verifications 테이블
- [ ] backups 테이블
- [ ] mysql/habit_app_db_init.sql 파일 생성

### 4.2 DB 연결
- [ ] connection.py: habit_app_db, .env 기반 설정
- [ ] .env.example: DB_HOST, DB_USER, DB_PASSWORD, DB_NAME

### 4.3 이메일 인증 API
- [ ] app/api/recovery.py 생성
- [ ] POST /v1/recovery/email/request: 6자리 코드 생성, code_hash 저장, 이메일 발송
- [ ] POST /v1/recovery/email/verify: code_hash 비교, devices.email 업데이트
- [ ] email_service.py: send_verification_code (Habit App용)

### 4.4 백업 API
- [ ] app/api/backups.py 생성
- [ ] POST /v1/backups: payload 업서트 (ON DUPLICATE KEY UPDATE)
- [ ] GET /v1/backups/latest?device_uuid=...: 최신 백업 조회

### 4.5 main.py
- [ ] recovery, backups 라우터 등록  
- [ ] (이미 Habit App API로 변경됨)

---

## 5. UI/설정

### 5.1 홈 화면
- [ ] 습관 리스트 (sort_order 정렬)
- [ ] 오늘 수행 카운터 (+1/-1)
- [ ] 달성 시 즉시 시각 변화 (색상/체크 등)

### 5.2 분석 화면
- [ ] 히트맵 (월/연)
- [ ] Streak 표시
- [ ] 최근 7/30일 달성률

### 5.3 설정 화면
- [ ] 백업: 수동/자동, 이메일 등록, 마지막 백업 시간
- [ ] 복구 버튼
- [ ] 테마 (라이트/다크) - 기존 유지
- [ ] 다국어 - 기존 유지
- [ ] Drawer 구조: 습관관리, 설정, 백업, 언어, 테마 등

### 5.4 습관 편집
- [ ] title, daily_target, reminder_time 입력
- [ ] sort_order 변경 (드래그 등)

---

## 6. 기존 TagDo 기능 검토

### 6.1 유지 (습관앱에 맞게 수정)
- [ ] 테마 시스템 (ThemeNotifier, CommonColorScheme)
- [ ] 다국어 (easy_localization)
- [ ] 로컬 알림 (NotificationService, flutter_local_notifications)
- [ ] 앱 아이콘/스플래시
- [ ] Drawer 구조
- [ ] MVVM 패턴 (Handler, Notifier)

### 6.2 제거 또는 대체
- [ ] Todo 모델 → Habit 모델
- [ ] Tag 모델 → (습관앱에 태그 없음, 제거 또는 다른 용도)
- [ ] Hive → SQLite
- [ ] TodoListNotifier → HabitListNotifier
- [ ] TagHandler, TagListNotifier → (제거 또는 습관 카테고리로 전환)

### 6.3 수정/마이그레이션
- [ ] AppStorage: tutorial_completed 등 → habit_app용 키로 정리
- [ ] InAppReviewService: todo_completed_count → habit 관련 지표로 변경
- [ ] 번역 파일: Todo 관련 → Habit 관련 문자열

---

## 7. 출시 준비

- [ ] [docs/RELEASE_CHECKLIST.md](docs/RELEASE_CHECKLIST.md) 참고
- [ ] Bundle ID / applicationId: habit_app 최종 확정
- [ ] 카테고리: 생산성 또는 건강/피트니스
- [ ] 개인정보처리방침 URL (iOS 필수)

---

## 8. FastAPI 폴더 정리 (완료된 항목)

- [x] Table Now API 라우터 9개 삭제
- [x] weather, fcm, weather_mapping 유틸 삭제
- [x] main_gt.py, test_*.py 삭제
- [x] mysql/ table_now 관련 삭제
- [x] main.py: Habit App API로 변경
- [x] requirements.txt: firebase-admin, pycryptodome, requests 제거

---

## 9. docs/email 문서 (완료된 항목)

- [x] 인증_토큰과_인증코드_설명.md → 습관앱 이메일 인증용 갱신
- [x] 이메일_서비스_설정_가이드.md → Habit App으로 갱신
- [x] 이메일_등록_인증_구현_가이드.md 신규 작성
- [x] 비밀번호_변경_이메일_인증_구현_가이드.md 삭제

---

## 10. 수정 필요 사항 (검토)

### 10.1 pubspec.yaml
- [ ] hive, hive_flutter 제거
- [ ] flutter_colorpicker: 태그 색상용 → 습관앱에서 사용 여부 결정
- [ ] showcaseview: 튜토리얼 → 습관앱 온보딩으로 수정
- [ ] in_app_review: habit 관련 지표로 조건 변경

### 10.2 기존 문서
- [x] README.md: HabitCell 반영
- [ ] CURSOR.md: 그대로 유지 (작업 방식, MVVM 등)
- [ ] docs/RELEASE_CHECKLIST.md: habit_app 전용 항목 추가

### 10.3 테스트
- [ ] widget_test.dart: Todo → Habit 테스트로 수정
- [ ] 통합 테스트 (SQLite, 백업/복구, 이메일 인증)

---

## 참고 문서

- [docs/habit/master_habit_app_spec_v_1_0.md](docs/habit/master_habit_app_spec_v_1_0.md)
- [docs/habit/habit_app_db_schema_master_v_1_0.md](docs/habit/habit_app_db_schema_master_v_1_0.md)
- [docs/email/이메일_등록_인증_구현_가이드.md](docs/email/이메일_등록_인증_구현_가이드.md)

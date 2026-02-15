# TODO - Habit App 구현 항목

> docs/habit (master_habit_app_spec_v_1_0.md, **sqlite_schema_v1.md**) 기준  
> SQLite 로컬 우선. MySQL/FastAPI 후순위.

---

## 최근 완료 (2026-02)

- 히트맵: 주/월/년/전체 뷰, 기간 필터, 왼쪽 정렬, 데이터 있는 월만 표시
- 잔디 테마: 7종 선택, Drawer 설정
- 홈 필터: 결과 없을 때도 날짜·필터 버튼 유지
- Drawer 스낵바: showOverlaySnackBar로 드로어 위에 표시
- 통계: 전체/습관별 카드, 카테고리 색상, 없음=회색

---

## 프로젝트 규칙

### 번역 (i18n)
- **번역은 UI가 안정화되었을 때 일괄 작업한다.**
- 개발 중에 번역 키를 미리 삽입하면 수정 사항이 늘어날 수 있음.

---

## 진행 순서

| 단계 | 섹션 | 내용 | 상태 |
|------|------|------|------|
| 1 | 0 | 프로젝트 전환 (HabitCell) | ✅ 완료 |
| 2 | 1 | 데이터 레이어 (Hive → SQLite) | ✅ 완료 |
| 3 | 6.2 + 0.2 | Todo/Tag 제거, Hive 제거 | ✅ 완료 |
| 4 | 2 | Flutter 핵심 (습관 CRUD, +1/-1) | ✅ 완료 |
| 5 | 5 | UI (홈, 분석, 설정) | ✅ 기본 골격 완료 |
| 6 | 2.3 | 히트맵 + 잔디 테마 | ✅ 기본 완료 |
| 7 | 2.5, 3, 4 | 알림, 백업/복구, FastAPI | 🔄 다음 |

---

## 0. 프로젝트 전환 (TagDo → Habit App)

### 0.1 앱 기본 정보
- [x] pubspec.yaml: name `habitcell`, description HabitCell
- [x] Android: applicationId `com.cheng80.habitcell`
- [x] iOS: Bundle ID `com.cheng80.habitcell`
- [x] Android: `kotlin/com/cheng80/habitcell/` 패키지 경로
- [x] README.md: HabitCell 전환 반영

### 0.2 기존 TagDo 코드 정리
- [x] Todo/Tag 관련 코드 제거
- [x] Hive 관련 import/초기화 제거
- [x] Drawer 메뉴: 습관 관리 → 카테고리 관리로 변경

---

## 1. 데이터 레이어 (Hive → SQLite)

### 1.1 의존성
- [x] pubspec.yaml: hive, hive_flutter 제거
- [x] pubspec.yaml: sqflite, path 유지
- [x] path_provider, uuid 추가

### 1.2 SQLite 스키마 생성
- [x] `sqlite_schema_v1.md` 확정 스키마 (lib/db/habit_db_schema.dart)
- [x] habits 테이블
- [x] habit_daily_logs 테이블
- [x] categories 테이블 (id, name, color_value, sort_order)
- [x] habits.category_id (FK → categories)
- [x] app_settings 테이블
- [x] PRAGMA foreign_keys = ON, 인덱스 생성

### 1.3 모델 클래스
- [x] Habit 모델 (lib/model/habit.dart)
- [x] HabitDailyLog 모델 (lib/model/habit_daily_log.dart)
- [x] Category 모델 (lib/model/category.dart)
- [x] app_settings: getSetting/setSetting (Map 대신 Handler 메서드)

### 1.4 DB Handler
- [x] HabitDatabaseHandler (lib/vm/habit_database_handler.dart) - SQLite 전용
- [x] habits CRUD: insert, update, delete(소프트), getAll, getById, createHabit
- [x] categories CRUD: insert, update, delete, getAll, getById, createCategory
- [x] habit_daily_logs: upsert, getLogByHabitAndDate, getLogsByHabitId, incrementCount, decrementCount
- [x] app_settings: getSetting, setSetting
- [x] DB 초기화 (onCreate에서 스키마 생성)

---

## 2. Flutter - 핵심 기능

### 2.1 습관 CRUD
- [x] 습관 생성: HabitEditSheet + Handler.createHabit
- [x] 습관 편집: title, daily_target 수정
- [x] 습관 삭제: is_deleted=true (소프트 삭제)
- [x] 습관 목록: is_deleted=false만 조회, sort_order 정렬
- [x] sort_order: 카드 오른쪽 드래그 핸들로 순서 변경
- [ ] reminder_time (추후)

### 2.2 일별 기록 (+1/-1)
- [x] 홈 화면: 습관별 오늘 카운트 표시
- [x] +1 버튼: habit_daily_logs count 증가 (upsert)
- [x] -1 버튼: count 감소 (0 미만 방지)
- [x] 달성 판단: count >= daily_target 시 시각적 표시
- [x] 완료 토글: count >= target 시 완료 버튼 표시, 토글 시 맨 아래로 이동
- [x] is_dirty 플래그: 변경 시 1로 설정

### 2.3 히트맵 (GitHub 잔디 모티브)
- [x] 주별 히트맵 위젯 (7개 셀 1행, 최대 175px)
- [x] 월별 히트맵 위젯 (달력형 7×5, 최대 210px)
- [x] 연간 히트맵 위젯 (데이터 있는 월만 표시, 3열 그리드, 왼쪽 정렬)
- [x] 전체 뷰 (년 단위 블록, 데이터 있는 월만 표시)
- [x] 날짜별 달성 여부: count >= daily_target → 달성, 미달성 → 회색
- [x] 색상 레벨: HSL 기반 4단계 (levelColorsFromBase)
- [x] **잔디 색상 테마 (사용자 선택)**
  - [x] HeatmapTheme enum: github, ocean, sunset, lavender, mint, rose, monochrome
  - [x] HeatmapThemeColors: empty(미달성) + levels[4](달성 강도)
  - [x] 테마별 색상 정의
  - [x] GetStorage: heatmap_theme 키로 저장
  - [x] Drawer: "잔디 색상 테마" 선택 UI (미리보기 썸네일)
  - [x] 다크 모드 대응

### 2.4 Streak 및 통계
- [x] 연속 달성일(streak) 계산 로직 (HabitStats, OverallStats)
- [x] 최근 7일 달성일 (achieved7)
- [x] 최근 30일 달성일 (achieved30)
- [x] 분석 탭: 전체/습관별 통계 카드 표시

### 2.5 로컬 알림
- [ ] reminder_time: 습관별 HH:mm에 로컬 알림 예약
- [x] 마감 알림: 습관별 사용자 지정 시간 (deadline_reminder_time, HH:mm)
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
- [x] 습관 리스트 (sort_order 정렬)
- [x] 오늘 수행 카운터 (+1/-1)
- [x] 달성 시 즉시 시각 변화 (색상)
- [x] 카테고리 바 (윈도우바 스타일: 상단 색상+이름)
- [x] 필터 (전체/완료/미완료): 결과 없을 때도 날짜·필터 버튼 유지

### 5.2 분석 화면
- [x] 기본 골격 (플레이스홀더)
- [x] 히트맵 (주/월/년/전체, 기간 필터)
- [x] 전체 통계 카드 (카테고리별, 없음=회색)
- [x] 습관별 통계 (달성일·연속일, 7/30일 달성률)

### 5.3 설정 화면
- [ ] 백업: 수동/자동, 이메일 등록, 마지막 백업 시간
- [ ] 복구 버튼
- [x] 테마 (라이트/다크) - Drawer
- [x] 다국어 - Drawer
- [x] Drawer: 카테고리 관리, 다크모드, 화면꺼짐, 미리 알림, 언어, 평점
- [x] Drawer 스낵바: showOverlaySnackBar로 드로어 위에 표시

### 5.4 습관 편집
- [x] title (maxLength 30, 글자수 표시), daily_target 입력
- [x] 카테고리 선택 (5열 그리드, 프리셋+전체 색상)
- [ ] reminder_time (추후)

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
- [x] Todo 모델 → Habit 모델
- [x] Tag 모델 → Category 모델 (기본 카테고리: 건강, 집중, 독서 등)
- [x] Hive → SQLite
- [x] TodoListNotifier → HabitListNotifier
- [x] TagHandler, TagListNotifier → CategoryListNotifier

### 6.3 수정/마이그레이션
- [ ] AppStorage: tutorial_completed 등 → habit_app용 키로 정리
- [ ] InAppReviewService: todo_completed_count → habit 관련 지표로 변경
- [ ] 번역 파일: Todo 관련 → Habit 관련 문자열

---

## 7. 출시 준비

- [ ] [docs/RELEASE_CHECKLIST.md](docs/RELEASE_CHECKLIST.md) 참고
- [x] Bundle ID / applicationId: com.cheng80.habitcell 확정
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
- [x] hive, hive_flutter 제거
- [x] flutter_colorpicker: 카테고리 색상 선택용
- [ ] showcaseview: 튜토리얼 → 습관앱 온보딩으로 수정
- [ ] in_app_review: habit 관련 지표로 조건 변경

### 10.2 기존 문서
- [x] README.md: HabitCell 반영
- [x] CURSOR.md: 그대로 유지 (작업 방식, MVVM 등)
- [x] docs/RELEASE_CHECKLIST.md: HabitCell 전용 항목 반영

### 10.3 테스트
- [ ] widget_test.dart: Todo → Habit 테스트로 수정
- [ ] 통합 테스트 (SQLite, 백업/복구, 이메일 인증)

---

## 참고 문서

- [docs/habit/master_habit_app_spec_v_1_0.md](docs/habit/master_habit_app_spec_v_1_0.md)
- [docs/habit/habit_app_db_schema_master_v_1_0.md](docs/habit/habit_app_db_schema_master_v_1_0.md)
- [docs/email/이메일_등록_인증_구현_가이드.md](docs/email/이메일_등록_인증_구현_가이드.md)

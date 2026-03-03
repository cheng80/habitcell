# HabitCell

습관 추적 앱. 일별 기록(+1/-1), 히트맵(잔디 스타일), Streak, 카테고리별 통계를 지원한다.

> **구현 계획**: [docs/PLAN_BASIC_STRUCTURE.md](docs/PLAN_BASIC_STRUCTURE.md)  
> **코딩 규칙**: [CURSOR.md](CURSOR.md)

---

## 대표 이미지

| 메인 화면 | 카테고리 관리 | 습관 분석 |
|:---------:|:---------:|:---------:|
| ![메인](docs/screenshots/iPhone/ko/iPhone_01.png) | ![카테고리 관리](docs/screenshots/iPhone/ko/iPhone_02.png) | ![습관 분석](docs/screenshots/iPhone/ko/iPhone_03.png) |

---

## 제품 정의

| 항목 | 내용 |
|------|------|
| **한 줄 정의** | 습관 추적 앱. 일별 기록, 히트맵, Streak, 카테고리별 통계 |
| **대상** | 개인 습관 관리, 일일 목표 추적 |
| **핵심 가치** | Local-first, 미니멀 UX, 히트맵 시각화, 백업/복구 |

---

## 주요 기능 (MVP)

| 기능 | 설명 |
|------|------|
| 습관 CRUD | 제목, 일일 목표(daily_target), 카테고리, 마감 알림 시간 |
| 일별 기록 | +1/-1 버튼으로 오늘 카운트, 목표 달성 시 시각 표시 |
| 필터 | 전체/완료/미완료, 결과 없어도 날짜·필터 버튼 유지 |
| 순서 변경 | "전체" 필터에서 드래그로 리스트 정렬 |
| 히트맵 | 주/월/년/전체 기간, 잔디 색상 테마 7종 |
| 통계 | 전체/습관별 Streak, 최근 7일/30일 달성일 |
| 카테고리 | 10종 기본 + 커스터마이징, 색상 선택 |
| 백업/복구 | Local-first + FastAPI 스냅샷 백업, 이메일 인증 복구 |
| 테마 | 라이트/다크/시스템, 영속화 |
| 다국어 | ko, en, ja, zh-CN, zh-TW |

---

## 기술 스택

| 구분 | 기술 | 용도 |
|------|------|------|
| 프론트엔드 | Flutter | iOS/Android |
| 상태 관리 | Riverpod | 비동기 데이터, 테마, 필터, 히트맵 |
| 로컬 DB | SQLite (sqflite) | habits, habit_daily_logs, categories, heatmap_daily_snapshots |
| 설정 | GetStorage | 테마·언어·잔디 테마·화면꺼짐 |
| 다국어 | easy_localization | 5개 언어 |
| 알림 | flutter_local_notifications | 마감 알람, 앱 아이콘 배지 |
| 백엔드(선택) | FastAPI + MySQL | 백업/복구, 이메일 인증 |
| UI | Material + ConfigUI | 플랫/미니멀, Soft UI |

---

## 아키텍처

**MVVM + Handler/Notifier**

```
lib/
├── main.dart
├── model/       # Habit, Category, HabitDailyLog, HabitStats
├── view/        # habit_home, analysis_screen, app_drawer, habit_item, sheets, widgets
├── vm/          # Handler(DB), Notifier(Riverpod)
├── service/     # NotificationService, InAppReviewService, BackupService
├── theme/       # ColorScheme, ConfigUI, palette
├── util/        # 공통 유틸, locale, date_util
└── db/          # 스키마 정의 (habit_db_schema)
```

```
fastapi/app/     # 백업/복구용 (선택)
├── main.py
├── api/         # backups, recovery
├── database/
└── utils/       # email_service
```

- **Handler**: SQLite CRUD 전담 (HabitDatabaseHandler)
- **Notifier**: Riverpod 상태 관리
- **View**: UI만, `ref.watch`/`ref.read`로 상태 구독·액션 호출

---

## 실행

### 1. Flutter 앱

```bash
flutter pub get
flutter run
```

**우선 기기**: iOS 시뮬레이터 (Debug 모드)

### 2. FastAPI 백엔드 (백업/복구용, 선택)

```bash
cd fastapi
python -m venv venv
source venv/bin/activate   # Windows: venv\Scripts\activate
pip install -r requirements.txt
# .env 설정 후
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

상세: [fastapi/API_GUIDE.md](fastapi/API_GUIDE.md)

---

## 버전 관리

앱 버전은 `pubspec.yaml`의 `version`에서 관리한다. (상세: [docs/DRAWER_AND_VERSION_GUIDE.md](docs/DRAWER_AND_VERSION_GUIDE.md))

```yaml
version: 1.0.1+3   # 1.0.1 = 버전명, +3 = 빌드 번호(versionCode)
```

**빌드 시 오버라이드**:
```bash
flutter build apk --build-name=1.0.1 --build-number=3
flutter build ios --build-name=1.0.1 --build-number=3
```

---

## 문서

| 문서 | 설명 |
|------|------|
| [docs/PLAN_BASIC_STRUCTURE.md](docs/PLAN_BASIC_STRUCTURE.md) | 구현 계획 |
| [fastapi/API_GUIDE.md](fastapi/API_GUIDE.md) | FastAPI 백업/복구 API |
| [docs/RELEASE_BUILD.md](docs/RELEASE_BUILD.md) | 릴리즈 빌드 절차 |
| [docs/RELEASE_CHECKLIST.md](docs/RELEASE_CHECKLIST.md) | 앱 스토어 출시 체크리스트 |
| [docs/DRAWER_AND_VERSION_GUIDE.md](docs/DRAWER_AND_VERSION_GUIDE.md) | Drawer, 버전 표시 |
| [docs/TUTORIAL_SHOWCASEVIEW_GUIDE.md](docs/TUTORIAL_SHOWCASEVIEW_GUIDE.md) | 튜토리얼 화면 |
| [docs/NOTIFICATION_SETUP.md](docs/NOTIFICATION_SETUP.md) | 알림 설정 |

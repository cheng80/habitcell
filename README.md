# HabitCell

습관 추적 앱. 일별 기록(+1/-1), 히트맵(잔디 스타일), Streak, 카테고리별 통계를 지원한다.

---

## 주요 기능

| 기능 | 설명 |
|------|------|
| 습관 CRUD | 제목, 일일 목표(daily_target), 카테고리, 마감 알림 시간 |
| 일별 기록 | +1/-1 버튼으로 오늘 카운트, 목표 달성 시 시각 표시 |
| 필터 | 전체/완료/미완료, 결과 없어도 날짜·필터 버튼 유지 |
| 순서 변경 | "전체" 필터에서 드래그로 리스트 정렬 |
| 히트맵 | 주/월/년/전체 기간, 잔디 색상 테마 7종 (GitHub, Ocean, Sunset 등) |
| 통계 | 전체/습관별 Streak, 최근 7일/30일 달성일 |
| 카테고리 | 10종 기본 + 커스터마이징, 색상 선택 |
| 테마 | 라이트/다크/시스템, 영속화 |
| 다국어 | ko, en, ja, zh-CN, zh-TW |

---

## 기술 스택

| 구분 | 기술 | 용도 |
|------|------|------|
| 상태 관리 | Riverpod | 비동기 데이터, 테마, 필터, 히트맵 기간 |
| 로컬 DB | SQLite (sqflite) | habits, habit_daily_logs, categories, heatmap_daily_snapshots |
| 설정 | GetStorage | 테마·언어·잔디 테마·화면꺼짐·미리 알림 |
| 다국어 | easy_localization | 5개 언어, locale 기반 |
| 알림 | flutter_local_notifications | 마감 알람, 앱 아이콘 배지 |
| UI | Material + ConfigUI | 플랫/미니멀, Soft UI, 접근성 |

---

## 사용 패키지

| 패키지 | 용도 |
|--------|------|
| **상태·UI** | |
| flutter_riverpod | 상태 관리 (습관, 통계, 히트맵, 테마) |
| flutter_colorpicker | 카테고리 색상 선택 |
| **로컬 저장소** | |
| sqflite, path, path_provider, uuid | SQLite DB, 습관 ID |
| get_storage | 경량 설정 (테마, 잔디 테마, wakelock 등) |
| **알림·배지** | |
| flutter_local_notifications | 마감 알람 |
| timezone | 알람 타임존 (Asia/Seoul) |
| app_badge_plus | 앱 아이콘 배지 |
| **다국어** | |
| easy_localization | 5개 언어 |
| intl | 날짜 포맷 |
| **기타** | |
| permission_handler | 알림 권한 |
| showcaseview | 튜토리얼 (예정) |
| in_app_review | 스토어 평점 |
| wakelock_plus | 화면 꺼짐 방지 |
| flutter_native_splash | 스플래시 |

<details>
<summary>dev_dependencies</summary>

| 패키지 | 용도 |
|--------|------|
| flutter_lints | 린트 규칙 |
| flutter_launcher_icons | 앱 아이콘 생성 |

</details>

---

## 아키텍처

**MVVM + 레이어 분리**

```
lib/
├── model/      # Habit, Category, HabitDailyLog, HabitStats, DayAchievement
├── view/       # UI (habit_home, analysis_screen, app_drawer, habit_item, sheets, widgets)
├── vm/         # 비즈니스 로직·상태
│   ├── *Handler   → DB 접근 (HabitDatabaseHandler)
│   └── *Notifier  → Riverpod (HabitListNotifier, HeatmapDataProvider 등)
├── service/    # NotificationService, InAppReviewService
├── theme/      # ColorScheme, ConfigUI, palette
├── util/       # 공통 유틸, locale, date_util
└── db/         # 스키마 정의 (habit_db_schema)

assets/
└── translations/   # 다국어 JSON (ko, en, ja, zh-CN, zh-TW)
```

- **View**: UI 렌더링만. `ref.watch`로 상태 구독, `ref.read`로 액션 호출
- **Handler**: SQLite CRUD 전담
- **Notifier**: Riverpod AsyncNotifier/Notifier. `ref.invalidateSelf()`로 재로딩
- **테마**: `CommonColorScheme` + `context.palette` + `ConfigUI` (반경, 패딩, 폰트)
- **다국어**: `easy_localization` + `assets/translations/`. Drawer에서 언어 선택

---

## 실행

```bash
flutter pub get
flutter run
```

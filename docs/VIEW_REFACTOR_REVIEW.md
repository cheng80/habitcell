# View 파일 분리 검토

> backup_settings.dart 정리 후, 다른 view들 중 분리 가능한 화면 검토 결과

## 요약

| 파일 | 라인 | 우선순위 | 분리 권장 |
|------|------|----------|-----------|
| app_drawer.dart | 633 | 높음 | ✅ |
| category_settings.dart | 413 | 중간 | ✅ |
| analysis_screen.dart | 421 | 중간 | ✅ |
| habit_home.dart | 414 | 낮음 | △ |
| habit_item.dart | 379 | 낮음 | △ |
| habit_edit_sheet.dart | 384 | 낮음 | △ |
| main_scaffold.dart | 171 | - | ❌ 적정 |
| habit_heatmap.dart | 489 | - | ❌ 이미 위젯 |

---

## 1. app_drawer.dart (633줄) — **우선 분리 권장**

### 현재 구조
- `AppDrawer` (ConsumerStatefulWidget)
- `_onInsertDummyData`, `_onDeleteAllData` — 유사한 다이얼로그+로딩 패턴 (~80줄×2)
- `_onAlarmStatusCheck` — 알람 상태 조회 (~55줄)
- `_showHeatmapThemePicker` — top-level 함수 (~95줄)
- `_showLanguagePicker` — top-level 함수 (~40줄)
- `_langTile` — top-level 함수 (~15줄)

### 분리 제안

| 분리 대상 | 새 파일 | 설명 |
|-----------|---------|------|
| `_showHeatmapThemePicker` | `view/widgets/heatmap_theme_picker_sheet.dart` | 잔디 테마 선택 바텀시트 |
| `_showLanguagePicker` + `_langTile` | `view/widgets/language_picker_sheet.dart` | 다국어 선택 바텀시트 |
| 로딩 다이얼로그 패턴 | `view/widgets/loading_overlay.dart` | 공통 로딩 오버레이 (선택) |
| 개발용 버튼 섹션 | `view/widgets/drawer_dev_section.dart` | 더미/삭제 ListTile 그룹 (선택) |

---

## 2. category_settings.dart (413줄)

### 현재 구조
- `CategorySettings` (ConsumerWidget)
- `_CategoryTile` — private StatelessWidget (~55줄)
- `_CategoryEditorSheet` — private StatefulWidget (~215줄)

### 분리 제안

| 분리 대상 | 새 파일 | 설명 |
|-----------|---------|------|
| `_CategoryTile` | `view/widgets/category_tile.dart` | 카테고리 목록 타일 |
| `_CategoryEditorSheet` | `view/sheets/category_editor_sheet.dart` | 카테고리 추가/수정 시트 |

---

## 3. analysis_screen.dart (421줄)

### 현재 구조
- `AnalysisScreen` (ConsumerWidget)
- `_buildOverallStats` — top-level 함수 (~65줄)
- `_StatItem` — private StatelessWidget (~35줄)
- `_buildStatsCards` — top-level 함수 (~75줄)
- `_buildHeatmap` — top-level 함수 (~45줄)
- `_HeatmapRangeFilter` — private StatelessWidget (~55줄)
- `_buildEmptyState` — top-level 함수 (~25줄)

### 분리 제안

| 분리 대상 | 새 파일 | 설명 |
|-----------|---------|------|
| `_buildOverallStats` + `_StatItem` | `view/widgets/analysis/overall_stats_card.dart` | 전체 통계 카드 |
| `_buildStatsCards` | `view/widgets/analysis/stats_per_habit_cards.dart` | 습관별 통계 카드 |
| `_HeatmapRangeFilter` | `view/widgets/analysis/heatmap_range_filter.dart` | 기간 필터 칩 |
| `_buildHeatmap` | `view/widgets/analysis/analysis_heatmap_section.dart` | 분석 탭 히트맵 섹션 (선택) |

---

## 4. habit_home.dart (414줄)

### 현재 구조
- `HabitHome` (ConsumerStatefulWidget)
- `_FilterChip` — private 위젯
- `_buildFilteredEmptyState`, `_buildDragProxyDecorator` — build 내부/private

### 분리 제안
- `_FilterChip` → `view/widgets/filter_chip.dart` (재사용 가능 시)
- 나머지는 `HabitHome` 내부 유지해도 무방 (복잡도 낮음)

---

## 5. habit_item.dart (379줄)

### 현재 구조
- `HabitItem` (ConsumerWidget)
- `_CellGrid` — private 위젯 (6열 그리드, +1/-1)
- `_buildCategoryBar`, `_buildHeaderRow`, `_buildCountRow` — private 메서드

### 분리 제안
- `_CellGrid` → `view/widgets/habit_cell_grid.dart` (독립 위젯으로 분리 시 테스트/재사용 용이)
- 나머지는 `HabitItem`에 두어도 됨

---

## 6. habit_edit_sheet.dart (384줄)

### 현재 구조
- `HabitEditSheet` (ConsumerStatefulWidget)
- `_DeadlineTimePickerSheet` — private 위젯 (Cupertino 타임 피커)
- 이미 `edit_sheet_category_selector.dart`로 카테고리 선택 분리됨

### 분리 제안
- `_DeadlineTimePickerSheet` → `view/widgets/deadline_time_picker_sheet.dart` (재사용 가능 시)

---

## 권장 작업 순서

1. **app_drawer.dart** — 가장 길고, 바텀시트 2개가 top-level로 분리 가능
2. **category_settings.dart** — `_CategoryEditorSheet`가 200줄 이상으로 분리 이득 큼
3. **analysis_screen.dart** — 위젯/함수 단위로 깔끔히 분리 가능

---

## 참고: backup_settings.dart 분리 결과

- `RestoreOptionCard` → `widgets/restore_option_card.dart`
- `EmailRegistrationCard` → `widgets/email_registration_card.dart`
- `ServerBackupStatusCard` → `widgets/server_backup_status_card.dart`
- `backup_settings.dart`: 1039줄 → 604줄

# TODO - 추가 구현 항목

## 기능 추가

- [x] **튜토리얼 / 온보딩 (showcaseview ^5.0.1)**
  - [x] 1단계: GetStorage에 `tutorial_completed` 플래그 추가
    - `AppStorage`: getTutorialCompleted, setTutorialCompleted, resetTutorialCompleted
  - [x] 2단계: Home 화면에 ShowcaseView 래핑
    - `ShowcaseView.register()` + `startShowCase()` (addPostFrameCallback)
    - GlobalKey 6개: tagManage, drawer, search, add, filter, firstTodo
  - [x] 3단계: 스포트라이트 대상 정의 및 순서
    - 1) 태그 관리 → Drawer 내 태그 관리 버튼
    - 2) 햄버거 메뉴 → 메뉴 열기, 태그 관리·언어·테마
    - 3) 검색 버튼 → 할 일 검색
    - 4) + 버튼 → 새 할 일 추가
    - 5) 필터 칩 (전체/미완료/완료) → 목록 필터
    - 6) 첫 할 일 항목 → 체크박스, 태그, 드래그 핸들, 마감일
  - [x] 4단계: 다국어 문자열 추가
    - tutorial_skip, tutorial_next, tutorial_step_1~6, tutorial_replay (ko, en, ja, zh-CN, zh-TW)
  - [x] 5단계: "튜토리얼 다시 보기" 메뉴
    - Drawer에 ListTile 추가, onTutorialReplay 콜백으로 startShowCase 재호출

- [x] **스토어 평점/리뷰 팝업 (in_app_review ^2.0.11)**
  - 참고: [docs/IN_APP_REVIEW_GUIDE.md](docs/IN_APP_REVIEW_GUIDE.md)
  - [x] 1단계: `requestReview()` — 인앱 리뷰 팝업 (자동 호출)
    - `AppStorage`: `first_launch_date`, `todo_completed_count`, `review_requested` 저장
    - `InAppReviewService`: 조건(5개 완료 또는 3일 경과) 만족 시 `requestReview()` 호출
    - `TodoListNotifier.toggleCheck`: 완료 시 횟수 증가 + `maybeRequestReview()` 호출
  - [x] 2단계: `openStoreListing()` — 스토어로 이동 버튼
    - Drawer에 "평점 남기기" ListTile 추가 (언어/태그 관리 사이)
    - iOS 출시 후 `InAppReviewService.appStoreId` 입력 필요
  - [x] 3단계: 다국어 문자열 추가
    - `rateApp`: ko, en, ja, zh-CN, zh-TW

- [x] **색상 태그별 필터링 기능**
  - `DatabaseHandler`에 `queryTodosByTag(int tag)` 메서드 추가
  - `VMHandler`에 `filterByTag(int? tag)` 메서드 추가
  - `home.dart` 앱바 아래에 태그 필터 드롭다운 UI 추가
  - null이면 전체 보기, 인덱스 지정 시 해당 색상만 필터링
  - 수정 파일: `database_handler.dart`, `vm_handler.dart`, `home.dart`

- [x] **태그에 이름 부여**
  - Tag 모델 + Hive Box "tag"로 DB 저장
  - 기본 10개: 업무, 개인, 공부, 취미, 건강, 쇼핑, 가족, 금융, 이동, 기타
  - 목록/편집/필터 화면에서 색상 옆에 태그 이름 표시

- [x] **검색 기능**
  - 할 일 내용(content) 텍스트 검색
  - 앱바에 검색 아이콘 추가 → 검색 바 토글

- [x] **완료/미완료 필터 (전체, 완료, 미완료)**
  - 기존 자동 정렬(미완료→완료) 제거
  - 단일 정렬 기준: 최근 수정순
  - 상태 필터 칩 UI 추가 (HomeStatusChips)

- [x] **태그 색상 커스터마이징**
  - Tag 모델에 `colorValue` (int) 필드로 색상 직접 저장
  - `TodoColor.presets` 15개 프리셋 + `MaterialPicker` (~190색) 선택 가능
  - `flutter_colorpicker` 패키지 적용

- [x] **태그 관리 화면 (태그 설정)**
  - Drawer → "태그 관리" 버튼으로 진입
  - 태그 추가/수정/삭제 가능 (`tag_settings.dart`)
  - 색상 선택: 프리셋 다이얼로그 + MaterialPicker 다이얼로그

- [x] **Drawer 추가**
  - 세팅 헤더 (기어 아이콘 + "세팅" 텍스트)
  - 다크 모드 스위치
  - 화면 꺼짐 방지 스위치 (wakelock_plus, 기본값 false)
  - 태그 관리 버튼

- [x] **테마 시스템 적용 (다크/라이트 모드)**
  - `ThemeNotifier` + `GetStorage`로 테마 상태 관리/영속화
  - `CommonColorScheme` 기반 시맨틱 컬러 정의
  - `context.palette` 확장으로 어디서든 테마 색상 접근
  - 모든 view 파일의 하드코딩 색상 → `context.palette` 마이그레이션

- [x] **UI 모듈화**
  - `home.dart`의 위젯 빌드 함수들을 `home_widgets.dart`로 분리
  - `todo_item.dart` 별도 위젯 파일 분리

- [x] **Todo 항목 순서 변경 (드래그 앤 드롭)**
  - `ReorderableListView` + `ReorderableDragStartListener` (드래그 핸들)
  - `Todo.sortOrder` 필드 추가 (HiveField 6)
  - `DatabaseHandler.reorder()` / `TodoListNotifier.reorder()`로 순서 영속화

- [x] **삭제 UX 개선**
  - 길게 누르기 시 해당 Todo 하이라이트 효과 (AnimatedContainer)
  - 삭제 바텀시트에 "완료 항목 일괄 삭제" 버튼 추가
  - 바텀시트 닫히면 하이라이트 자동 해제

- [x] **편집 시트 내 태그 관리 바로가기**
  - Todo 생성/수정 바텀시트 하단에 "태그 관리" 버튼 추가
  - Navigator.push로 태그 설정 화면 이동 → 복귀 시 태그 목록 자동 갱신

- [x] **마감일 및 알림 기능 (단계적 구현)**
  - [x] 1단계: Todo 모델에 `dueDate` (DateTime?) 필드 추가 + TypeAdapter 수정
  - [x] 2단계: 편집 시트에 날짜/시간 선택 UI
    - 날짜: `showDatePicker` (Material 캘린더)
    - 시간: `CupertinoDatePicker` 바텀시트 (Material showTimePicker 대체)
  - [x] 3단계: 홈 화면 Todo 아이템에 마감일 표시 (알람 아이콘 + 날짜/시간 텍스트)
  - [x] 4단계: `flutter_local_notifications` 연동 (알림 예약/취소/수정)
    - `NotificationService`: scheduleNotification, cancelNotification, cleanupExpiredNotifications
    - TodoListNotifier insert/update/delete 시 알람 등록/취소 연동
    - 앱 시작/포그라운드 복귀 시 Hive Box 마감일 Todo 알람 재등록 (DB 로드만으로는 미등록됨)
    - Android 알람 ID 32비트 제한 처리 (`_toNotificationId`)
    - 알람 등록 시 payload에 dueDate 저장 → 로그에 dueDate 출력
  - [x] 5단계: iOS 권한 요청 처리 (Info.plist, AppDelegate 설정)
    - `requestPermission`, `DarwinInitializationSettings` (presentBanner, presentList 등)
  - Drawer "알람 상태 확인" 메뉴: Hive Box 마감일 Todo 개수 + 등록된 알람 개수 표시
  - [x] 앱 아이콘 배지 (app_badge_plus): 예약 알람 개수 표시, 앱 진입 시 clearBadge

- [x] **마감일 필터 (알람 아이콘 토글)**
  - 홈 필터: [전체][미완료][완료] 왼쪽 / [🔔] 오른쪽
  - 알람 아이콘 토글: 마감일 있는 것만 ↔ 전체

- [x] **다국어 (easy_localization)**
  - `assets/translations/`: ko, en, ja, zh-CN, zh-TW
  - Drawer에 언어 선택

- [x] **앱 아이콘 & 스플래시**
  - `assets/icon.png`, `assets/splash.png` (TagDo 텍스트 포함)
  - `flutter_launcher_icons`, `flutter_native_splash` 설정
  - `FlutterNativeSplash.preserve()` / `remove()` 패턴 적용

- [x] **튜토리얼용 할 일 자동 생성**
  - 앱 최초 설치 시 5분 후 알람이 있는 튜토리얼 할 일 1개 생성
  - `AppStorage.tutorial_todo_created` 플래그로 1회만 실행
  - `TodoListNotifier.createTutorialTodoIfNeeded()` — Home에서 `context.tr()`로 번역된 문자열 전달

## 기능 확장

- [ ] **위젯/홈 위젯**
  - 홈 화면에 Todo 요약 표시 (미완료 개수, 다음 마감일 등)
  - `home_widget` 패키지 사용, 네이티브 위젯(Android/iOS) 작성 필요
  - 참고: [docs/HOME_WIDGET_PACKAGE_REVIEW.md](docs/HOME_WIDGET_PACKAGE_REVIEW.md)

- [ ] **백업/복원**
  - Hive 데이터(Todo, Tag) 내보내기·가져오기
  - 파일 저장/불러오기 또는 공유(Share)로 백업본 전달

- [ ] **데이터 내보내기**
  - CSV/JSON 등으로 Todo 목록 내보내기
  - 설정 또는 Drawer에서 "데이터 내보내기" 메뉴

## 출시 준비

→ **[docs/RELEASE_CHECKLIST.md](docs/RELEASE_CHECKLIST.md)** 참고 (다른 앱에서도 재사용 가능)

- TagDo 전용: Bundle ID `com.cheng80.tagdo`, applicationId `com.cheng80.tagdo`, 카테고리 생산성

## 버그 수정 / 개선

- [x] **DateTime.now() 중복 호출 버그 수정**
  - `Todo.create()`에서 now 변수 하나로 통일 완료

- [x] **updatedAt 미갱신 수정**
  - `todo_edit.dart` 수정 모드에서 `updatedAt: DateTime.now()` 추가 완료

- [x] **"CHAGNGE" 오타 수정**
  - "CHANGE"로 수정 완료

- [x] **전체 삭제 시 확인 다이얼로그 추가**
  - 실수로 전체 삭제 방지를 위한 "정말 삭제하시겠습니까?" 확인 팝업

- [x] **빈 내용 저장 방지**
  - content가 비어있을 때 저장 버튼 비활성화 또는 인라인 경고 표시

- [x] **드롭다운 선택 시 글자 흔들림 수정**
  - `isExpanded: true` + `Expanded` + `Align` 적용

- [x] **다크 모드 바텀시트/다이얼로그 가독성 개선**
  - `sheetBackground`, `textOnSheet`, `iconOnSheet` 다크 테마 색상 조정
  - 모든 바텀시트/AlertDialog에 `backgroundColor: p.sheetBackground` 적용

- [x] **Hive TypeAdapter 파일 리네이밍**
  - `.g.dart` → `_adapter.dart` (수동 관리 명확화)
  - 코드 제너레이터 마이그레이션 가이드 문서 작성 (`docs/generator_migration.md`)

- [x] **과거 마감일 수정 시 DatePicker assertion 수정**
  - `initialDate`가 `firstDate`(오늘)보다 이전일 때 assertion 발생
  - `savedDueDate.isBefore(today)` 시 `initialDate`를 오늘로 클램프

## 구조 개선

- [x] **MVVM 패턴 정리**
  - Handler: DB/저장소 접근 전담 (DatabaseHandler, TagHandler)
  - Notifier: Riverpod 상태 관리 (TodoListNotifier, TagListNotifier, ThemeNotifier, WakelockNotifier)
  - vm_handler.dart 삭제 → TodoListNotifier로 통합

- [x] **Todo 아이템 위젯 분리**
  - `home.dart`의 `_buildTodoItem()`을 별도 위젯 파일로 분리
  - `view/todo_item.dart` 생성 → `ConsumerWidget`으로 구현

- [x] **TodoEditSheet 위젯 모듈화**
  - `todo_edit_sheet.dart` 500줄+ → 관련 위젯을 `sheets/todo_edit_sheet/` 폴더로 분리
  - `edit_form_field.dart`, `edit_sheet_header.dart`, `edit_sheet_content_field.dart`, `edit_sheet_due_date_field.dart`, `edit_sheet_tag_selector.dart`

- [x] **마감일(dueDate) UI 통합**
  - Todo 카드: 생성/수정 시간 제거 → 마감일 영역으로 대체 (설정 시에만 표시)
  - 핸들 아이콘 왼쪽에 알람 아이콘(`Icons.access_alarm`) - dueDate 설정 시 노란색(`alarmAccent`), 미설정 시 영역만 유지
  - 테마에 `alarmAccent` 색상 추가 (라이트/다크 공통)
  - `edit_sheet_notifier.dart`에 `editDueDateProvider` 추가, `Todo.copyWith`에 `clearDueDate` 파라미터

- [ ] **Riverpod 코드 제너레이션 방식 추가 (`@riverpod`)**
  - 참고 프로젝트의 `vm_handler_gen.dart`처럼 어노테이션 방식 ViewModel 추가
  - `riverpod_annotation`, `riverpod_generator` 패키지 필요

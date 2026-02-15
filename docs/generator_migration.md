# 코드 제너레이터 도입 마이그레이션 가이드

현재 프로젝트는 Hive TypeAdapter와 Riverpod Provider를 **수동 관리**하고 있다.
차후 `build_runner` 기반 코드 제너레이터를 도입할 때 참고한다.

---

## 현재 구조 (수동 관리)

| 항목 | 파일 | 비고 |
|------|------|------|
| Todo TypeAdapter | `lib/model/todo_adapter.dart` | `part of 'todo.dart'` |
| Tag TypeAdapter | `lib/model/tag_adapter.dart` | `part of 'tag.dart'` |
| Riverpod Provider | 각 `*_notifier.dart` 내 수동 정의 | `@riverpod` 미사용 |

---

## 1단계: Hive 제너레이터 도입

### 패키지 추가

```yaml
# pubspec.yaml
dev_dependencies:
  build_runner: ^2.4.0
  hive_generator: ^2.0.1
```

### 마이그레이션 절차

1. `todo_adapter.dart`, `tag_adapter.dart` 삭제
2. 모델 파일의 `part` 선언을 `.g.dart`로 복원:
   ```dart
   // todo.dart
   part 'todo.g.dart';  // todo_adapter.dart → todo.g.dart

   // tag.dart
   part 'tag.g.dart';   // tag_adapter.dart → tag.g.dart
   ```
3. 빌드 실행:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
4. 생성된 `.g.dart` 파일 확인 후 기존 수동 코드와 비교

### 주의사항

- `@HiveField`의 인덱스 번호는 절대 변경하지 않는다 (기존 데이터 호환)
- 새 필드 추가 시 기존 최대 인덱스 + 1 사용
- `defaultValue` 설정으로 기존 데이터 마이그레이션 대응
- 현재 필드 인덱스:
  - **Todo**: 0(no), 1(content), 2(tag), 3(isCheck), 4(createdAt), 5(updatedAt), 6(sortOrder), 7(dueDate)
  - **Tag**: 0(id), 1(name), 2(colorValue)

---

## 2단계: Riverpod 제너레이터 도입

### 패키지 추가

```yaml
# pubspec.yaml
dependencies:
  riverpod_annotation: ^2.6.1

dev_dependencies:
  build_runner: ^2.4.0        # 1단계에서 이미 추가
  riverpod_generator: ^2.6.5
```

### 변환 예시

**변환 전 (수동 정의):**
```dart
class TodoListNotifier extends AsyncNotifier<List<Todo>> {
  @override
  Future<List<Todo>> build() async { ... }
}

final todoListProvider =
    AsyncNotifierProvider<TodoListNotifier, List<Todo>>(TodoListNotifier.new);
```

**변환 후 (제너레이터):**
```dart
@riverpod
class TodoListNotifier extends _$TodoListNotifier {
  @override
  Future<List<Todo>> build() async { ... }
}
// → todoListProvider가 자동 생성됨
```

### 마이그레이션 절차

1. 모델 파일에 `part '*.g.dart';` 추가
2. Notifier 클래스에 `@riverpod` 어노테이션 추가
3. `extends AsyncNotifier` → `extends _$클래스명` 변경
4. 수동 정의한 `final xxxProvider = ...` 삭제
5. 빌드 실행:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
6. 기존 `ref.watch(xxxProvider)` 호출은 그대로 동작 (Provider 이름 동일)

### 주의사항

- 한 번에 전부 변환하지 말고, 파일 단위로 순차 진행
- 변환 후 기존 테스트가 통과하는지 확인
- `autoDispose` 여부는 `@Riverpod(keepAlive: true/false)`로 제어

---

## 현재 수동 관리 파일 목록

### TypeAdapter (Hive)
- `lib/model/todo_adapter.dart` → `todo.g.dart`로 대체 예정
- `lib/model/tag_adapter.dart` → `tag.g.dart`로 대체 예정

### Riverpod Provider (수동 정의)
- `lib/vm/todo_list_notifier.dart` — `todoListProvider`
- `lib/vm/tag_list_notifier.dart` — `tagListProvider`
- `lib/vm/theme_notifier.dart` — `themeNotifierProvider`
- `lib/vm/home_filter_notifier.dart` — `selectedTagProvider`, `todoStatusProvider`, `searchQueryProvider`, `searchModeProvider`, `filterStateProvider`
- `lib/vm/edit_sheet_notifier.dart` — `editTagProvider`, `isContentEmptyProvider`

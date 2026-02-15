import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 완료 상태 필터
enum TodoStatus { all, unchecked, checked }

// 홈 필터 로컬 상태 - 선택 태그
class SelectedTagNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void setTag(int? value) => state = value;
}

// 홈 필터 로컬 상태 - 완료 상태
class TodoStatusNotifier extends Notifier<TodoStatus> {
  @override
  TodoStatus build() => TodoStatus.all;

  void setStatus(TodoStatus value) => state = value;
}

// 홈 필터 로컬 상태 - 검색어
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String value) => state = value;
}

// 홈 필터 로컬 상태 - 검색 모드
class SearchModeNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setMode(bool value) => state = value;
}

/// 마감일 필터: null=전체, true=마감일 있는 것만
class DueDateFilterNotifier extends Notifier<bool?> {
  @override
  bool? build() => null;

  void setHasDueDate(bool? value) => state = value;

  void toggle() => state = state == true ? null : true;
}

// 삭제 시트 표시 중인 Todo no (하이라이트 용)
class HighlightedTodoNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void highlight(int? no) => state = no;
}

// 화면 종료 시 자동 해제
final selectedTagProvider =
    NotifierProvider.autoDispose<SelectedTagNotifier, int?>(
  SelectedTagNotifier.new,
);
final todoStatusProvider =
    NotifierProvider.autoDispose<TodoStatusNotifier, TodoStatus>(
  TodoStatusNotifier.new,
);
final searchQueryProvider =
    NotifierProvider.autoDispose<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);
final searchModeProvider =
    NotifierProvider.autoDispose<SearchModeNotifier, bool>(
  SearchModeNotifier.new,
);
final dueDateFilterProvider =
    NotifierProvider.autoDispose<DueDateFilterNotifier, bool?>(
  DueDateFilterNotifier.new,
);
final highlightedTodoProvider =
    NotifierProvider.autoDispose<HighlightedTodoNotifier, int?>(
  HighlightedTodoNotifier.new,
);

/// 태그/검색어/상태/마감일 유무 결합 필터
class FilterState {
  final int? tag;
  final String keyword;
  final TodoStatus status;
  final bool? hasDueDate;

  const FilterState({
    required this.tag,
    required this.keyword,
    required this.status,
    this.hasDueDate,
  });
}

final filterStateProvider = Provider<FilterState>((ref) {
  final tag = ref.watch(selectedTagProvider);
  final keyword = ref.watch(searchQueryProvider).trim();
  final status = ref.watch(todoStatusProvider);
  final hasDueDate = ref.watch(dueDateFilterProvider);
  return FilterState(
    tag: tag,
    keyword: keyword,
    status: status,
    hasDueDate: hasDueDate,
  );
});

// tag_list_notifier.dart
// Tag 목록 Riverpod Notifier

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitcell/model/tag.dart';
import 'package:habitcell/vm/tag_handler.dart';

/// Tag 목록 비동기 관리
class TagListNotifier extends AsyncNotifier<List<Tag>> {
  final _tagHandler = TagHandler();

  @override
  Future<List<Tag>> build() async {
    return _tagHandler.loadAll();
  }

  /// 태그 신규 생성
  Future<void> addTag(Tag tag) async {
    await _tagHandler.saveTag(tag);
    ref.invalidateSelf();
  }

  /// 태그 수정 (이름, 색상 등)
  Future<void> updateTag(Tag tag) async {
    await _tagHandler.saveTag(tag);
    ref.invalidateSelf();
  }

  /// 태그 삭제
  Future<void> deleteTag(int id) async {
    await _tagHandler.deleteTag(id);
    ref.invalidateSelf();
  }

  /// 다음 사용 가능한 ID
  int nextId() => _tagHandler.nextId();
}

final tagListProvider =
    AsyncNotifierProvider<TagListNotifier, List<Tag>>(TagListNotifier.new);

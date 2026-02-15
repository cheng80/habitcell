// tag_handler.dart
// Tag Hive Box CRUD

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:habitcell/model/tag.dart';
import 'package:habitcell/util/app_locale.dart';

/// 기본 태그 색상 (이름은 locale별)
const List<Color> _defaultColors = [
  Colors.red,
  Colors.amber,
  Colors.purpleAccent,
  Colors.lightBlue,
  Colors.blue,
  Colors.deepOrange,
  Colors.pink,
  Colors.teal,
  Colors.indigoAccent,
  Colors.green,
];

/// locale별 기본 태그 이름 (ko, en, ja, zh_CN, zh_TW)
const Map<String, List<String>> _tagNamesByLocale = {
  'ko': ['업무', '개인', '공부', '취미', '건강', '쇼핑', '가족', '금융', '이동', '기타'],
  'en': ['Work', 'Personal', 'Study', 'Hobby', 'Health', 'Shopping', 'Family', 'Finance', 'Travel', 'Others'],
  'ja': ['仕事', '個人', '勉強', '趣味', '健康', 'ショッピング', '家族', '金融', '移動', 'その他'],
  'zh_CN': ['工作', '个人', '学习', '爱好', '健康', '购物', '家庭', '理财', '出行', '其他'],
  'zh_TW': ['工作', '個人', '學習', '嗜好', '健康', '購物', '家庭', '理財', '出行', '其他'],
};

/// TagHandler - Tag Box CRUD
class TagHandler {
  static const String _boxName = 'tag';

  Box<Tag> _getBox() => Hive.box<Tag>(_boxName);

  /// 전체 태그 조회. 비어 있으면 기본 태그 생성 후 반환
  Future<List<Tag>> loadAll() async {
    final box = _getBox();
    if (box.isEmpty) {
      await _initDefaults();
    }
    final list = box.values.toList();
    list.sort((a, b) => a.id.compareTo(b.id));
    return list;
  }

  /// 태그 저장 (신규 생성 / 수정 공용)
  Future<void> saveTag(Tag tag) async {
    await _getBox().put('${tag.id}', tag);
  }

  /// 태그 삭제
  Future<void> deleteTag(int id) async {
    await _getBox().delete('$id');
  }

  /// 다음 사용 가능한 ID 반환
  int nextId() {
    final box = _getBox();
    if (box.isEmpty) return 0;
    final maxId = box.values.map((t) => t.id).reduce((a, b) => a > b ? a : b);
    return maxId + 1;
  }

  /// Box 비어 있을 때 기본 태그 생성 (초기 locale 적용)
  Future<void> _initDefaults() async {
    final box = _getBox();
    final names = _getTagNamesForLocale(appLocaleForInit);
    for (var i = 0; i < names.length && i < _defaultColors.length; i++) {
      await box.put(
        '$i',
        Tag(id: i, name: names[i], colorValue: _defaultColors[i].toARGB32()),
      );
    }
  }

  static List<String> _getTagNamesForLocale(Locale? locale) {
    if (locale != null) {
      final key = locale.countryCode != null
          ? '${locale.languageCode}_${locale.countryCode}'
          : locale.languageCode;
      final names = _tagNamesByLocale[key];
      if (names != null) return names;
    }
    return _tagNamesByLocale['ko']!;
  }

  /// id로 태그 조회 헬퍼
  static Tag? tagOf(List<Tag> tags, int id) {
    return tags.where((e) => e.id == id).firstOrNull;
  }

  /// id로 태그 이름 조회. 없으면 "태그 N" 반환
  static String nameOf(List<Tag> tags, int id) {
    return tagOf(tags, id)?.name ?? '태그 $id';
  }

  /// id로 태그 색상 조회. 없으면 회색 반환
  static Color colorOf(List<Tag> tags, int id) {
    return tagOf(tags, id)?.color ?? Colors.grey;
  }
}

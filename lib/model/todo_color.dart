// todo_color.dart
// 태그 색상 프리셋 팔레트

import 'package:flutter/material.dart';

/// TodoColor - 태그 생성/수정 시 선택 가능한 프리셋 색상 팔레트
///
/// 사용자가 태그 색상을 고를 때 이 목록에서 선택합니다.
/// 선택된 색상은 Tag.colorValue (Color.value int)로 저장됩니다.
class TodoColor {
  const TodoColor._();

  /// 선택 가능한 프리셋 색상 목록
  static const List<Color> presets = [
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
    Colors.brown,
    Colors.cyan,
    Colors.lime,
    Colors.orange,
    Colors.indigo,
  ];
}

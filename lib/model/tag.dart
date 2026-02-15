// tag.dart
// 태그 모델 - id, name, colorValue

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Hive TypeAdapter (수동 관리)
part 'tag_adapter.dart';

/// Hive에 저장할 Tag 데이터 모델
/// typeId: 2 → Todo(1)와 구분
@HiveType(typeId: 2)
class Tag {
  /// [필드 0] 고유 번호
  @HiveField(0)
  final int id;

  /// [필드 1] 태그 표시 이름
  @HiveField(1)
  final String name;

  /// [필드 2] 색상 값 (Color.value → int)
  /// 사용 시: Color(tag.colorValue)
  @HiveField(2)
  final int colorValue;

  const Tag({
    required this.id,
    required this.name,
    required this.colorValue,
  });

  /// 색상 객체로 변환
  Color get color => Color(colorValue);

  Tag copyWith({
    int? id,
    String? name,
    int? colorValue,
  }) {
    return Tag(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
    );
  }
}

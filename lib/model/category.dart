// category.dart
// 카테고리 모델 - id, name, colorValue, sortOrder

import 'package:flutter/material.dart';

/// 카테고리 데이터 모델
/// SQLite categories 테이블과 매핑
class Category {
  final String id;
  final String name;
  final int colorValue;
  final int sortOrder;

  const Category({
    required this.id,
    required this.name,
    required this.colorValue,
    this.sortOrder = 0,
  });

  /// 색상 객체로 변환
  Color get color => Color(colorValue);

  Category copyWith({
    String? id,
    String? name,
    int? colorValue,
    int? sortOrder,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color_value': colorValue,
      'sort_order': sortOrder,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String,
      name: map['name'] as String,
      colorValue: map['color_value'] as int? ?? 0xFF9E9E9E,
      sortOrder: map['sort_order'] as int? ?? 0,
    );
  }
}

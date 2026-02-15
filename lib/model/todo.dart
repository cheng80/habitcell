// todo.dart
// 핵심 기능만 간단히 요약


import 'package:hive_flutter/hive_flutter.dart';

/// Hive TypeAdapter (수동 관리)
part 'todo_adapter.dart';

/// Hive에 저장할 수 있는 Todo 데이터 모델
/// typeId: 1 → Hive 내부에서 이 타입을 구분하기 위한 고유 식별자
@HiveType(typeId: 1)
class Todo {
  /// [필드 0] 고유 번호 - 밀리초 타임스탬프로 유니크한 값을 생성합니다.
  /// Hive Box에서 key로도 사용됩니다 (put("${todo.no}", todo)).
  @HiveField(0)
  final int no;

  /// [필드 1] 할 일 내용 - 사용자가 입력한 텍스트
  @HiveField(1)
  final String content;

  /// [필드 2] 태그 ID - Tag.id에 대응
  @HiveField(2)
  final int tag;

  /// [필드 3] 완료 여부 - true이면 완료, false이면 미완료
  @HiveField(3)
  final bool isCheck;

  /// [필드 4] 생성 일시
  @HiveField(4)
  final DateTime createdAt;

  /// [필드 5] 수정 일시
  @HiveField(5)
  final DateTime updatedAt;

  /// [필드 6] 사용자 지정 정렬 순서 (작을수록 위에 표시)
  @HiveField(6, defaultValue: 0)
  final int sortOrder;

  /// [필드 7] 마감일시 (알림용, null이면 미설정)
  @HiveField(7)
  final DateTime? dueDate;

  /// 기본 생성자
  const Todo({
    required this.no,
    required this.content,
    required this.tag,
    required this.isCheck,
    required this.createdAt,
    required this.updatedAt,
    this.sortOrder = 0,
    this.dueDate,
  });

  /// [팩토리 생성자] Todo.create - 새로운 Todo 생성
  /// - no: 밀리초 타임스탬프로 유니크 ID 자동 생성
  /// - isCheck: 항상 false (미완료 상태)
  /// - createdAt, updatedAt: 현재 시간으로 동일하게 설정
  factory Todo.create(String content, int current, {int sortOrder = 0, DateTime? dueDate}) {
    final now = DateTime.now();
    return Todo(
      no: now.millisecondsSinceEpoch,
      content: content,
      tag: current,
      isCheck: false,
      createdAt: now,
      updatedAt: now,
      sortOrder: sortOrder,
      dueDate: dueDate,
    );
  }

  /// [copyWith] - 불변 객체의 일부 필드만 변경한 복사본 생성
  /// [clearDueDate] true이면 dueDate를 null로 설정 (마감일 해제)
  Todo copyWith({
    final int? no,
    final String? content,
    final int? tag,
    final bool? isCheck,
    final DateTime? createdAt,
    final DateTime? updatedAt,
    final int? sortOrder,
    final DateTime? dueDate,
    final bool clearDueDate = false,
  }) {
    return Todo(
      no: no ?? this.no,
      content: content ?? this.content,
      tag: tag ?? this.tag,
      isCheck: isCheck ?? this.isCheck,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sortOrder: sortOrder ?? this.sortOrder,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
    );
  }

  /// 디버깅용 toString
  @override
  String toString() =>
      "Todo(no: $no, content: $content, tag: $tag, isCheck: $isCheck, sortOrder: $sortOrder, dueDate: $dueDate, createdAt: $createdAt, updatedAt: $updatedAt)";
}

// todo_adapter.dart
// Todo Hive TypeAdapter (수동 관리)

part of 'todo.dart';

/// TodoAdapter - Todo 객체의 직렬화/역직렬화 담당
/// typeId: 1 → @HiveType(typeId: 1)과 동일
class TodoAdapter extends TypeAdapter<Todo> {
  @override
  final int typeId = 1;

  /// 바이너리 → Todo 객체 (역직렬화)
  @override
  Todo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Todo(
      no: fields[0] as int,
      content: fields[1] as String,
      tag: fields[2] as int,
      isCheck: fields[3] as bool,
      createdAt: fields[4] as DateTime,
      updatedAt: fields[5] as DateTime,
      sortOrder: fields[6] as int? ?? 0,
      dueDate: fields[7] as DateTime?,
    );
  }

  /// Todo 객체 → 바이너리 (직렬화)
  @override
  void write(BinaryWriter writer, Todo obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.no)
      ..writeByte(1)
      ..write(obj.content)
      ..writeByte(2)
      ..write(obj.tag)
      ..writeByte(3)
      ..write(obj.isCheck)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt)
      ..writeByte(6)
      ..write(obj.sortOrder)
      ..writeByte(7)
      ..write(obj.dueDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TodoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

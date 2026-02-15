// tag_adapter.dart
// Tag Hive TypeAdapter (수동 관리)

part of 'tag.dart';

/// TagAdapter - Tag 객체의 직렬화/역직렬화 담당
/// typeId: 2 → @HiveType(typeId: 2)과 동일
class TagAdapter extends TypeAdapter<Tag> {
  @override
  final int typeId = 2;

  /// 바이너리 → Tag 객체 (역직렬화)
  @override
  Tag read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Tag(
      id: fields[0] as int,
      name: fields[1] as String,
      colorValue: fields[2] as int,
    );
  }

  /// Tag 객체 → 바이너리 (직렬화)
  @override
  void write(BinaryWriter writer, Tag obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.colorValue);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TagAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

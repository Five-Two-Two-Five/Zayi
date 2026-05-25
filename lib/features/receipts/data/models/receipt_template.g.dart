// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipt_template.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReceiptTemplateAdapter extends TypeAdapter<ReceiptTemplate> {
  @override
  final int typeId = 0;

  @override
  ReceiptTemplate read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ReceiptTemplate(
      id: fields[0] as String,
      name: fields[1] as String,
      headerSettings: (fields[2] as Map).cast<String, dynamic>(),
      footerSettings: (fields[3] as Map).cast<String, dynamic>(),
      styling: (fields[4] as Map).cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, ReceiptTemplate obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.headerSettings)
      ..writeByte(3)
      ..write(obj.footerSettings)
      ..writeByte(4)
      ..write(obj.styling);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReceiptTemplateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

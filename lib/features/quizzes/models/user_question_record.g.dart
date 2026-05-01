// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_question_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserQuestionRecordAdapter extends TypeAdapter<UserQuestionRecord> {
  @override
  final int typeId = 0;

  @override
  UserQuestionRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserQuestionRecord(
      questionId: fields[0] as String,
      wasCorrect: fields[1] as bool,
      timesAnswered: fields[2] as int,
      lastSeen: fields[3] as DateTime,
      dueInDays: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, UserQuestionRecord obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.questionId)
      ..writeByte(1)
      ..write(obj.wasCorrect)
      ..writeByte(2)
      ..write(obj.timesAnswered)
      ..writeByte(3)
      ..write(obj.lastSeen)
      ..writeByte(4)
      ..write(obj.dueInDays);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserQuestionRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

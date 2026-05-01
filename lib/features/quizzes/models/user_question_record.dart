import 'package:hive/hive.dart';

// هذا السطر سيظهر تحته خط أحمر الآن، لا تقلقي سنحله في الخطوة 4
part 'user_question_record.g.dart';

@HiveType(typeId: 0) // رقم فريد لتعريف الجدول
class UserQuestionRecord extends HiveObject {
  @HiveField(0)
  final String questionId;

  @HiveField(1)
  bool wasCorrect;

  @HiveField(2)
  int timesAnswered;

  @HiveField(3)
  DateTime lastSeen;

  @HiveField(4)
  int dueInDays; // متى يظهر السؤال مرة أخرى (المذاكرة الذكية)

  UserQuestionRecord({
    required this.questionId,
    required this.wasCorrect,
    required this.timesAnswered,
    required this.lastSeen,
    required this.dueInDays,
  });
}

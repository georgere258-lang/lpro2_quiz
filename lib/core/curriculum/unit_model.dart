// PATH: lib/core/curriculum/unit_model.dart

class UnitModel {
  final String id;

  /// 1) Truth Line
  final String truthLine;

  /// 2) Emotional Context
  final String emotionalContext;

  /// 3) Questions
  final List<Question> questions;

  /// 4) Closing Insight (نص الـ Insight الأساسي قبل أي تخصيص)
  final String closingInsight;

  const UnitModel({
    required this.id,
    required this.truthLine,
    required this.emotionalContext,
    required this.questions,
    required this.closingInsight,
  });
}

class Question {
  final String id;
  final String text;
  final List<String> options;

  /// اختياري لاحقًا (بدون كسر الحالي)
  final int? correctIndex;

  const Question({
    required this.id,
    required this.text,
    required this.options,
    this.correctIndex,
  });
}

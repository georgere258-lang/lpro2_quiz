// PATH: lib/features/quizzes/models/section_quiz_model.dart

class SectionQuiz {
  final String id;
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  final String? explanation; // التفسير الذي يظهر بعد الإجابة
  final String category;

  SectionQuiz({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    this.explanation,
    required this.category,
  });

  // تحويل من JSON (قادم من GitHub) إلى Object داخل التطبيق
  factory SectionQuiz.fromJson(Map<String, dynamic> json) {
    return SectionQuiz(
      id: json['id']?.toString() ?? '',
      question: json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      // نضمن أن الرقم القادم هو integer دائمًا
      correctAnswerIndex: (json['correctAnswerIndex'] as num?)?.toInt() ?? 0,
      explanation: json['explanation'],
      category: json['category'] ?? '',
    );
  }

  // تحويل من Object إلى JSON (مهم جداً للوحة التحكم عند الرفع لـ GitHub)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      if (explanation != null && explanation!.isNotEmpty)
        'explanation': explanation,
      'category': category,
    };
  }
}

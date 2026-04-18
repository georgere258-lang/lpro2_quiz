// PATH: lib/features/quizzes/models/quiz.dart

import '../../../core/constants/firestore_paths.dart';
import '../../../core/models/admin_control_models.dart';

/// Valid quiz categories.
class QuizCategory {
  static const String stars = 'stars';
  static const String pros = 'pros';
  static const String general = 'general';

  // المسميات العربية لضمان توافق الـ Validation
  static const String starsArabic = 'دوري النجوم';
  static const String prosArabic = 'دوري المحترفين';

  static const List<String> values = [
    stars,
    pros,
    general,
    starsArabic,
    prosArabic
  ];

  static bool isValid(String value) => values.contains(value);
}

/// Valid quiz leagues.
class QuizLeague {
  static const String bronze = 'bronze';
  static const String silver = 'silver';
  static const String gold = 'gold';
  static const String platinum = 'platinum';

  static const List<String> values = [bronze, silver, gold, platinum];

  static bool isValid(String value) => values.contains(value);
}

/// Quiz model implementing admin control interface.
class Quiz implements IAdminControlled {
  @override
  final String id;

  final String question;
  final List<String> options;
  final int correctOptionIndex;
  final String category;
  final String league;
  final int difficulty;
  final String? explanation;
  final AdminControlFields control;
  final bool isDeleted;

  Quiz({
    required this.id,
    required this.question,
    required this.options,
    required this.correctOptionIndex,
    required this.category,
    required this.league,
    this.difficulty = 3,
    this.explanation,
    required this.control,
    this.isDeleted = false,
  });

  @override
  bool get isActive => control.isActive;

  @override
  DateTime? get publishAt => control.publishAt;

  @override
  DateTime? get expireAt => control.expireAt;

  @override
  DateTime? get updatedAt => control.updatedAt;

  @override
  String get sectionKey => control.sectionKey;

  /// Tags stored in AdminControlFields (max 5).
  List<String> get tags => control.tags;

  @override
  void validate() {
    // Question validation
    if (question.trim().length < 5) {
      // قللنا القيد لـ 5 لمرونة الأسئلة الحالية
      throw ArgumentError('الاستبيان يجب أن يكون على الأقل 5 أحرف');
    }

    // Options validation
    if (options.length < 2 || options.length > 5) {
      throw ArgumentError('يجب أن تحتوي الاختيارات على 2-5 عناصر');
    }
    for (var i = 0; i < options.length; i++) {
      if (options[i].trim().isEmpty) {
        throw ArgumentError('الاختيار رقم [$i] لا يمكن أن يكون فارغاً');
      }
    }

    // Correct index validation
    if (correctOptionIndex < 0 || correctOptionIndex >= options.length) {
      throw ArgumentError(
        'مؤشر الإجابة الصحيحة يجب أن يكون بين 0 و ${options.length - 1}',
      );
    }

    // Category validation
    if (!QuizCategory.isValid(category)) {
      throw ArgumentError('الفئة غير صالحة: $category');
    }

    // Difficulty validation
    if (difficulty < 1 || difficulty > 5) {
      throw ArgumentError('الصعوبة يجب أن تكون من 1 لـ 5');
    }

    // AdminControlFields validation
    control.validate();
  }

  @override
  Map<String, dynamic> toFirestore() {
    final map = control.toFirestore();
    map['question'] = question.trim();
    map['options'] = options.map((o) => o.trim()).toList();
    // نرفعها باسم correctAnswer لتوافق الداتابيز عندك
    map['correctAnswer'] = correctOptionIndex;
    map['category'] = category;
    map['league'] = league;
    map['difficulty'] = difficulty;
    map['isDeleted'] = isDeleted;
    if (explanation != null) {
      map['explanation'] = explanation!.trim();
    }
    // الـ Repository هو المسؤول عن الـ Timestamps
    map.remove('createdAt');
    map.remove('updatedAt');
    return map;
  }

  factory Quiz.fromFirestore(Map<String, dynamic> data, String id) {
    // ✅ دعم الحقلين لضمان قراءة correctAnswer من فايربيز عندك
    final dynamic correctVal =
        data['correctAnswer'] ?? data['correctOptionIndex'] ?? 0;

    return Quiz(
      id: id,
      question: (data['question'] as String?) ?? '',
      options: _parseOptions(data['options']),
      correctOptionIndex: correctVal is int ? correctVal : 0,
      category: (data['category'] as String?) ?? QuizCategory.general,
      league: (data['league'] as String?) ?? QuizLeague.bronze,
      difficulty: _parseDifficulty(data['difficulty']),
      explanation: data['explanation'] as String?,
      control: AdminControlFields.fromFirestore(
        data,
        FirestorePaths.sectionKeyQuiz,
      ),
      isDeleted: data['isDeleted'] == true,
    );
  }

  static List<String> _parseOptions(dynamic value) {
    if (value == null) return const ['', ''];
    if (value is List) {
      final parsed = value.map((e) => e.toString().trim()).toList();
      return parsed.length >= 2 ? parsed : const ['', ''];
    }
    return const ['', ''];
  }

  static int _parseDifficulty(dynamic value) {
    if (value is int && value >= 1 && value <= 5) return value;
    if (value is String) return int.tryParse(value)?.clamp(1, 5) ?? 3;
    return 3;
  }
}

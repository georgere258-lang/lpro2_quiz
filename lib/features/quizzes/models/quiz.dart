// PATH: lib/features/quizzes/models/quiz.dart

import '../../../core/constants/firestore_paths.dart';
import '../../../core/models/admin_control_models.dart';

/// Valid quiz categories.
class QuizCategory {
  static const String stars = 'stars';
  static const String pros = 'pros';
  static const String general = 'general';

  static const List<String> values = [stars, pros, general];

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
    if (question.trim().length < 10) {
      throw ArgumentError('question must be at least 10 characters');
    }

    // Options validation
    if (options.length < 2 || options.length > 4) {
      throw ArgumentError('options must have 2-4 items');
    }
    for (var i = 0; i < options.length; i++) {
      if (options[i].trim().isEmpty) {
        throw ArgumentError('option[$i] cannot be empty');
      }
    }

    // Correct index validation
    if (correctOptionIndex < 0 || correctOptionIndex >= options.length) {
      throw ArgumentError(
        'correctOptionIndex must be 0..${options.length - 1}',
      );
    }

    // Category validation
    if (!QuizCategory.isValid(category)) {
      throw ArgumentError('category must be one of: ${QuizCategory.values}');
    }

    // League validation
    if (!QuizLeague.isValid(league)) {
      throw ArgumentError('league must be one of: ${QuizLeague.values}');
    }

    // Difficulty validation
    if (difficulty < 1 || difficulty > 5) {
      throw ArgumentError('difficulty must be 1-5');
    }

    // Explanation validation (if present)
    if (explanation != null && explanation!.trim().length < 10) {
      throw ArgumentError('explanation must be at least 10 characters if set');
    }

    // AdminControlFields validation (includes tags max 5)
    control.validate();
  }

  @override
  Map<String, dynamic> toFirestore() {
    final map = control.toFirestore();
    map['question'] = question.trim();
    map['options'] = options.map((o) => o.trim()).toList();
    map['correctOptionIndex'] = correctOptionIndex;
    map['category'] = category;
    map['league'] = league;
    map['difficulty'] = difficulty;
    map['isDeleted'] = isDeleted;
    if (explanation != null) {
      map['explanation'] = explanation!.trim();
    }
    // Remove timestamps - repository handles serverTimestamp
    map.remove('createdAt');
    map.remove('updatedAt');
    return map;
  }

  factory Quiz.fromFirestore(Map<String, dynamic> data, String id) {
    return Quiz(
      id: id,
      question: (data['question'] as String?) ?? '',
      options: _parseOptions(data['options']),
      correctOptionIndex: (data['correctOptionIndex'] as int?) ?? 0,
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
      final parsed = value.whereType<String>().toList();
      return parsed.length >= 2 ? parsed : const ['', ''];
    }
    return const ['', ''];
  }

  static int _parseDifficulty(dynamic value) {
    if (value is int && value >= 1 && value <= 5) return value;
    return 3;
  }
}

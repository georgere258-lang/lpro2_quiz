// PATH: lib/features/quizzes/repositories/quiz_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../core/models/admin_control_models.dart';
import '../models/quiz.dart';

/// Repository for Quiz CRUD operations.
class QuizRepository {
  final FirebaseFirestore _firestore;
  late final CollectionReference<Map<String, dynamic>> _collection;

  QuizRepository([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance {
    _collection = _firestore.collection(FirestorePaths.quizzes);
  }

  /// Watches quizzes filtered by category and league.
  Stream<List<Quiz>> watchByCategoryLeague({
    required String category,
    required String league,
    bool includeInactive = false,
    bool includeDeleted = false,
    int limit = 50,
  }) {
    final safeLimit = limit.clamp(1, 100);
    Query<Map<String, dynamic>> query = _collection
        .where('category', isEqualTo: category)
        .where('league', isEqualTo: league);

    if (!includeDeleted) {
      query = query.where('isDeleted', isEqualTo: false);
    }
    if (!includeInactive) {
      query = query.where('isActive', isEqualTo: true);
    }

    return query
        .orderBy('createdAt', descending: true)
        .limit(safeLimit)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Quiz.fromFirestore(d.data(), d.id)).toList());
  }

  /// Watches all quizzes.
  Stream<List<Quiz>> watchAll({
    bool includeDeleted = false,
    int limit = 50,
  }) {
    final safeLimit = limit.clamp(1, 100);
    Query<Map<String, dynamic>> query = _collection;

    if (!includeDeleted) {
      query = query.where('isDeleted', isEqualTo: false);
    }

    return query
        .orderBy('createdAt', descending: true)
        .limit(safeLimit)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Quiz.fromFirestore(d.data(), d.id)).toList());
  }

  /// Creates a new quiz and returns its ID.
  Future<String> create(Quiz quiz) async {
    quiz.validate();

    final data = quiz.toFirestore();
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    data['isDeleted'] = false;

    final docRef = await _collection.add(data);
    return docRef.id;
  }

  /// Updates a quiz with the given fields.
  Future<void> update(String id, Map<String, dynamic> updates) async {
    final sanitized = <String, dynamic>{};

    for (final entry in updates.entries) {
      final key = entry.key;
      final value = entry.value;

      // Normalize DateTime fields to UTC Timestamp
      if (value is DateTime) {
        sanitized[key] = UtcNormalizer.toTimestamp(value);
      } else {
        sanitized[key] = value;
      }
    }

    sanitized['updatedAt'] = FieldValue.serverTimestamp();
    await _collection.doc(id).update(sanitized);
  }

  /// Toggles the active state of a quiz.
  Future<void> toggleActive(String id, bool isActive) async {
    await _collection.doc(id).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Moves a quiz to a new category and/or league.
  Future<void> move(
    String id, {
    required String newCategory,
    required String newLeague,
  }) async {
    if (!QuizCategory.isValid(newCategory)) {
      throw ArgumentError('Invalid category: $newCategory');
    }
    if (!QuizLeague.isValid(newLeague)) {
      throw ArgumentError('Invalid league: $newLeague');
    }

    await _collection.doc(id).update({
      'category': newCategory,
      'league': newLeague,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Soft deletes a quiz (sets isDeleted=true, isActive=false).
  Future<void> softDelete(String id) async {
    await _collection.doc(id).update({
      'isDeleted': true,
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Restores a soft-deleted quiz (sets isDeleted=false).
  /// Note: Does NOT auto-enable isActive - admin must manually activate.
  Future<void> restore(String id) async {
    await _collection.doc(id).update({
      'isDeleted': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Builds a share payload for a quiz (zero-cost, no network calls).
  Map<String, dynamic> buildSharePayload(Quiz quiz) {
    return {
      'quizId': quiz.id,
      'question': quiz.question,
      'league': quiz.league,
      'category': quiz.category,
      'deepLink': 'lpro://quiz/${quiz.id}',
    };
  }
}

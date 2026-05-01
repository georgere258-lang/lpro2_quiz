// PATH: lib/features/quizzes/repositories/quiz_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../core/models/admin_control_models.dart';
import '../models/quiz.dart';

/// Repository for Quiz CRUD operations (Firebase/Leagues Only).
class QuizRepository {
  final FirebaseFirestore _firestore;
  late final CollectionReference<Map<String, dynamic>> _collection;

  QuizRepository([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance {
    _collection = _firestore.collection(FirestorePaths.quizzes);
  }

  // ────────────────────────────────────────────────────────────────────────────
  // 1. الذكاء الاصطناعي للسحب (Smart Fetch) - نسخة فايربيز الأصلية للدوريات
  // ────────────────────────────────────────────────────────────────────────────

  Future<List<Quiz>> getSmartBatch({
    required String category,
    required int difficulty,
    required List<String> excludedIds,
    int limit = 15,
  }) async {
    // 1. تنظيف النص لضمان المطابقة الدقيقة
    final String cleanCategory = category.trim();
    debugPrint("🏠 [QuizRepo-Firebase] Fetching for: '$cleanCategory'");

    try {
      final snap = await _collection
          .where('category', isEqualTo: cleanCategory)
          .where('isActive', isEqualTo: true)
          .get();

      if (snap.docs.isEmpty) {
        debugPrint("⚠️ [QuizRepo] Firestore is empty for: $cleanCategory");
        return [];
      }

      final List<Quiz> allResults =
          snap.docs.map((d) => Quiz.fromFirestore(d.data(), d.id)).toList();

      List<Quiz> filtered = allResults.where((q) {
        final bool isNotDeleted = q.isDeleted == false;
        final bool isNotSeen = !excludedIds.contains(q.id);
        final bool matchesDiff = q.difficulty == difficulty;
        return isNotDeleted && isNotSeen && matchesDiff;
      }).toList();

      if (filtered.isEmpty) {
        filtered = allResults.where((q) => q.isDeleted == false).toList();
      }

      filtered.shuffle();
      return filtered.take(limit).toList();
    } catch (e) {
      debugPrint("❌ [QuizRepo] Firestore Error: $e");
      return [];
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // 2. نظام الحفظ (Save Session) - مخصص للدوريات (نجوم، محترفين)
  // ────────────────────────────────────────────────────────────────────────────
  Future<void> saveGameSession({
    required String uid,
    required String leagueKey,
    required int score,
    required int correctAnswers,
    required int totalQuestions,
  }) async {
    String k = leagueKey.trim();
    String normalized = 'freeplay';
    if (k == 'stars' || k == 'دوري النجوم') normalized = 'stars';
    if (k == 'pros' || k == 'دوري المحترفين') normalized = 'pros';

    final userRef = _firestore.collection(FirestorePaths.users).doc(uid);
    final statsRef = _firestore.collection(FirestorePaths.userStats).doc(uid);

    try {
      await _firestore.runTransaction((transaction) async {
        final userSnap = await transaction.get(userRef);
        final statsSnap = await transaction.get(statsRef);

        final userData = userSnap.data() ?? {};
        final rootData = statsSnap.data() ?? {};

        String dailyField = normalized == 'stars'
            ? 'dailyStarsRounds'
            : (normalized == 'pros'
                ? 'dailyProsRounds'
                : 'dailyFreePlayRounds');

        final userUpdates = <String, dynamic>{
          dailyField: (userData[dailyField] ?? 0) + 1,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (normalized != 'freeplay') {
          userUpdates['points'] = FieldValue.increment(score);
          userUpdates['lastQuizDate'] = FieldValue.serverTimestamp();
        }

        transaction.set(userRef, userUpdates, SetOptions(merge: true));

        final Map<String, dynamic> leagueMap = rootData[normalized] is Map
            ? Map<String, dynamic>.from(rootData[normalized])
            : {};

        leagueMap['roundsPlayed'] = (leagueMap['roundsPlayed'] ?? 0) + 1;
        leagueMap['totalQuestions'] =
            (leagueMap['totalQuestions'] ?? 0) + totalQuestions;
        leagueMap['correctAnswers'] =
            (leagueMap['correctAnswers'] ?? 0) + correctAnswers;
        leagueMap['totalPoints'] = (leagueMap['totalPoints'] ?? 0) + score;

        transaction.set(
            statsRef,
            {
              normalized: leagueMap,
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true));
      });
    } catch (e) {
      debugPrint("❌ [QuizRepo] Save Error: $e");
      rethrow;
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // 3. العمليات التقليدية (Admin & Streams)
  // ────────────────────────────────────────────────────────────────────────────
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

    if (!includeDeleted) query = query.where('isDeleted', isEqualTo: false);
    if (!includeInactive) query = query.where('isActive', isEqualTo: true);

    return query
        .orderBy('createdAt', descending: true)
        .limit(safeLimit)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Quiz.fromFirestore(d.data(), d.id)).toList());
  }

  Stream<List<Quiz>> watchAll({
    bool includeDeleted = false,
    int limit = 50,
  }) {
    final safeLimit = limit.clamp(1, 100);
    Query<Map<String, dynamic>> query = _collection;
    if (!includeDeleted) query = query.where('isDeleted', isEqualTo: false);
    return query
        .orderBy('createdAt', descending: true)
        .limit(safeLimit)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Quiz.fromFirestore(d.data(), d.id)).toList());
  }

  Future<String> create(Quiz quiz) async {
    quiz.validate();
    final data = quiz.toFirestore();
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    data['isDeleted'] = false;
    final docRef = await _collection.add(data);
    return docRef.id;
  }

  Future<void> update(String id, Map<String, dynamic> updates) async {
    final sanitized = <String, dynamic>{};
    updates.forEach((key, value) {
      sanitized[key] = (value is DateTime) ? Timestamp.fromDate(value) : value;
    });
    sanitized['updatedAt'] = FieldValue.serverTimestamp();
    await _collection.doc(id).update(sanitized);
  }

  Future<void> toggleActive(String id, bool isActive) async {
    await _collection.doc(id).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> move(String id,
      {required String newCategory, required String newLeague}) async {
    if (!QuizCategory.isValid(newCategory)) {
      throw ArgumentError('Invalid category');
    }
    if (!QuizLeague.isValid(newLeague)) throw ArgumentError('Invalid league');
    await _collection.doc(id).update({
      'category': newCategory,
      'league': newLeague,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> softDelete(String id) async {
    await _collection.doc(id).update({
      'isDeleted': true,
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> restore(String id) async {
    await _collection.doc(id).update({
      'isDeleted': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

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

// PATH: lib/features/quiz/repositories/quiz_repository_impl.dart
// STATUS: Phase 6.3 - Production Final (Strict Rules Compliance & Data Integrity)
// ✅ Fully compatible with Firestore Rules (gameKeys & hasOnly)
// ✅ Map-Safe logic for all league categories
// ✅ Atomicity: Reads first, then selective Writes

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../core/constants/firestore_paths.dart';

class QuizRepositoryImpl {
  final FirebaseFirestore _firestore;

  QuizRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ────────────────────────────────────────────────────────────────────────────
  // Helpers
  // ────────────────────────────────────────────────────────────────────────────

  int _readInt(Map<String, dynamic> data, String key) {
    final v = data[key];
    if (v is num) return v.toInt();
    return 0;
  }

  int _readMapInt(Map<String, dynamic> map, String key) {
    final v = map[key];
    if (v is num) return v.toInt();
    return 0;
  }

  /// يضمن استرجاع Map صالحة لتجنب أخطاء النوع (Type Casting) أو البيانات التالفة
  Map<String, dynamic> _safeMap(Map<String, dynamic> root, String key) {
    final v = root[key];
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return v.map((k, v) => MapEntry(k.toString(), v));
    return <String, dynamic>{};
  }

  /// توحيد مسميات الدوريات لتطابق المسارات المعتمدة في قاعدة البيانات
  String _normalizeLeagueKey(String raw) {
    final k = raw.trim();
    if (k == 'stars' || k == 'pros' || k == 'freeplay') return k;
    if (k == 'دوري النجوم' || k.toLowerCase() == 'stars league') return 'stars';
    if (k == 'دوري المحترفين' || k.toLowerCase() == 'pros league') {
      return 'pros';
    }
    if (k == 'لعب حر' || k == 'اللعب الحر' || k.toLowerCase() == 'free play') {
      return 'freeplay';
    }
    return 'freeplay';
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Main Logic
  // ────────────────────────────────────────────────────────────────────────────

  Future<void> saveGameSession({
    required String uid,
    required String leagueKey,
    required int score,
    required int correctAnswers,
    required int totalQuestions,
  }) async {
    final normalizedLeagueKey = _normalizeLeagueKey(leagueKey);

    final userRef = _firestore.collection(FirestorePaths.users).doc(uid);
    final statsRef = _firestore.collection(FirestorePaths.userStats).doc(uid);

    final now = DateTime.now();
    final timestampNow = Timestamp.fromDate(now);

    try {
      debugPrint(
          '🟦 [QuizRepo] START saveGameSession: uid=$uid, league=$normalizedLeagueKey');

      await _firestore.runTransaction((transaction) async {
        // 1. READ PHASE (يجب أن تسبق أي عملية كتابة في الـ Transaction)
        final userSnap = await transaction.get(userRef);
        final statsSnap = await transaction.get(statsRef);

        final userData = userSnap.data() ?? <String, dynamic>{};
        final rootData = statsSnap.data() ?? <String, dynamic>{};

        // 2. LOGIC PHASE
        String pointsField = '';
        String dailyField = '';
        final bool isFreePlay = normalizedLeagueKey == 'freeplay';

        if (normalizedLeagueKey == 'stars') {
          pointsField = 'starsPoints';
          dailyField = 'dailyStarsRounds';
        } else if (normalizedLeagueKey == 'pros') {
          pointsField = 'proPoints';
          dailyField = 'dailyProsRounds';
        } else {
          dailyField = 'dailyFreePlayRounds';
        }

        // التحقق من التاريخ لتصفير العدادات اليومية إذا لزم الأمر
        final Timestamp? lastTs = userData['lastQuizDate'] as Timestamp?;
        bool isSameDay = false;
        if (lastTs != null) {
          final lastDate = lastTs.toDate();
          isSameDay = lastDate.year == now.year &&
              lastDate.month == now.month &&
              lastDate.day == now.day;
        }

        // --- بناء تحديثات جدول المستخدم (SELECTIVE UPDATE) ---
        // نلتزم فقط بالحقول الموجودة في gameKeys في الرولز
        final userUpdates = <String, dynamic>{
          dailyField: _readInt(userData, dailyField) + 1,
          'updatedAt': timestampNow,
        };

        if (!isSameDay) {
          if (dailyField != 'dailyStarsRounds') {
            userUpdates['dailyStarsRounds'] = 0;
          }
          if (dailyField != 'dailyProsRounds') {
            userUpdates['dailyProsRounds'] = 0;
          }
          if (dailyField != 'dailyFreePlayRounds') {
            userUpdates['dailyFreePlayRounds'] = 0;
          }
        }

        if (!isFreePlay) {
          userUpdates['points'] = FieldValue.increment(score);
          if (pointsField.isNotEmpty) {
            userUpdates[pointsField] = FieldValue.increment(score);
          }
          userUpdates['lastQuizDate'] = timestampNow;
        }

        // --- بناء وثيقة الإحصائيات (FULL REPLACE) ---
        final Map<String, dynamic> leagueMap = Map<String, dynamic>.from(
          _safeMap(rootData, normalizedLeagueKey),
        );

        leagueMap['roundsPlayed'] = _readMapInt(leagueMap, 'roundsPlayed') + 1;
        leagueMap['totalQuestions'] =
            _readMapInt(leagueMap, 'totalQuestions') + totalQuestions;
        leagueMap['correctAnswers'] =
            _readMapInt(leagueMap, 'correctAnswers') + correctAnswers;
        leagueMap['wrongAnswers'] = _readMapInt(leagueMap, 'wrongAnswers') +
            (totalQuestions - correctAnswers);
        leagueMap['totalPoints'] =
            _readMapInt(leagueMap, 'totalPoints') + score;

        // تجميع المستند النهائي ليتوافق مع قاعدة hasOnly(['stars', 'pros', 'freeplay', 'updatedAt'])
        final cleanRoot = <String, dynamic>{
          'updatedAt': timestampNow,
          'stars': normalizedLeagueKey == 'stars'
              ? leagueMap
              : _safeMap(rootData, 'stars'),
          'pros': normalizedLeagueKey == 'pros'
              ? leagueMap
              : _safeMap(rootData, 'pros'),
          'freeplay': normalizedLeagueKey == 'freeplay'
              ? leagueMap
              : _safeMap(rootData, 'freeplay'),
        };

        // 3. WRITE PHASE
        // تحديث جدول المستخدم الأساسي
        transaction.set(userRef, userUpdates, SetOptions(merge: true));

        // استبدال كامل لوثيقة الإحصائيات لضمان مطابقتها للرولز 100%
        transaction.set(statsRef, cleanRoot);

        debugPrint('🟦 [QuizRepo] TRANSACTION PREPARED');
      });

      debugPrint('✅ [QuizRepo] SAVE SUCCESS');
    } on FirebaseException catch (e) {
      debugPrint('❌ [QuizRepo] FIREBASE ERROR: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('❌ [QuizRepo] UNEXPECTED ERROR: $e');
      rethrow;
    }
  }
}

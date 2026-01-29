// PATH: lib/features/quiz/repositories/quiz_repository_impl.dart
// STATUS: Phase 6.1 - Transaction Ordering + Practical Stability
//         ✅ Reads FIRST, Writes LAST (fixes ordering crash)
//         ✅ LeagueKey normalization (Arabic/legacy -> stars/pros/freeplay)
//         ✅ num/int safe reads
//         ✅ Concrete timestamps for users + user_stats (avoid sentinel issues)
//         ✅ FirebaseException logging (code/message) for definitive diagnosis
//
// NOTE: No UI changes. No field renames.

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

  String _normalizeLeagueKey(String raw) {
    final k = raw.trim();

    // canonical
    if (k == 'stars' || k == 'pros' || k == 'freeplay') return k;

    // Arabic / legacy
    if (k == 'دوري النجوم' || k.toLowerCase() == 'stars league') return 'stars';
    if (k == 'دوري المحترفين' || k.toLowerCase() == 'pros league')
      return 'pros';

    // Free play labels
    if (k == 'لعب حر' || k == 'اللعب الحر' || k.toLowerCase() == 'free play') {
      return 'freeplay';
    }

    debugPrint('⚠️ [QuizRepo] Unknown leagueKey="$raw" -> fallback "freeplay"');
    return 'freeplay';
  }

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
          '🟦 [QuizRepo] ENTER saveGameSession uid=$uid league="$leagueKey" -> "$normalizedLeagueKey" score=$score');

      await _firestore.runTransaction((transaction) async {
        // ─────────────────────────────────────────────────────────────────────
        // READ PHASE (ALL READS FIRST)
        // ─────────────────────────────────────────────────────────────────────
        final userSnap = await transaction.get(userRef);
        final statsSnap = await transaction.get(statsRef);

        final userData = userSnap.data() ?? <String, dynamic>{};
        final rootData = statsSnap.data() ?? <String, dynamic>{};

        // ─────────────────────────────────────────────────────────────────────
        // LOGIC PHASE (NO WRITES YET)
        // ─────────────────────────────────────────────────────────────────────

        // --- Users: fields based on league
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
          pointsField = '';
          dailyField = 'dailyFreePlayRounds';
        }

        // Day check
        final Timestamp? lastTs = userData['lastQuizDate'] as Timestamp?;
        bool isSameDay = false;
        if (lastTs != null) {
          final lastDate = lastTs.toDate();
          isSameDay = lastDate.year == now.year &&
              lastDate.month == now.month &&
              lastDate.day == now.day;
        }

        final int currentDaily = isSameDay ? _readInt(userData, dailyField) : 0;
        final int newDaily = currentDaily + 1;

        final userUpdates = <String, dynamic>{
          dailyField: newDaily,
        };

        if (!isSameDay) {
          if (dailyField != 'dailyStarsRounds')
            userUpdates['dailyStarsRounds'] = 0;
          if (dailyField != 'dailyProsRounds')
            userUpdates['dailyProsRounds'] = 0;
          if (dailyField != 'dailyFreePlayRounds')
            userUpdates['dailyFreePlayRounds'] = 0;
        }

        if (!isFreePlay) {
          userUpdates['points'] = FieldValue.increment(score);
          userUpdates[pointsField] = FieldValue.increment(score);
          userUpdates['lastQuizDate'] = timestampNow;
          userUpdates['updatedAt'] = timestampNow;
        } else {
          userUpdates['updatedAt'] = timestampNow;
        }

        // --- user_stats: update league sub-map
        final Map<String, dynamic> leagueMap = Map<String, dynamic>.from(
          rootData[normalizedLeagueKey] as Map? ?? <String, dynamic>{},
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

        final cleanRoot = <String, dynamic>{
          // ✅ Practical stability: avoid serverTimestamp equality edge-cases
          // If your rules currently require updatedAt == request.time, you'll need to relax that.
          // If rules accept "is timestamp", this will pass reliably.
          'updatedAt': timestampNow,
        };

        // preserve other leagues if present
        if (rootData.containsKey('stars'))
          cleanRoot['stars'] = rootData['stars'];
        if (rootData.containsKey('pros')) cleanRoot['pros'] = rootData['pros'];
        if (rootData.containsKey('freeplay'))
          cleanRoot['freeplay'] = rootData['freeplay'];

        cleanRoot[normalizedLeagueKey] = leagueMap;

        // ─────────────────────────────────────────────────────────────────────
        // WRITE PHASE (ALL WRITES LAST)
        // ─────────────────────────────────────────────────────────────────────
        transaction.set(userRef, userUpdates, SetOptions(merge: true));
        transaction.set(statsRef, cleanRoot);

        debugPrint('🟦 [QuizRepo] TXN prepared (writes queued)');
      });

      debugPrint('✅ [QuizRepo] COMMIT OK');
    } on FirebaseException catch (e) {
      debugPrint('❌ [QuizRepo] FIREBASE EXCEPTION code=${e.code}');
      debugPrint('❌ [QuizRepo] message=${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('❌ [QuizRepo] ERROR: $e');
      rethrow;
    }
  }
}

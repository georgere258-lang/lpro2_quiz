// PATH: lib/features/leaderboards/repositories/leaderboards_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/leaderboard_entry.dart';

/// المستودع المحدث: يقرأ من وثيقة ملخص واحدة لكل دوري لتوفير القراءات 90%
class LeaderboardsRepository {
  final FirebaseFirestore _firestore;

  LeaderboardsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ✅ تم تغيير المسار ليشير إلى وثيقة الملخص الموحدة في الكاش
  DocumentReference<Map<String, dynamic>> _leagueCacheRef(String league) {
    return _firestore.collection('leaderboard_cache').doc(league);
  }

  /// جلب الـ 10 الأوائل (قراءة وثيقة واحدة فقط)
  Future<List<LeaderboardEntry>> getTop10(String league) async {
    final doc = await _leagueCacheRef(league).get();
    if (!doc.exists || doc.data() == null) return [];

    final List<dynamic> entriesData = doc.data()!['entries'] ?? [];
    return entriesData
        .map((e) => LeaderboardEntry.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// بث الـ 10 الأوائل (بث وثيقة واحدة فقط - صفر نزيف عند التنقل)
  Stream<List<LeaderboardEntry>> streamTop10(String league) {
    return _leagueCacheRef(league).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return [];

      final List<dynamic> entriesData = doc.data()!['entries'] ?? [];
      return entriesData
          .map((e) => LeaderboardEntry.fromMap(e as Map<String, dynamic>))
          .toList();
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ADMIN ONLY: تحديث "الصحيفة الموحدة" بضغطة زر واحدة
  // ═══════════════════════════════════════════════════════════════════════════

  /// تحديث كافة الدوريات (يُستدعى من زر Refresh في لوحة التحكم)
  Future<void> refreshTop10AsAdmin() async {
    // 1. جلب بيانات المستخدمين (الأدمن فقط لديه صلاحية الوصول لـ users)
    final usersSnap = await _firestore
        .collection('users')
        .orderBy('points', descending: true)
        .limit(100)
        .get();

    final users = usersSnap.docs.map((d) {
      final data = d.data();
      return {
        'uid': d.id,
        'name': (data['name'] as String?) ?? 'مستخدم',
        'avatarIndex': (data['avatarIndex'] as int?) ?? 0,
        'points': (data['points'] as int?) ?? 0,
        'starsPoints': (data['starsPoints'] as int?) ?? 0,
        'proPoints': (data['proPoints'] as int?) ?? 0,
      };
    }).toList();

    // 2. تحديث كل دوري في وثيقة كاش منفصلة (عملية كتابة واحدة لكل دوري)
    await _updateLeagueCache('general', users, 'points');
    await _updateLeagueCache('stars', users, 'starsPoints');
    await _updateLeagueCache('pros', users, 'proPoints');
  }

  /// معالجة وحفظ الدوري في وثيقة ملخص واحدة
  Future<void> _updateLeagueCache(
    String league,
    List<Map<String, dynamic>> users,
    String pointsField,
  ) async {
    // ترتيب المستخدمين حسب نقاط الدوري
    final sorted = List<Map<String, dynamic>>.from(users)
      ..sort(
          (a, b) => (b[pointsField] as int).compareTo(a[pointsField] as int));

    // أخذ أفضل 10 فقط
    final top10 = sorted.take(10).toList();

    // تحويلهم لقائمة Maps جاهزة للتخزين
    final List<Map<String, dynamic>> entriesToStore = [];
    for (int i = 0; i < top10.length; i++) {
      final user = top10[i];
      entriesToStore.add({
        'uid': user['uid'],
        'name': user['name'],
        'avatarIndex': user['avatarIndex'],
        'points': user[pointsField],
        'rank': i + 1,
        'updatedAt': Timestamp.now(),
      });
    }

    // ✅ التوفير الأكبر: كتابة وثيقة واحدة تحتوي على القائمة كاملة
    // هذا يمسح القديم ويضع الجديد في "خبطة واحدة"
    await _leagueCacheRef(league).set({
      'league': league,
      'lastUpdate': FieldValue.serverTimestamp(),
      'entries': entriesToStore,
    });
  }
}

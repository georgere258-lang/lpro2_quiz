import 'package:cloud_firestore/cloud_firestore.dart';

class HomeProCardService {
  static const String _collection = 'home_pro_cards';

  final FirebaseFirestore _db;
  HomeProCardService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  /// Stream النص "الحالي" الذي يجب أن يظهر في الكارت الآن.
  ///
  /// ✅ لا يحتاج أي تعديل في HomeProCardContainer.
  /// ✅ يدعم: publishAt / expireAt / pinned / priority / isActive
  Stream<String?> streamText() {
    // نقرأ فقط العناصر الفعالة
    // ترتيب أولي: pinned ثم priority ثم publishAt (الأحدث أولاً)
    // ⚠️ قد تحتاج Index في Firestore للترتيب (لو طلبه منك Firebase Console اعمله).
    final q = _db
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .orderBy('pinned', descending: true)
        .orderBy('priority', descending: true)
        .orderBy('publishAt', descending: true)
        .limit(50);

    return q.snapshots().map((snap) {
      final now = DateTime.now();

      // فلترة محلية دقيقة حسب publishAt/expireAt
      for (final doc in snap.docs) {
        final data = doc.data();

        final text = (data['text'] ?? '').toString().trim();
        if (text.isEmpty) continue;

        final publishAt = _asDateTime(data['publishAt']);
        final expireAt = _asDateTime(data['expireAt']);

        // لو publishAt موجودة ولسه مجتش → تجاهل
        if (publishAt != null && now.isBefore(publishAt)) continue;

        // لو expireAt موجودة وعدّت → تجاهل
        if (expireAt != null && !now.isBefore(expireAt)) continue;

        // ✅ أول عنصر يطابق الشروط هو "المعلومة الحالية"
        return text;
      }

      // مفيش شيء مناسب الآن
      return null;
    });
  }

  // =========================
  // Helpers
  // =========================
  DateTime? _asDateTime(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    return null;
  }
}

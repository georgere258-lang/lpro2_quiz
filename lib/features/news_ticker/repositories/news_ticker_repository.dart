// PATH: lib/features/news_ticker/repositories/news_ticker_repository.dart
// STATUS: OPTIMIZED & READY ✅

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/firestore_paths.dart';

class NewsTickerRepository {
  final FirebaseFirestore _db;

  NewsTickerRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  static const String _col = FirestorePaths.newsTickerItems;

  Map<String, dynamic> _normalizeAndValidatePayload(
      Map<String, dynamic> input) {
    final out = Map<String, dynamic>.from(input);
    DateTime? startUtc;
    DateTime? endUtc;

    if (out['startDate'] is Timestamp) {
      startUtc = (out['startDate'] as Timestamp).toDate().toUtc();
      out['startDate'] = Timestamp.fromDate(startUtc);
    }
    if (out['endDate'] is Timestamp) {
      endUtc = (out['endDate'] as Timestamp).toDate().toUtc();
      out['endDate'] = Timestamp.fromDate(endUtc);
    }

    if (startUtc != null && endUtc != null && !startUtc.isBefore(endUtc)) {
      throw Exception('startDate must be before endDate');
    }

    return out;
  }

  /// مراقبة الأخبار للوحة التحكم (الترتيب بـ priority كما طلبت)
  Stream<QuerySnapshot<Map<String, dynamic>>> watchAllForAdmin() {
    return _db
        .collection(_col)
        .orderBy('priority', descending: true)
        .snapshots();
  }

  /// إضافة خبر جديد مع بصمة زمنية
  Future<void> addItem(Map<String, dynamic> payload) async {
    final data = _normalizeAndValidatePayload(payload);
    // نضمن وجود updatedAt ليعمل التحديث اللحظي عند المستخدمين
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _db.collection(_col).add(data);
  }

  /// تحديث خبر موجود مع تحديث البصمة الزمنية
  Future<void> updateItem(String docId, Map<String, dynamic> update) async {
    final data = _normalizeAndValidatePayload(update);
    // تحديث الوقت عند أي تعديل ليقفز الخبر للأمام عند المستخدم
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _db.collection(_col).doc(docId).update(data);
  }

  /// حذف خبر
  Future<void> deleteItem(String docId) async {
    await _db.collection(_col).doc(docId).delete();
  }

  /// تفعيل / إيقاف الخبر مع تحديث التوقيت لضمان اللحظية
  Future<void> toggleActive(String docId, bool currentActive) async {
    await _db.collection(_col).doc(docId).update({
      'isActive': !currentActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

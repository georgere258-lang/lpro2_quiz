import 'package:cloud_firestore/cloud_firestore.dart';

class NewsTickerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// المصدر الوحيد لشريط الأخبار
  Stream<List<Map<String, dynamic>>> streamTickerItems() {
    return _firestore
        .collection('news_ticker_items')
        .where('isActive', isEqualTo: true)
        .orderBy('priority', descending: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now();

      return snapshot.docs
          .where((doc) {
            final data = doc.data();

            final Timestamp? start = data['startDate'];
            final Timestamp? end = data['endDate'];

            if (start != null && now.isBefore(start.toDate())) return false;
            if (end != null && now.isAfter(end.toDate())) return false;

            return true;
          })
          .map((doc) => doc.data())
          .toList();
    });
  }

  /// إضافة خبر (يُستخدم من الأدمن أو من الرانك)
  Future<void> publishNews({
    required String textAr,
    int priority = 0,
    bool notify = false,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await _firestore.collection('news_ticker_items').add({
      'text_ar': textAr,
      'priority': priority,
      'isActive': true,
      'notify': notify,
      'startDate': startDate,
      'endDate': endDate,
      'createdAt': FieldValue.serverTimestamp(),
      'source': 'system', // admin / ranking
    });
  }
}

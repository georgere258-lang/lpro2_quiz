// PATH: lib/core/services/news_ticker_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class NewsTickerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Map<String, dynamic>>> streamTickerItems() {
    return _firestore
        .collection('news_ticker_items')
        .where('isActive', isEqualTo: true)
        // ✅ أهم تأمين: orderBy واحد فقط على حقل ثابت (مش serverTimestamp)
        .orderBy('priority', descending: true)
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now();

      // فلترة آمنة + منع النص الفارغ
      final filtered = snapshot.docs.where((doc) {
        final data = doc.data();

        final text = data['text_ar']?.toString().trim();
        if (text == null || text.isEmpty) return false;

        final Timestamp? start = data['startDate'] as Timestamp?;
        final Timestamp? end = data['endDate'] as Timestamp?;

        if (start != null && now.isBefore(start.toDate())) return false;
        if (end != null && now.isAfter(end.toDate())) return false;

        return true;
      }).toList();

      // ✅ ترتيب داخلي ثابت بدون ما نعتمد على Firestore orderBy لحقول قد تكون null
      filtered.sort((a, b) {
        final da = a.data();
        final db = b.data();

        int ta = _bestMillis(da);
        int tb = _bestMillis(db);

        // الأحدث أولاً
        if (ta != tb) return tb.compareTo(ta);

        // fallback ثابت لو الاتنين نفس التوقيت/صفر
        return b.id.compareTo(a.id);
      });

      return filtered.map((d) => d.data()).toList();
    });
  }

  int _bestMillis(Map<String, dynamic> data) {
    final Timestamp? u = data['updatedAt'] as Timestamp?;
    if (u != null) return u.millisecondsSinceEpoch;

    final Timestamp? c = data['createdAt'] as Timestamp?;
    if (c != null) return c.millisecondsSinceEpoch;

    return 0;
  }

  Future<void> publishNews({
    required String textAr,
    int priority = 0,
    bool notify = false,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final trimmed = textAr.trim();
    if (trimmed.isEmpty) return;

    final nowTs = Timestamp.now();

    final data = <String, dynamic>{
      'text_ar': trimmed,
      'priority': priority,
      'isActive': true,
      'notify': notify,

      // ✅ updatedAt ثابت فوراً (مش serverTimestamp) عشان أي Sorting/Screen يعتمد عليه
      'updatedAt': nowTs,

      // نسيب createdAt زي ما هو موجود عندك (مش مؤثر على الاستعلام الآن)
      'createdAt': FieldValue.serverTimestamp(),

      'source': 'system', // admin / ranking
    };

    if (startDate != null) {
      data['startDate'] = Timestamp.fromDate(startDate);
    }
    if (endDate != null) {
      data['endDate'] = Timestamp.fromDate(endDate);
    }

    await _firestore.collection('news_ticker_items').add(data);
  }
}

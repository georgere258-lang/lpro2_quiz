import 'package:cloud_firestore/cloud_firestore.dart';

class HomeProCardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream الكارت النشط فقط
  Stream<String?> streamText() {
    return _firestore
        .collection('home_pro_items')
        .where('isActive', isEqualTo: true)
        .orderBy('priority', descending: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now();

      for (final doc in snapshot.docs) {
        final data = doc.data();

        final Timestamp? start = data['startDate'];
        final Timestamp? end = data['endDate'];

        if (start != null && now.isBefore(start.toDate())) continue;
        if (end != null && now.isAfter(end.toDate())) continue;

        final text = (data['text'] ?? '').toString().trim();
        if (text.isNotEmpty) {
          return text;
        }
      }
      return null;
    });
  }

  /// نشر معلومة (يستخدمها الأدمن لاحقًا)
  Future<void> publish({
    required String text,
    int priority = 0,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await _firestore.collection('home_pro_items').add({
      'text': text,
      'priority': priority,
      'isActive': true,
      'startDate': startDate,
      'endDate': endDate,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class NewsTickerConfigService {
  final DocumentReference _doc =
      FirebaseFirestore.instance.collection('news_ticker_config').doc('global');

  Stream<bool> streamEmbeddedEnabled() {
    return _doc.snapshots().map((snapshot) {
      if (!snapshot.exists) return true; // default ON
      final data = snapshot.data() as Map<String, dynamic>;
      return data['enableEmbeddedMessages'] ?? true;
    });
  }

  Future<void> setEmbeddedEnabled(bool value) async {
    await _doc.set({
      'enableEmbeddedMessages': value,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

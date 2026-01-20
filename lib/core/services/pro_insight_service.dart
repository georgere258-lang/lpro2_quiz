import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/pro_insight_model.dart';

class ProInsightService {
  final _collection = FirebaseFirestore.instance.collection('pro_insight');

  Stream<List<ProInsightModel>> streamActiveInsights() {
    return _collection
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProInsightModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> addInsight(ProInsightModel model) async {
    await _collection.add(model.toMap());
  }

  Future<void> toggleActive(String id, bool value) async {
    await _collection.doc(id).update({'isActive': value});
  }

  Future<void> deleteInsight(String id) async {
    await _collection.doc(id).delete();
  }
}

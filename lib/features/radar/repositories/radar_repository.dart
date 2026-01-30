// PATH: lib/features/radar/repositories/radar_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_paths.dart';
import '../models/radar_item.dart';

class RadarRepository {
  final FirebaseFirestore _db;

  RadarRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestorePaths.marketRadar);

  Stream<List<RadarItem>> watchAll() {
    return _col.orderBy('control.orderInSection').snapshots().map(
          (q) => q.docs
              .map((d) => RadarItem.fromFirestore(d.id, d.data()))
              .toList(),
        );
  }

  Future<void> create(RadarItem item) async {
    item.validate();

    final doc = _col.doc();
    final data = item.copyWith(id: doc.id).toFirestore();

    await doc.set({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    await _col.doc(id).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }
}

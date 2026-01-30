import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/money_item.dart';

class MoneyRepository {
  final FirebaseFirestore _db;

  static const String _collection = 'money_items';

  MoneyRepository(this._db);

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(_collection);

  // ─────────────────────────────────────────────
  // Watch
  // ─────────────────────────────────────────────
  Stream<List<MoneyItem>> watchAll() {
    return _col.orderBy('control.orderInSection').snapshots().map(
          (q) => q.docs
              .map((d) => MoneyItem.fromFirestore(d.id, d.data()))
              .toList(),
        );
  }

  // ─────────────────────────────────────────────
  // Create
  // ─────────────────────────────────────────────
  Future<void> create(MoneyItem item) async {
    final doc = _col.doc();

    await doc.set({
      'title': item.title.trim(),
      'body': item.body.trim(),
      'isFeatured': item.isFeatured,
      'isImportant': item.isImportant,
      'control': item.control,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ─────────────────────────────────────────────
  // Update
  // ─────────────────────────────────────────────
  Future<void> update(String id, Map<String, dynamic> data) async {
    await _col.doc(id).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ─────────────────────────────────────────────
  // Delete
  // ─────────────────────────────────────────────
  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }
}

// PATH: lib/features/money/repositories/money_repository.dart
// STATUS: FULL FILE ✅ (android/experiments-v2 only) — adds isActive + isArchived filtering
// NOTE: This stays in experiments for now; we will move to android/stable later in a separate step.

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/money_item.dart';

class MoneyRepository {
  final FirebaseFirestore _db;

  // ✅ IMPORTANT: Keep this aligned with the current Money/Economy collection used in android/stable.
  // If your stable currently uses a different collection name (e.g., 'money' / 'money_items'),
  // do NOT change it here without an explicit decision.
  static const String _collection = 'money_items';

  MoneyRepository(this._db);

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(_collection);

  // ─────────────────────────────────────────────
  // Watch (Active + Not Archived only)
  // ─────────────────────────────────────────────
  Stream<List<MoneyItem>> watchAll() {
    return _col
        .where('isArchived', isEqualTo: false)
        .where('isActive', isEqualTo: true)
        .orderBy('control.orderInSection')
        .snapshots()
        .map(
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
      // ✅ Defaults aligned with Radar/Economy system
      'isActive': true,
      'isArchived': false,
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

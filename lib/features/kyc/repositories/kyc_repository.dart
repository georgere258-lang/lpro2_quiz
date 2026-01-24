// PATH: lib/features/kyc/repositories/kyc_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../core/models/admin_control_models.dart';
import '../models/kyc_item.dart';

/// Repository for KYC (Know Your Client) operations.
class KycRepository {
  final FirebaseFirestore _firestore;
  late final CollectionReference<Map<String, dynamic>> _collection;

  KycRepository([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance {
    _collection = _firestore.collection(FirestorePaths.knowYourClient);
  }

  /// Watches active KYC items ordered by orderInSection descending.
  Stream<List<KycItem>> watchActive() {
    return _collection
        .where('isActive', isEqualTo: true)
        .orderBy('orderInSection', descending: true)
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs.map((d) => KycItem.fromFirestore(d.data(), d.id)).toList());
  }

  /// Watches all KYC items.
  Stream<List<KycItem>> watchAll() {
    return _collection
        .orderBy('orderInSection', descending: true)
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs.map((d) => KycItem.fromFirestore(d.data(), d.id)).toList());
  }

  /// Creates a new KYC item and returns its ID.
  Future<String> create(KycItem item) async {
    item.validate();

    final data = item.toFirestore();
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();

    final docRef = await _collection.add(data);
    return docRef.id;
  }

  /// Updates a KYC item with the given fields.
  Future<void> update(String id, Map<String, dynamic> updates) async {
    final sanitized = <String, dynamic>{};

    for (final entry in updates.entries) {
      final value = entry.value;
      if (value is DateTime) {
        sanitized[entry.key] = UtcNormalizer.toTimestamp(value);
      } else {
        sanitized[entry.key] = value;
      }
    }

    sanitized['updatedAt'] = FieldValue.serverTimestamp();
    await _collection.doc(id).update(sanitized);
  }

  /// Toggles the active state of a KYC item.
  Future<void> toggleActive(String id, bool isActive) async {
    await _collection.doc(id).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Reorders a KYC item to a new position.
  Future<void> reorder(String id, int newOrder) async {
    await _collection.doc(id).update({
      'orderInSection': newOrder,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Permanently deletes a KYC item (hard delete).
  Future<void> delete(String id) async {
    await _collection.doc(id).delete();
  }
}

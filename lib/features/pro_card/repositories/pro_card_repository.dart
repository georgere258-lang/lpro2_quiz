// PATH: lib/features/pro_card/repositories/pro_card_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../core/models/admin_control_models.dart';
import '../models/pro_card_banner.dart';

/// Repository for Pro Card banner operations.
class ProCardRepository {
  final FirebaseFirestore _firestore;
  late final DocumentReference<Map<String, dynamic>> _docRef;

  ProCardRepository([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance {
    _docRef = _firestore
        .collection(FirestorePaths.homeProCard)
        .doc(FirestorePaths.currentDoc);
  }

  /// Watches the current pro card banner.
  Stream<ProCardBanner?> watchCurrent() {
    return _docRef.snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return ProCardBanner.fromFirestore(snap.data()!, snap.id);
    });
  }

  /// Gets the current pro card banner.
  Future<ProCardBanner?> getCurrent() async {
    final snap = await _docRef.get();
    if (!snap.exists || snap.data() == null) return null;
    return ProCardBanner.fromFirestore(snap.data()!, snap.id);
  }

  /// Creates or updates the current pro card banner.
  Future<void> upsertCurrent({
    required String text,
    required bool isActive,
    DateTime? publishAt,
    DateTime? expireAt,
    bool clearPublishAt = false,
    bool clearExpireAt = false,
  }) async {
    final control = AdminControlFields(
      isActive: isActive,
      publishAt: clearPublishAt ? null : publishAt,
      expireAt: clearExpireAt ? null : expireAt,
      sectionKey: FirestorePaths.sectionKeyProCard,
    );

    final model = ProCardBanner(
      id: FirestorePaths.currentDoc,
      text: text.trim(),
      control: control,
    );
    model.validate();

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(_docRef);
      final data = model.toFirestore();

      // Handle publishAt/expireAt deletion
      if (clearPublishAt && publishAt == null) {
        data['publishAt'] = FieldValue.delete();
      }
      if (clearExpireAt && expireAt == null) {
        data['expireAt'] = FieldValue.delete();
      }

      data['updatedAt'] = FieldValue.serverTimestamp();

      if (!snap.exists) {
        data['createdAt'] = FieldValue.serverTimestamp();
        tx.set(_docRef, data);
      } else {
        tx.update(_docRef, data);
      }
    });
  }

  /// Toggles the active state of the current pro card.
  Future<void> toggleActive(bool isActive) async {
    await _docRef.update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

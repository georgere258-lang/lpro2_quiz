// PATH: lib/features/pro_card/repositories/pro_card_repository.dart
// Pro Card = single live message (home_pro_card/current).

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/firestore_paths.dart';

class ProCardRepository {
  final FirebaseFirestore _firestore;

  ProCardRepository([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<Map<String, dynamic>?> watchCurrent() {
    return _firestore
        .collection(FirestorePaths.proCardCurrent)
        .doc(FirestorePaths.currentDoc)
        .snapshots()
        .map((s) => s.data());
  }

  Future<void> setCurrent({
    required String text,
    required bool isActive,
    DateTime? publishAt,
    DateTime? expireAt,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw Exception('Pro Card text cannot be empty');
    }

    // Convert to UTC for consistent storage
    final DateTime? publishUtc = publishAt?.toUtc();
    final DateTime? expireUtc = expireAt?.toUtc();

    // Validate invariant: publishAt must be before expireAt if both are set
    if (publishUtc != null && expireUtc != null && !publishUtc.isBefore(expireUtc)) {
      throw Exception('publishAt must be before expireAt');
    }

    final Map<String, dynamic> data = {
      'text': trimmed,
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // ✅ delete keys is only safe with merge:true
    if (publishUtc != null) {
      data['publishAt'] = Timestamp.fromDate(publishUtc);
    } else {
      data['publishAt'] = FieldValue.delete();
    }

    if (expireUtc != null) {
      data['expireAt'] = Timestamp.fromDate(expireUtc);
    } else {
      data['expireAt'] = FieldValue.delete();
    }

    await _firestore
        .collection(FirestorePaths.proCardCurrent)
        .doc(FirestorePaths.currentDoc)
        .set(data, SetOptions(merge: true)); // ✅ FIX
  }
}

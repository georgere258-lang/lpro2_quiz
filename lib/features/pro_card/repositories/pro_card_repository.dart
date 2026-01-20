// PATH: lib/features/pro_card/repositories/pro_card_repository.dart
// Pro Card = single live message (home_pro_card/current). No list, history, or archive.

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_paths.dart';

class ProCardRepository {
  final FirebaseFirestore _firestore;

  ProCardRepository([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Stream of the single current document. Null if it does not exist yet.
  Stream<Map<String, dynamic>?> watchCurrent() {
    return _firestore
        .collection(FirestorePaths.proCardCurrent)
        .doc(FirestorePaths.currentDoc)
        .snapshots()
        .map((s) => s.data());
  }

  /// Overwrites home_pro_card/current with the given fields. Creates the doc if it does not exist.
  Future<void> setCurrent({
    required String text,
    required bool isActive,
    DateTime? publishAt,
    DateTime? expireAt,
  }) async {
    final m = <String, dynamic>{
      'text': text,
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (publishAt != null) {
      m['publishAt'] = Timestamp.fromDate(publishAt);
    } else {
      m['publishAt'] = FieldValue.delete();
    }
    if (expireAt != null) {
      m['expireAt'] = Timestamp.fromDate(expireAt);
    } else {
      m['expireAt'] = FieldValue.delete();
    }
    await _firestore
        .collection(FirestorePaths.proCardCurrent)
        .doc(FirestorePaths.currentDoc)
        .set(m);
  }
}

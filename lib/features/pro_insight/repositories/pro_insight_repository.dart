// PATH: lib/features/pro_insight/repositories/pro_insight_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_paths.dart';

/// Repository for Pro Insight admin write operations.
class ProInsightRepository {
  final FirebaseFirestore _db;

  ProInsightRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  static const String _col = FirestorePaths.proInsight;

  /// Get document reference by ID.
  DocumentReference<Map<String, dynamic>> docById(String docId) {
    return _db.collection(_col).doc(docId);
  }

  /// Normalize UTC for publishAt/featuredUntil and validate invariants.
  Map<String, dynamic> _normalizeAndValidateUpdate(Map<String, dynamic> input) {
    final out = Map<String, dynamic>.from(input);
    DateTime? publishAtUtc;
    DateTime? featuredUntilUtc;

    // Normalize publishAt
    if (out.containsKey('publishAt')) {
      final val = out['publishAt'];
      if (val is DateTime) {
        publishAtUtc = val.toUtc();
        out['publishAt'] = Timestamp.fromDate(publishAtUtc);
      } else if (val is Timestamp) {
        publishAtUtc = val.toDate().toUtc();
        out['publishAt'] = Timestamp.fromDate(publishAtUtc);
      }
      // FieldValue (delete/serverTimestamp) stays as-is
    }

    // Normalize featuredUntil
    if (out.containsKey('featuredUntil')) {
      final val = out['featuredUntil'];
      if (val is DateTime) {
        featuredUntilUtc = val.toUtc();
        out['featuredUntil'] = Timestamp.fromDate(featuredUntilUtc);
      } else if (val is Timestamp) {
        featuredUntilUtc = val.toDate().toUtc();
        out['featuredUntil'] = Timestamp.fromDate(featuredUntilUtc);
      }
      // FieldValue (delete/serverTimestamp) stays as-is
    }

    // Invariant: publishAt must be before featuredUntil if both exist
    if (publishAtUtc != null &&
        featuredUntilUtc != null &&
        !publishAtUtc.isBefore(featuredUntilUtc)) {
      throw Exception('publishAt must be before featuredUntil');
    }

    return out;
  }

  /// Update a document with normalized timestamps and validation.
  Future<void> update(String docId, Map<String, dynamic> update) async {
    await _db
        .collection(_col)
        .doc(docId)
        .update(_normalizeAndValidateUpdate(update));
  }

  /// Delete a document.
  Future<void> delete(String docId) async {
    await _db.collection(_col).doc(docId).delete();
  }
}

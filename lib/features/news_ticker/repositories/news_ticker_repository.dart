// PATH: lib/features/news_ticker/repositories/news_ticker_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_paths.dart';

/// Repository for News Ticker admin CRUD operations.
class NewsTickerRepository {
  final FirebaseFirestore _db;

  NewsTickerRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  static const String _col = FirestorePaths.newsTickerItems;

  /// Normalize startDate/endDate to UTC and validate invariant.
  /// Leaves FieldValue.delete() and other types untouched.
  Map<String, dynamic> _normalizeAndValidatePayload(Map<String, dynamic> input) {
    final out = Map<String, dynamic>.from(input);
    DateTime? startUtc;
    DateTime? endUtc;

    if (out['startDate'] is Timestamp) {
      startUtc = (out['startDate'] as Timestamp).toDate().toUtc();
      out['startDate'] = Timestamp.fromDate(startUtc);
    }
    if (out['endDate'] is Timestamp) {
      endUtc = (out['endDate'] as Timestamp).toDate().toUtc();
      out['endDate'] = Timestamp.fromDate(endUtc);
    }

    if (startUtc != null && endUtc != null && !startUtc.isBefore(endUtc)) {
      throw Exception('startDate must be before endDate');
    }

    return out;
  }

  /// Watch all ticker items for admin panel (ordered by priority desc).
  /// Admin panel applies additional client-side sorting.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchAllForAdmin() {
    return _db
        .collection(_col)
        .orderBy('priority', descending: true)
        .snapshots();
  }

  /// Add a new ticker item.
  Future<void> addItem(Map<String, dynamic> payload) async {
    await _db.collection(_col).add(_normalizeAndValidatePayload(payload));
  }

  /// Update an existing ticker item.
  Future<void> updateItem(String docId, Map<String, dynamic> update) async {
    await _db.collection(_col).doc(docId).update(_normalizeAndValidatePayload(update));
  }

  /// Delete a ticker item.
  Future<void> deleteItem(String docId) async {
    await _db.collection(_col).doc(docId).delete();
  }

  /// Toggle isActive and update timestamp.
  Future<void> toggleActive(String docId, bool currentActive) async {
    await _db.collection(_col).doc(docId).update({
      'isActive': !currentActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

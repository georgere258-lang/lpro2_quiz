import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/firestore_paths.dart';

/// مصدر واحد: home_pro_card/current. لا list ولا history ولا archive.
///
/// يرجّع text فقط لو:
///   isActive && (publishAt == null || publishAt <= now) && (expireAt == null || now < expireAt)
/// لو الشرط false أو text فاضي => null.
class HomeProCardService {
  final FirebaseFirestore _db;
  HomeProCardService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  Stream<String?> streamText() {
    return _db
        .collection(FirestorePaths.proCardCurrent)
        .doc(FirestorePaths.currentDoc)
        .snapshots()
        .map((snap) {
      final d = snap.data();
      if (d == null) return null;

      final isActive = d['isActive'] == true;
      final publishAt = _asDateTime(d['publishAt']);
      final expireAt = _asDateTime(d['expireAt']);
      final now = DateTime.now();

      if (!isActive) return null;
      if (publishAt != null && now.isBefore(publishAt)) return null;
      if (expireAt != null && !now.isBefore(expireAt)) return null;

      final text = (d['text'] ?? '').toString().trim();
      return text.isEmpty ? null : text;
    });
  }

  DateTime? _asDateTime(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    return null;
  }
}

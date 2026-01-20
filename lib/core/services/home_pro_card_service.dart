import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/firestore_paths.dart';

class HomeProCardService {
  final FirebaseFirestore _db;
  HomeProCardService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  static const _cacheKey = 'cached_home_pro_card_text';

  Stream<String?> streamText() {
    return _db
        .collection(FirestorePaths.proCardCurrent)
        .doc(FirestorePaths.currentDoc)
        .snapshots()
        .asyncMap((snap) async {
      final d = snap.data();

      // لو الدوك مش موجود → رجّع المخزن
      if (d == null) {
        return _readCached();
      }

      final isActive = d['isActive'] == true;
      final publishAt = _asDateTime(d['publishAt']);
      final expireAt = _asDateTime(d['expireAt']);
      final now = DateTime.now();

      if (!isActive) return _readCached();
      if (publishAt != null && now.isBefore(publishAt)) return _readCached();
      if (expireAt != null && !now.isBefore(expireAt)) return _readCached();

      final text = (d['text'] ?? '').toString().trim();
      if (text.isEmpty) return _readCached();

      // ✅ خزّن آخر قيمة صحيحة
      await _cache(text);
      return text;
    });
  }

  Future<void> _cache(String text) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_cacheKey, text);
  }

  Future<String?> _readCached() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_cacheKey);
  }

  DateTime? _asDateTime(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    return null;
  }
}

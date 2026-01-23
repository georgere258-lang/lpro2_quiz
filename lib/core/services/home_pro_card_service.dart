// PATH: lib/core/services/home_pro_card_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/firestore_paths.dart';

/// مصدر واحد: home_pro_card/current
/// يُرجِع نصًا صالحًا لو:
/// isActive && (publishAt == null || publishAt <= now) && (expireAt == null || now < expireAt)
/// مع Cache محلي لمنع الوميض والاختفاء المؤقت.
class HomeProCardService {
  final FirebaseFirestore _db;
  HomeProCardService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  static const _cacheKey = 'home_pro_card_last_text';

  Stream<String?> streamText() async* {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey);

    // بثّ القيمة المخزنة فورًا (إن وُجدت) لمنع الوميض
    if (cached != null && cached.trim().isNotEmpty) {
      yield cached;
    }

    yield* _db
        .collection(FirestorePaths.proCardCurrent)
        .doc(FirestorePaths.currentDoc)
        .snapshots()
        .map((snap) {
      final d = snap.data();
      if (d == null) return null;

      final isActive = d['isActive'] == true;
      final publishAt = _asDateTime(d['publishAt']);
      final expireAt = _asDateTime(d['expireAt']);
      final now = DateTime.now().toUtc();

      // Convert timestamps to UTC for consistent comparison
      final publishUtc = publishAt?.toUtc();
      final expireUtc = expireAt?.toUtc();

      if (!isActive) return null;
      if (publishUtc != null && now.isBefore(publishUtc)) return null;
      if (expireUtc != null && !now.isBefore(expireUtc)) return null;

      final text = (d['text'] ?? '').toString().trim();
      return text.isEmpty ? null : text;
    }).asyncMap((text) async {
      // تحديث الكاش عند وجود نص صالح
      if (text != null && text.trim().isNotEmpty) {
        await prefs.setString(_cacheKey, text);
        return text;
      }
      // fallback: رجّع آخر قيمة محفوظة بدل الاختفاء
      return cached;
    });
  }

  DateTime? _asDateTime(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    return null;
  }
}

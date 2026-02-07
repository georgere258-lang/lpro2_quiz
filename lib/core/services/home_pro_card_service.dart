// PATH: lib/core/services/home_pro_card_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/firestore_paths.dart';
import '../../features/pro_card/models/pro_card_banner.dart';
import '../../core/models/admin_control_models.dart';

/// مصدر واحد: home_pro_card/current
/// يُرجِع ProCardBanner صالح لو:
/// isActive && (publishAt == null || publishAt <= now) && (expireAt == null || now < expireAt)
/// مع Cache محلي لمنع الوميض والاختفاء المؤقت.
class HomeProCardService {
  final FirebaseFirestore _db;
  HomeProCardService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  static const _cacheTypeKey = 'home_pro_card_last_type';
  static const _cacheTextKey = 'home_pro_card_last_text';
  static const _cacheImageKey = 'home_pro_card_last_image';

  Stream<ProCardBanner?> streamBanner() async* {
    final prefs = await SharedPreferences.getInstance();
    final cachedTypeStr = prefs.getString(_cacheTypeKey);
    final cachedText = prefs.getString(_cacheTextKey);
    final cachedImage = prefs.getString(_cacheImageKey);

    ProCardBanner? cachedBanner;

    if ((cachedText != null && cachedText.trim().isNotEmpty) ||
        (cachedImage != null && cachedImage.trim().isNotEmpty)) {
      final type = (cachedTypeStr ?? 'text').toLowerCase() == 'image'
          ? ProCardContentType.image
          : ProCardContentType.text;

      cachedBanner = ProCardBanner(
        id: FirestorePaths.currentDoc,
        text: cachedText ?? '',
        imageUrl: cachedImage ?? '',
        contentType: type,
        control: AdminControlFields(
          isActive: true,
          publishAt: null,
          expireAt: null,
          sectionKey: FirestorePaths.sectionKeyProCard,
        ),
      );

      // بثّ القيمة المخزنة فورًا (إن وُجدت) لمنع الوميض
      yield cachedBanner;
    }

    yield* _db
        .collection(FirestorePaths.homeProCard)
        .doc(FirestorePaths.currentDoc)
        .snapshots()
        .map((snap) {
      final d = snap.data();
      if (d == null) return null;

      final banner = ProCardBanner.fromFirestore(d, snap.id);

      final now = DateTime.now().toUtc();
      final publishUtc = banner.publishAt?.toUtc();
      final expireUtc = banner.expireAt?.toUtc();

      if (!banner.isActive) return null;
      if (publishUtc != null && now.isBefore(publishUtc)) return null;
      if (expireUtc != null && !now.isBefore(expireUtc)) return null;

      // تحقق من المحتوى حسب النوع
      if (banner.isText) {
        return banner.text.trim().isEmpty ? null : banner;
      } else {
        return banner.imageUrl.trim().isEmpty ? null : banner;
      }
    }).asyncMap((banner) async {
      if (banner != null) {
        await prefs.setString(_cacheTypeKey, banner.isImage ? 'image' : 'text');
        await prefs.setString(_cacheTextKey, banner.text.trim());
        await prefs.setString(_cacheImageKey, banner.imageUrl.trim());
        return banner;
      }
      // fallback: رجّع آخر قيمة محفوظة بدل الاختفاء
      return cachedBanner;
    });
  }
}

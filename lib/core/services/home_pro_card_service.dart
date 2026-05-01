// PATH: lib/core/services/home_pro_card_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/firestore_paths.dart';
import '../../features/pro_card/models/pro_card_banner.dart';
import '../../core/models/admin_control_models.dart';

class HomeProCardService {
  final FirebaseFirestore _db;
  HomeProCardService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  static const _cacheTypeKey = 'home_pro_card_last_type';
  static const _cacheTextKey = 'home_pro_card_last_text';
  static const _cacheImageKey = 'home_pro_card_last_image';

  Stream<ProCardBanner?> streamBanner() async* {
    final prefs = await SharedPreferences.getInstance();

    // 1. إرسال الكاش فوراً (صفر قراءة من فايربيز)
    ProCardBanner? cached = _loadFromCache(prefs);
    if (cached != null) yield cached;

    try {
      // 2. طلب الوثيقة "مرة واحدة" فقط (قراءة واحدة فقط)
      // ✅ استبدلنا snapshots بـ get لمنع النزيف المستمر
      final snap = await _db
          .collection(FirestorePaths.homeProCard)
          .doc(FirestorePaths.currentDoc)
          .get();

      final data = snap.data();
      if (data == null) {
        yield null;
        return;
      }

      final banner = ProCardBanner.fromFirestore(data, snap.id);

      // 3. فحص الصلاحية (Admin Logic)
      if (_isValid(banner)) {
        await _saveToCache(prefs, banner);
        yield banner;
      } else {
        yield null;
      }
    } catch (e) {
      // في حالة الخطأ، نكتفي بالكاش إذا كان موجوداً
      if (cached != null) yield cached;
    }
  }

  bool _isValid(ProCardBanner banner) {
    final now = DateTime.now().toUtc();
    if (!banner.isActive) return false;
    if (banner.publishAt != null && now.isBefore(banner.publishAt!.toUtc())) {
      return false;
    }
    if (banner.expireAt != null && !now.isAfter(banner.expireAt!.toUtc())) {
      return false;
    }
    return banner.isText
        ? banner.text.trim().isNotEmpty
        : banner.imageUrl.trim().isNotEmpty;
  }

  ProCardBanner? _loadFromCache(SharedPreferences prefs) {
    final text = prefs.getString(_cacheTextKey);
    final img = prefs.getString(_cacheImageKey);
    if ((text == null || text.isEmpty) && (img == null || img.isEmpty)) {
      return null;
    }

    return ProCardBanner(
      id: FirestorePaths.currentDoc,
      text: text ?? '',
      imageUrl: img ?? '',
      contentType: prefs.getString(_cacheTypeKey) == 'image'
          ? ProCardContentType.image
          : ProCardContentType.text,
      control: AdminControlFields(
        isActive: true,
        sectionKey: FirestorePaths.sectionKeyProCard,
      ),
    );
  }

  Future<void> _saveToCache(
      SharedPreferences prefs, ProCardBanner banner) async {
    await prefs.setString(_cacheTypeKey, banner.isImage ? 'image' : 'text');
    await prefs.setString(_cacheTextKey, banner.text.trim());
    await prefs.setString(_cacheImageKey, banner.imageUrl.trim());
  }
}

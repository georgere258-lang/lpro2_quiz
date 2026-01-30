// PATH: lib/core/services/market_content_cms_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class MarketContentCmsService {
  MarketContentCmsService(this._db);

  final FirebaseFirestore _db;

  // Collections (خليهم هنا مؤقتاً، وبعد ما تفتح firestore_paths.dart ننقلها Constants)
  static const String cMarketRadar = 'market_radar_items';
  static const String cMoneyEconomy = 'money_economy_items';

  CollectionReference<Map<String, dynamic>> col(String sectionKey) {
    switch (sectionKey) {
      case 'market_radar':
        return _db.collection(cMarketRadar);
      case 'money_economy':
        return _db.collection(cMoneyEconomy);
      default:
        throw ArgumentError('Unknown sectionKey: $sectionKey');
    }
  }

  // ---------- CRUD ----------
  Future<void> createItem({
    required String sectionKey,
    required String title,
    required String subtitle,
    required String typeKey, // quick | medium | deep | case | zone (حسب تصميمك)
    required Map<String, dynamic> payload, // محتوى الـ BottomSheet / Reader
    int? orderInSection,
    bool isActive = true,
    bool isPinned = false,
    int? publishAtMs,
    int? expireAtMs,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    final docRef = col(sectionKey).doc();
    await docRef.set({
      'title': title.trim(),
      'subtitle': subtitle.trim(),
      'typeKey': typeKey,
      'payload': payload,
      'isActive': isActive,
      'isPinned': isPinned,
      'orderInSection': orderInSection ?? now, // fallback ترتيب تلقائي
      'publishAtMs': publishAtMs,
      'expireAtMs': expireAtMs,
      'createdAtMs': now,
      'updatedAtMs': now,
    });
  }

  Future<void> updateItem({
    required String sectionKey,
    required String docId,
    required Map<String, dynamic> patch,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await col(sectionKey).doc(docId).update({
      ...patch,
      'updatedAtMs': now,
    });
  }

  Future<void> deleteItem({
    required String sectionKey,
    required String docId,
  }) async {
    await col(sectionKey).doc(docId).delete();
  }

  Future<void> togglePinned({
    required String sectionKey,
    required String docId,
    required bool newValue,
  }) async {
    await updateItem(
        sectionKey: sectionKey, docId: docId, patch: {'isPinned': newValue});
  }

  Future<void> toggleActive({
    required String sectionKey,
    required String docId,
    required bool newValue,
  }) async {
    await updateItem(
        sectionKey: sectionKey, docId: docId, patch: {'isActive': newValue});
  }

  // ---------- ORDERING: Move Up/Down ----------
  // يعتمد على orderInSection (int). الفكرة: swap بين item الحالي والـ neighbor.
  Future<void> move({
    required String sectionKey,
    required String docId,
    required bool up,
  }) async {
    final sectionCol = col(sectionKey);

    await _db.runTransaction((tx) async {
      final currentRef = sectionCol.doc(docId);
      final currentSnap = await tx.get(currentRef);
      if (!currentSnap.exists) return;

      final cur = currentSnap.data()!;
      final int curOrder = (cur['orderInSection'] as num?)?.toInt() ?? 0;

      // نجيب الجار: لو Up => أقرب order أقل / لو Down => أقرب order أكبر
      Query<Map<String, dynamic>> q = sectionCol
          .where('isActive', isEqualTo: true)
          .orderBy('orderInSection', descending: up);

      // علشان نختار جار صحيح: نقرأ مجموعة صغيرة ونحدد محلياً
      final querySnap = await q.limit(30).get();

      DocumentSnapshot<Map<String, dynamic>>? neighbor;
      for (final d in querySnap.docs) {
        if (d.id == docId) continue;
        final int o = (d.data()['orderInSection'] as num?)?.toInt() ?? 0;

        if (up) {
          if (o < curOrder) {
            neighbor = d;
            break;
          }
        } else {
          if (o > curOrder) {
            neighbor = d;
            break;
          }
        }
      }

      if (neighbor == null) return;

      final neighborRef = sectionCol.doc(neighbor.id);
      final int nOrder =
          (neighbor.data()!['orderInSection'] as num?)?.toInt() ?? 0;

      // swap
      tx.update(currentRef, {
        'orderInSection': nOrder,
        'updatedAtMs': DateTime.now().millisecondsSinceEpoch
      });
      tx.update(neighborRef, {
        'orderInSection': curOrder,
        'updatedAtMs': DateTime.now().millisecondsSinceEpoch
      });
    });
  }
}

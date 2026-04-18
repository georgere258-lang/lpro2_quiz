// PATH: lib/core/services/news_ticker_service.dart
// STATUS: FULL FILE - ULTRA-OPTIMIZED (Realtime-Only) ✅

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/firestore_paths.dart'; // تأكد من صحة المسار النسبي

class NewsTickerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _col = FirestorePaths.newsTickerItems;

  /// 🌟 نظام الاستماع اللحظي المطور
  Stream<List<Map<String, dynamic>>> streamTickerItems() {
    // الترتيب حسب الأولوية ثم الأحدث تعديلاً
    final query = _firestore
        .collection(_col)
        .where('isActive', isEqualTo: true)
        .orderBy('priority', descending: true)
        .orderBy('updatedAt', descending: true);

    final controller = StreamController<List<Map<String, dynamic>>>.broadcast();
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? sub;
    String lastSignature = '';

    // معالجة البيانات والفلترة الزمنية
    List<Map<String, dynamic>> mapSnapshot(
        QuerySnapshot<Map<String, dynamic>> snapshot) {
      final now = DateTime.now().toUtc();

      return snapshot.docs.where((doc) {
        final data = doc.data();

        // جلب التواريخ بأمان
        final Timestamp? start = data['startDate'] as Timestamp?;
        final Timestamp? end = data['endDate'] as Timestamp?;

        final startUtc = start?.toDate().toUtc();
        final endUtc = end?.toDate().toUtc();

        // 1. فلترة الوقت: يختفي الخبر فور انتهاء مدته
        if (startUtc != null && now.isBefore(startUtc)) return false;
        if (endUtc != null && !now.isBefore(endUtc)) return false;

        // 2. التأكد من وجود نص
        final text = data['text_ar']?.toString().trim();
        if (text == null || text.isEmpty) return false;

        return true;
      }).map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // إضافة الـ ID للبيانات للضرورة
        return data;
      }).toList();
    }

    void emitIfChanged(List<Map<String, dynamic>> items, {String src = ''}) {
      // الـ Signature يعتمد على النص والتوقيت لضمان التحديث عند تغيير المحتوى
      final sig = items
          .map((e) =>
              '${(e['text_ar'] ?? '')}|${(e['updatedAt'] ?? '')}|${(e['priority'] ?? 0)}')
          .join('##');

      if (sig == lastSignature) return;
      lastSignature = sig;

      debugPrint('🚀 NewsTicker Update [$src]: count=${items.length}');
      controller.add(items);
    }

    controller.onListen = () {
      sub = query.snapshots(includeMetadataChanges: false).listen(
        (snap) {
          final items = mapSnapshot(snap);
          emitIfChanged(items,
              src: snap.metadata.isFromCache ? 'cache' : 'live');
        },
        onError: (e) => debugPrint('❌ NewsTicker Stream Error: $e'),
      );
    };

    controller.onCancel = () {
      sub?.cancel();
      controller.close();
    };

    return controller.stream;
  }

  /// وظيفة النشر (تستخدم من لوحة التحكم أو النظام)
  Future<void> publishNews({
    required String textAr,
    int priority = 0,
    bool notify = false,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final trimmed = textAr.trim();
    if (trimmed.isEmpty) return;

    final data = <String, dynamic>{
      'text_ar': trimmed,
      'priority': priority,
      'isActive': true,
      'notify': notify,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'source': 'system',
    };

    if (startDate != null)
      data['startDate'] = Timestamp.fromDate(startDate.toUtc());
    if (endDate != null) data['endDate'] = Timestamp.fromDate(endDate.toUtc());

    await _firestore.collection(_col).add(data);
  }
}

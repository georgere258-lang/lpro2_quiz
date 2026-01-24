// PATH: lib/core/services/news_ticker_service.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:lpro2_quiz/core/constants/firestore_paths.dart';

class NewsTickerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _col = FirestorePaths.newsTickerItems;
  static const Duration _pollInterval = Duration(seconds: 5);

  /// Realtime + Polling(Server) => guarantees fresh updates even if listener lags.
  Stream<List<Map<String, dynamic>>> streamTickerItems() {
    final query = _firestore
        .collection(_col)
        .where('isActive', isEqualTo: true)
        .orderBy('priority', descending: true)
        // keep it, but polling will cover serverTimestamp delays anyway
        .orderBy('updatedAt', descending: true);

    final controller = StreamController<List<Map<String, dynamic>>>.broadcast();

    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? sub;
    Timer? pollTimer;

    String lastSignature = '';

    List<Map<String, dynamic>> mapSnapshot(
      QuerySnapshot<Map<String, dynamic>> snapshot,
    ) {
      final now = DateTime.now().toUtc();

      return snapshot.docs
          .where((doc) {
            final data = doc.data();

            final Timestamp? start = data['startDate'] as Timestamp?;
            final Timestamp? end = data['endDate'] as Timestamp?;

            // Convert timestamps to UTC for consistent comparison
            final startUtc = start?.toDate().toUtc();
            final endUtc = end?.toDate().toUtc();

            if (startUtc != null && now.isBefore(startUtc)) return false;
            if (endUtc != null && !now.isBefore(endUtc)) return false;

            final text = data['text_ar']?.toString().trim();
            if (text == null || text.isEmpty) return false;

            return true;
          })
          .map((doc) => doc.data())
          .toList();
    }

    void emitIfChanged(List<Map<String, dynamic>> items, {String src = ''}) {
      // signature based on text + updatedAt + id-ish fields if exist
      final sig = items
          .map((e) =>
              '${(e['text_ar'] ?? '').toString()}|${(e['updatedAt'] ?? '').toString()}|${(e['priority'] ?? 0).toString()}')
          .join('##');

      if (sig == lastSignature) return;
      lastSignature = sig;

      assert(() {
        debugPrint('NewsTicker emit ($src): count=${items.length}');
        return true;
      }());

      controller.add(items);
    }

    Future<void> pollServerOnce() async {
      try {
        final snap = await query.get(const GetOptions(source: Source.server));
        final items = mapSnapshot(snap);
        emitIfChanged(items, src: 'server_poll');
      } catch (e) {
        // ignore polling errors; realtime may still work
        assert(() {
          debugPrint('NewsTicker poll error: $e');
          return true;
        }());
      }
    }

    controller.onListen = () {
      // 1) realtime listener
      sub = query.snapshots(includeMetadataChanges: true).listen(
        (snap) {
          // emit cache/server listener results (fast path)
          final items = mapSnapshot(snap);
          emitIfChanged(items, src: snap.metadata.isFromCache ? 'cache' : 'rt');
        },
        onError: (e) {
          assert(() {
            debugPrint('NewsTicker stream error: $e');
            return true;
          }());
        },
      );

      // 2) server polling (hard guarantee)
      // fire immediately, then every interval
      pollServerOnce();
      pollTimer = Timer.periodic(_pollInterval, (_) => pollServerOnce());
    };

    controller.onCancel = () async {
      await sub?.cancel();
      pollTimer?.cancel();
      await controller.close();
    };

    return controller.stream;
  }

  Future<void> publishNews({
    required String textAr,
    int priority = 0,
    bool notify = false,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final trimmed = textAr.trim();
    if (trimmed.isEmpty) return;

    final DateTime? startUtc = startDate?.toUtc();
    final DateTime? endUtc = endDate?.toUtc();

    if (startUtc != null && endUtc != null && !startUtc.isBefore(endUtc)) {
      throw Exception('startDate must be before endDate');
    }

    final data = <String, dynamic>{
      'text_ar': trimmed,
      'priority': priority,
      'isActive': true,
      'notify': notify,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'source': 'system',
    };

    if (startUtc != null) {
      data['startDate'] = Timestamp.fromDate(startUtc);
    }
    if (endUtc != null) {
      data['endDate'] = Timestamp.fromDate(endUtc);
    }

    await _firestore.collection(_col).add(data);
  }
}

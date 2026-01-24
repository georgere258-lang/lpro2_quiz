// PATH: lib/core/services/app_config_service.dart
// App-wide feature flags and limits configuration service.

import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/firestore_paths.dart';

class AppConfigService {
  AppConfigService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const String _col = FirestorePaths.appConfig;
  static const String _docId = 'current';

  // ─────────────────────────────────────────────────────────────
  // Default values (used when doc is missing or fields are null)
  // ─────────────────────────────────────────────────────────────

  static const Map<String, dynamic> defaultFeatures = {
    'pushNotificationsEnabled': false,
    'sectionNotificationsEnabled': false,
    'supportChatEnabled': true,
    'quizShareEnabled': true,
  };

  static const Map<String, dynamic> defaultLimits = {
    'maxFetchPerPage': 50,
    'maxProInsightScan': 300,
    'maxSupportMessagesPerDay': 50,
  };

  static Map<String, dynamic> get defaults => {
        'features': Map<String, dynamic>.from(defaultFeatures),
        'limits': Map<String, dynamic>.from(defaultLimits),
      };

  // ─────────────────────────────────────────────────────────────
  // Public API
  // ─────────────────────────────────────────────────────────────

  /// Watch the current config document as a stream.
  /// Returns defaults merged with actual data.
  Stream<Map<String, dynamic>> watchCurrent() {
    return _db.collection(_col).doc(_docId).snapshots().map((snap) {
      return _mergeWithDefaults(snap.data());
    });
  }

  /// Get the current config once.
  /// Returns defaults merged with actual data.
  Future<Map<String, dynamic>> getCurrent() async {
    final snap = await _db.collection(_col).doc(_docId).get();
    return _mergeWithDefaults(snap.data());
  }

  /// Upsert (merge) updates into the current config document.
  /// Always sets updatedAt to serverTimestamp.
  Future<void> upsertCurrent(Map<String, dynamic> update) async {
    final payload = Map<String, dynamic>.from(update);
    payload['updatedAt'] = FieldValue.serverTimestamp();

    await _db
        .collection(_col)
        .doc(_docId)
        .set(payload, SetOptions(merge: true));
  }

  // ─────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────

  Map<String, dynamic> _mergeWithDefaults(Map<String, dynamic>? data) {
    final result = defaults;

    if (data == null) return result;

    // Merge features
    if (data['features'] is Map) {
      final f = data['features'] as Map<String, dynamic>;
      for (final key in defaultFeatures.keys) {
        if (f.containsKey(key)) {
          (result['features'] as Map<String, dynamic>)[key] = f[key];
        }
      }
    }

    // Merge limits
    if (data['limits'] is Map) {
      final l = data['limits'] as Map<String, dynamic>;
      for (final key in defaultLimits.keys) {
        if (l.containsKey(key)) {
          (result['limits'] as Map<String, dynamic>)[key] = l[key];
        }
      }
    }

    return result;
  }
}

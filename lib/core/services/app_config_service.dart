// PATH: lib/core/services/app_config_service.dart
// App-wide feature flags and limits configuration service.

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/firestore_paths.dart';

class AppConfigService {
  // ─────────────────────────────────────────────────────────────
  // Singleton pattern with cached config
  // ─────────────────────────────────────────────────────────────

  static final AppConfigService _instance = AppConfigService._internal();
  factory AppConfigService() => _instance;

  AppConfigService._internal() : _db = FirebaseFirestore.instance {
    _initStream();
  }

  /// For testing: create instance with custom Firestore
  AppConfigService.withFirestore(FirebaseFirestore firestore)
      : _db = firestore {
    _initStream();
  }

  final FirebaseFirestore _db;
  StreamSubscription<Map<String, dynamic>>? _subscription;

  /// Cached latest config map (updated from stream)
  Map<String, dynamic> _cachedConfig = defaults;

  void _initStream() {
    _subscription?.cancel();
    _subscription = watchCurrent().listen((data) {
      _cachedConfig = data;
    });
  }

  /// Dispose resources (call on app shutdown if needed)
  void dispose() {
    _subscription?.cancel();
  }

  static const String _col = FirestorePaths.appConfig;
  static const String _docId = 'current';

  // ─────────────────────────────────────────────────────────────
  // Default values (إضافة مفاتيح الأقسام الجديدة هنا)
  // ─────────────────────────────────────────────────────────────

  static const Map<String, dynamic> defaultFeatures = {
    'pushNotificationsEnabled': false,
    'sectionNotificationsEnabled': false,
    'supportChatEnabled': false,
    'quizShareEnabled': true,
    // مفاتيح التحكم في ظهور الأقسام (جديد)
    'showRadar': false, // رادار السوق
    'showEconomy': false, // اقتصاد عقاري
    'showInfoDiff': true, // المعلومة بتفرق
    'showCustomerInfo': true, // اعرف عميلك
  };

  static const Map<String, dynamic> defaultLimits = {
    'maxFetchPerPage': 50,
    'maxProInsightScan': 200,
    'maxSupportMessagesPerDay': 20,
  };

  static Map<String, dynamic> get defaults => {
        'features': Map<String, dynamic>.from(defaultFeatures),
        'limits': Map<String, dynamic>.from(defaultLimits),
      };

  // ─────────────────────────────────────────────────────────────
  // Strongly-typed getters
  // ─────────────────────────────────────────────────────────────

  Map<String, dynamic> get _features =>
      (_cachedConfig['features'] as Map<String, dynamic>?) ?? defaultFeatures;

  Map<String, dynamic> get _limits =>
      (_cachedConfig['limits'] as Map<String, dynamic>?) ?? defaultLimits;

  // Feature flags
  bool get pushNotificationsEnabled =>
      _features['pushNotificationsEnabled'] as bool? ?? false;

  bool get sectionNotificationsEnabled =>
      _features['sectionNotificationsEnabled'] as bool? ?? false;

  bool get supportChatEnabled =>
      _features['supportChatEnabled'] as bool? ?? false;

  bool get quizShareEnabled => _features['quizShareEnabled'] as bool? ?? true;

  // Getters الجديدة للتحكم في الأقسام (جديد)
  bool get showRadar => _features['showRadar'] as bool? ?? false;
  bool get showEconomy => _features['showEconomy'] as bool? ?? false;
  bool get showInfoDiff => _features['showInfoDiff'] as bool? ?? true;
  bool get showCustomerInfo => _features['showCustomerInfo'] as bool? ?? true;

  // Limits
  int get maxFetchPerPage => _limits['maxFetchPerPage'] as int? ?? 50;

  int get maxProInsightScan => _limits['maxProInsightScan'] as int? ?? 200;

  int get maxSupportMessagesPerDay =>
      _limits['maxSupportMessagesPerDay'] as int? ?? 20;

  // ─────────────────────────────────────────────────────────────
  // Public API (تظل كما هي تماماً)
  // ─────────────────────────────────────────────────────────────

  Stream<Map<String, dynamic>> watchCurrent() {
    return _db.collection(_col).doc(_docId).snapshots().map((snap) {
      return _mergeWithDefaults(snap.data());
    });
  }

  Future<Map<String, dynamic>> getCurrent() async {
    final snap = await _db.collection(_col).doc(_docId).get();
    return _mergeWithDefaults(snap.data());
  }

  Future<void> upsertCurrent(Map<String, dynamic> update) async {
    final payload = Map<String, dynamic>.from(update);
    payload['updatedAt'] = FieldValue.serverTimestamp();

    await _db
        .collection(_col)
        .doc(_docId)
        .set(payload, SetOptions(merge: true));
  }

  Map<String, dynamic> _mergeWithDefaults(Map<String, dynamic>? data) {
    final result = defaults;
    if (data == null) return result;

    if (data['features'] is Map) {
      final f = data['features'] as Map<String, dynamic>;
      for (final key in defaultFeatures.keys) {
        if (f.containsKey(key)) {
          (result['features'] as Map<String, dynamic>)[key] = f[key];
        }
      }
    }

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

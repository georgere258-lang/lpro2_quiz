// PATH: lib/core/models/admin_control_models.dart
// Shared admin control models for content management across collections.

import 'package:cloud_firestore/cloud_firestore.dart';

// ═══════════════════════════════════════════════════════════════════════════
// IAdminControlled - Interface for admin-controlled content
// ═══════════════════════════════════════════════════════════════════════════

/// Marker interface for entities that support admin control fields.
abstract class IAdminControlled {
  AdminControlFields get adminFields;
}

// ═══════════════════════════════════════════════════════════════════════════
// UtcNormalizer - Utility for UTC date handling
// ═══════════════════════════════════════════════════════════════════════════

/// Utility class for normalizing DateTime values to UTC.
class UtcNormalizer {
  UtcNormalizer._();

  /// Normalizes a DateTime to UTC. Returns null if input is null.
  static DateTime? normalize(DateTime? dt) => dt?.toUtc();

  /// Converts Firestore Timestamp to UTC DateTime.
  static DateTime? fromTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate().toUtc();
    if (value is DateTime) return value.toUtc();
    return null;
  }

  /// Converts DateTime to Firestore Timestamp (UTC).
  static Timestamp? toTimestamp(DateTime? dt) {
    if (dt == null) return null;
    return Timestamp.fromDate(dt.toUtc());
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// AdminControlFields - Shared admin control metadata
// ═══════════════════════════════════════════════════════════════════════════

/// Shared admin control fields for content management.
///
/// Used across collections like pro_insight, know_your_client, quizzes, etc.
/// All DateTime fields are stored and compared in UTC.
class AdminControlFields {
  /// Whether the content is visible to non-admin users.
  final bool isActive;

  /// Scheduled publish time (UTC). Content hidden until this time.
  final DateTime? publishAt;

  /// Scheduled expiration time (UTC). Content hidden after this time.
  final DateTime? expireAt;

  /// Whether the content is featured/highlighted.
  final bool featured;

  /// Featured status expiration time (UTC).
  final DateTime? featuredUntil;

  /// Order within featured items (lower = higher priority).
  final int? featuredOrder;

  /// Section key for grouping (e.g., 'pro_insight', 'kyc', 'radar').
  final String sectionKey;

  /// Order within the section (lower = higher priority).
  final int orderInSection;

  /// Whether to send push notification when published.
  final bool notify;

  /// Content tags (max 5).
  final List<String> tags;

  /// Creation timestamp (nullable for serverTimestamp compatibility).
  final DateTime? createdAt;

  /// Last update timestamp (nullable for serverTimestamp compatibility).
  final DateTime? updatedAt;

  // ─────────────────────────────────────────────────────────────────────────
  // Constructor
  // ─────────────────────────────────────────────────────────────────────────

  AdminControlFields._({
    required this.isActive,
    this.publishAt,
    this.expireAt,
    required this.featured,
    this.featuredUntil,
    this.featuredOrder,
    required this.sectionKey,
    required this.orderInSection,
    required this.notify,
    required this.tags,
    this.createdAt,
    this.updatedAt,
  });

  /// Creates AdminControlFields with validation and UTC normalization.
  ///
  /// Throws [ArgumentError] if:
  /// - [tags] has more than 5 items
  /// - [publishAt] is after [expireAt] (when both are set)
  factory AdminControlFields({
    bool isActive = false,
    DateTime? publishAt,
    DateTime? expireAt,
    bool featured = false,
    DateTime? featuredUntil,
    int? featuredOrder,
    required String sectionKey,
    int orderInSection = 0,
    bool notify = false,
    List<String> tags = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    // Normalize all DateTime to UTC
    final publishAtUtc = UtcNormalizer.normalize(publishAt);
    final expireAtUtc = UtcNormalizer.normalize(expireAt);
    final featuredUntilUtc = UtcNormalizer.normalize(featuredUntil);
    final createdAtUtc = UtcNormalizer.normalize(createdAt);
    final updatedAtUtc = UtcNormalizer.normalize(updatedAt);

    // Validation: tags max 5
    if (tags.length > 5) {
      throw ArgumentError('tags cannot exceed 5 items (got ${tags.length})');
    }

    // Validation: publishAt must be <= expireAt
    if (publishAtUtc != null &&
        expireAtUtc != null &&
        publishAtUtc.isAfter(expireAtUtc)) {
      throw ArgumentError('publishAt must be before or equal to expireAt');
    }

    return AdminControlFields._(
      isActive: isActive,
      publishAt: publishAtUtc,
      expireAt: expireAtUtc,
      featured: featured,
      featuredUntil: featuredUntilUtc,
      featuredOrder: featuredOrder,
      sectionKey: sectionKey,
      orderInSection: orderInSection,
      notify: notify,
      tags: List<String>.unmodifiable(tags),
      createdAt: createdAtUtc,
      updatedAt: updatedAtUtc,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Firestore Serialization
  // ─────────────────────────────────────────────────────────────────────────

  /// Converts to Firestore-compatible map.
  ///
  /// - [includeCreatedAt]: if true, sets createdAt to serverTimestamp
  /// - updatedAt is always set to serverTimestamp
  /// - null DateTime fields are omitted (caller can use FieldValue.delete externally)
  Map<String, dynamic> toFirestore({bool includeCreatedAt = false}) {
    final map = <String, dynamic>{
      'isActive': isActive,
      'featured': featured,
      'sectionKey': sectionKey,
      'orderInSection': orderInSection,
      'notify': notify,
      'tags': tags,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // Include createdAt only when requested (typically on create)
    if (includeCreatedAt) {
      map['createdAt'] = FieldValue.serverTimestamp();
    }

    // DateTime fields - only include if not null
    if (publishAt != null) {
      map['publishAt'] = UtcNormalizer.toTimestamp(publishAt);
    }
    if (expireAt != null) {
      map['expireAt'] = UtcNormalizer.toTimestamp(expireAt);
    }
    if (featuredUntil != null) {
      map['featuredUntil'] = UtcNormalizer.toTimestamp(featuredUntil);
    }
    if (featuredOrder != null) {
      map['featuredOrder'] = featuredOrder;
    }

    return map;
  }

  /// Creates AdminControlFields from Firestore document data.
  ///
  /// - [sectionKeyFallback]: used if sectionKey is not present in data
  factory AdminControlFields.fromFirestore(
    Map<String, dynamic> data, {
    required String sectionKeyFallback,
  }) {
    return AdminControlFields(
      isActive: data['isActive'] == true,
      publishAt: UtcNormalizer.fromTimestamp(data['publishAt']),
      expireAt: UtcNormalizer.fromTimestamp(data['expireAt']),
      featured: data['featured'] == true,
      featuredUntil: UtcNormalizer.fromTimestamp(data['featuredUntil']),
      featuredOrder: data['featuredOrder'] is int ? data['featuredOrder'] : null,
      sectionKey: (data['sectionKey'] as String?) ?? sectionKeyFallback,
      orderInSection: data['orderInSection'] is int ? data['orderInSection'] : 0,
      notify: data['notify'] == true,
      tags: _parseTags(data['tags']),
      createdAt: UtcNormalizer.fromTimestamp(data['createdAt']),
      updatedAt: UtcNormalizer.fromTimestamp(data['updatedAt']),
    );
  }

  /// Parses tags from Firestore data (handles null, List, or invalid types).
  static List<String> _parseTags(dynamic value) {
    if (value == null) return const [];
    if (value is List) {
      return value
          .whereType<String>()
          .take(5) // Enforce max 5 even from Firestore
          .toList();
    }
    return const [];
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Convenience Methods
  // ─────────────────────────────────────────────────────────────────────────

  /// Returns true if the content should be visible based on schedule.
  ///
  /// Checks:
  /// - isActive must be true
  /// - now must be >= publishAt (if set)
  /// - now must be < expireAt (if set)
  bool isVisibleAt(DateTime now) {
    if (!isActive) return false;

    final nowUtc = now.toUtc();

    if (publishAt != null && nowUtc.isBefore(publishAt!)) {
      return false;
    }
    if (expireAt != null && !nowUtc.isBefore(expireAt!)) {
      return false;
    }

    return true;
  }

  /// Returns true if the content is currently visible (uses DateTime.now()).
  bool get isCurrentlyVisible => isVisibleAt(DateTime.now());

  /// Returns true if the content is currently featured.
  ///
  /// Checks:
  /// - featured must be true
  /// - if featuredUntil is set, now must be < featuredUntil
  bool isFeaturedAt(DateTime now) {
    if (!featured) return false;
    if (featuredUntil == null) return true;
    return now.toUtc().isBefore(featuredUntil!);
  }

  /// Returns true if the content is currently featured (uses DateTime.now()).
  bool get isCurrentlyFeatured => isFeaturedAt(DateTime.now());

  /// Creates a copy with updated fields.
  AdminControlFields copyWith({
    bool? isActive,
    DateTime? publishAt,
    bool clearPublishAt = false,
    DateTime? expireAt,
    bool clearExpireAt = false,
    bool? featured,
    DateTime? featuredUntil,
    bool clearFeaturedUntil = false,
    int? featuredOrder,
    bool clearFeaturedOrder = false,
    String? sectionKey,
    int? orderInSection,
    bool? notify,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AdminControlFields(
      isActive: isActive ?? this.isActive,
      publishAt: clearPublishAt ? null : (publishAt ?? this.publishAt),
      expireAt: clearExpireAt ? null : (expireAt ?? this.expireAt),
      featured: featured ?? this.featured,
      featuredUntil:
          clearFeaturedUntil ? null : (featuredUntil ?? this.featuredUntil),
      featuredOrder:
          clearFeaturedOrder ? null : (featuredOrder ?? this.featuredOrder),
      sectionKey: sectionKey ?? this.sectionKey,
      orderInSection: orderInSection ?? this.orderInSection,
      notify: notify ?? this.notify,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'AdminControlFields('
        'isActive: $isActive, '
        'sectionKey: $sectionKey, '
        'featured: $featured, '
        'tags: $tags)';
  }
}

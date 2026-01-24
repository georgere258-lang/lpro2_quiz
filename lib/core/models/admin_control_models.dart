// PATH: lib/core/models/admin_control_models.dart
// Shared admin control models for content management across collections.

import 'package:cloud_firestore/cloud_firestore.dart';

// ═══════════════════════════════════════════════════════════════════════════
// UtcNormalizer - Utility for UTC date handling
// ═══════════════════════════════════════════════════════════════════════════

/// Utility class for normalizing DateTime values to UTC.
class UtcNormalizer {
  UtcNormalizer._();

  /// Returns current time in UTC.
  static DateTime nowUtc() => DateTime.now().toUtc();

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
// IAdminControlled - Interface for admin-controlled content
// ═══════════════════════════════════════════════════════════════════════════

/// Interface for entities that support admin control fields.
abstract class IAdminControlled {
  /// Unique identifier for the entity.
  String get id;

  /// Whether the content is active/visible.
  bool get isActive;

  /// Scheduled publish time (UTC).
  DateTime? get publishAt;

  /// Scheduled expiration time (UTC).
  DateTime? get expireAt;

  /// Last update timestamp (UTC).
  DateTime? get updatedAt;

  /// Section key for grouping.
  String get sectionKey;

  /// Converts the entity to a Firestore-compatible map.
  Map<String, dynamic> toFirestore();

  /// Validates the entity. Throws [ArgumentError] if invalid.
  void validate();
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

  /// Creates AdminControlFields with UTC normalization.
  /// Call [validate] to check constraints.
  AdminControlFields({
    this.isActive = false,
    DateTime? publishAt,
    DateTime? expireAt,
    this.featured = false,
    DateTime? featuredUntil,
    this.featuredOrder,
    required this.sectionKey,
    this.orderInSection = 0,
    this.notify = false,
    List<String> tags = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : publishAt = UtcNormalizer.normalize(publishAt),
        expireAt = UtcNormalizer.normalize(expireAt),
        featuredUntil = UtcNormalizer.normalize(featuredUntil),
        createdAt = UtcNormalizer.normalize(createdAt),
        updatedAt = UtcNormalizer.normalize(updatedAt),
        tags = List<String>.unmodifiable(tags);

  // ─────────────────────────────────────────────────────────────────────────
  // Validation
  // ─────────────────────────────────────────────────────────────────────────

  /// Validates the fields. Throws [ArgumentError] if invalid.
  ///
  /// Checks:
  /// - [tags] must have at most 5 items
  /// - [publishAt] must be <= [expireAt] (when both are set)
  /// - [featuredUntil] must be in the future if featured is true
  void validate() {
    // Validation: tags max 5
    if (tags.length > 5) {
      throw ArgumentError('tags cannot exceed 5 items (got ${tags.length})');
    }

    // Validation: publishAt must be <= expireAt
    if (publishAt != null && expireAt != null && publishAt!.isAfter(expireAt!)) {
      throw ArgumentError('publishAt must be before or equal to expireAt');
    }

    // Validation: featuredUntil must be in the future if featured
    if (featured && featuredUntil != null) {
      final now = UtcNormalizer.nowUtc();
      if (featuredUntil!.isBefore(now)) {
        throw ArgumentError('featuredUntil must be in the future (UTC)');
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Firestore Serialization
  // ─────────────────────────────────────────────────────────────────────────

  /// Converts to Firestore-compatible map.
  ///
  /// - DateTime fields are converted to Timestamp (UTC)
  /// - null DateTime fields are omitted (caller can use FieldValue.serverTimestamp)
  /// - createdAt/updatedAt: if provided as DateTime, converts to Timestamp;
  ///   if null, omitted (caller may use FieldValue.serverTimestamp)
  Map<String, dynamic> toFirestore() {
    final map = <String, dynamic>{
      'isActive': isActive,
      'featured': featured,
      'sectionKey': sectionKey,
      'orderInSection': orderInSection,
      'notify': notify,
      'tags': tags,
    };

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
    if (createdAt != null) {
      map['createdAt'] = UtcNormalizer.toTimestamp(createdAt);
    }
    if (updatedAt != null) {
      map['updatedAt'] = UtcNormalizer.toTimestamp(updatedAt);
    }

    return map;
  }

  /// Creates AdminControlFields from Firestore document data.
  ///
  /// - [sectionKey]: fallback used if sectionKey is not present in data
  /// - orderInSection defaults to current UTC timestamp milliseconds if not present
  factory AdminControlFields.fromFirestore(
    Map<String, dynamic> data,
    String sectionKey,
  ) {
    return AdminControlFields(
      isActive: data['isActive'] == true,
      publishAt: UtcNormalizer.fromTimestamp(data['publishAt']),
      expireAt: UtcNormalizer.fromTimestamp(data['expireAt']),
      featured: data['featured'] == true,
      featuredUntil: UtcNormalizer.fromTimestamp(data['featuredUntil']),
      featuredOrder: data['featuredOrder'] is int ? data['featuredOrder'] : null,
      sectionKey: (data['sectionKey'] as String?) ?? sectionKey,
      orderInSection: data['orderInSection'] is int
          ? data['orderInSection']
          : UtcNormalizer.nowUtc().millisecondsSinceEpoch,
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
      return value.whereType<String>().take(5).toList();
    }
    return const [];
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Convenience Methods
  // ─────────────────────────────────────────────────────────────────────────

  /// Returns true if the content should be visible based on schedule.
  bool isVisibleAt(DateTime now) {
    if (!isActive) return false;
    final nowUtc = now.toUtc();
    if (publishAt != null && nowUtc.isBefore(publishAt!)) return false;
    if (expireAt != null && !nowUtc.isBefore(expireAt!)) return false;
    return true;
  }

  /// Returns true if the content is currently visible.
  bool get isCurrentlyVisible => isVisibleAt(DateTime.now());

  /// Returns true if the content is featured at the given time.
  bool isFeaturedAt(DateTime now) {
    if (!featured) return false;
    if (featuredUntil == null) return true;
    return now.toUtc().isBefore(featuredUntil!);
  }

  /// Returns true if the content is currently featured.
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

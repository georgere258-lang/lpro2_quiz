// PATH: lib/features/users/models/user_profile.dart

import '../../../core/models/admin_control_models.dart';

/// Valid user roles.
class UserRole {
  static const String user = 'user';
  static const String moderator = 'moderator';
  static const String admin = 'admin';

  static const List<String> values = [user, moderator, admin];

  static bool isValid(String value) => values.contains(value);
}

/// User profile model for admin management.
class UserProfile {
  final String uid;
  final String email;
  final String? name;
  final String? phone;
  final String? phoneE164;
  final String? avatarId;
  final String role;
  final bool isBlocked;
  final String? blockReason;
  final DateTime? blockedAt;
  final String? blockedBy;
  final DateTime? createdAt;
  final DateTime? lastSeenAt;
  final Map<String, dynamic>? stats;

  UserProfile({
    required this.uid,
    required this.email,
    this.name,
    this.phone,
    this.phoneE164,
    this.avatarId,
    this.role = UserRole.user,
    this.isBlocked = false,
    this.blockReason,
    this.blockedAt,
    this.blockedBy,
    this.createdAt,
    this.lastSeenAt,
    this.stats,
  });

  void validateRole() {
    if (!UserRole.isValid(role)) {
      throw ArgumentError('role must be one of: ${UserRole.values}');
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (phoneE164 != null) 'phoneE164': phoneE164,
      if (avatarId != null) 'avatarId': avatarId,
      'role': role,
      'isBlocked': isBlocked,
      if (blockReason != null) 'blockReason': blockReason,
      if (blockedBy != null) 'blockedBy': blockedBy,
      if (stats != null) 'stats': stats,
    };
  }

  factory UserProfile.fromFirestore(Map<String, dynamic> data, String uid) {
    return UserProfile(
      uid: uid,
      email: (data['email'] as String?) ?? '',
      name: data['name'] as String?,
      phone: data['phone'] as String?,
      phoneE164: data['phoneE164'] as String?,
      avatarId: data['avatarId'] as String?,
      role: (data['role'] as String?) ?? UserRole.user,
      isBlocked: data['isBlocked'] == true,
      blockReason: data['blockReason'] as String?,
      blockedAt: UtcNormalizer.fromTimestamp(data['blockedAt']),
      blockedBy: data['blockedBy'] as String?,
      createdAt: UtcNormalizer.fromTimestamp(data['createdAt']),
      lastSeenAt: UtcNormalizer.fromTimestamp(data['lastSeenAt']),
      stats: data['stats'] is Map<String, dynamic> ? data['stats'] : null,
    );
  }
}

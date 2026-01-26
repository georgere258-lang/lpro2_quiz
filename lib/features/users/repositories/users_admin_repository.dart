// PATH: lib/features/users/repositories/users_admin_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/firestore_paths.dart';
import '../models/user_profile.dart';

/// Repository for admin user management operations.
class UsersAdminRepository {
  final FirebaseFirestore _firestore;
  late final CollectionReference<Map<String, dynamic>> _collection;

  UsersAdminRepository([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance {
    _collection = _firestore.collection(FirestorePaths.users);
  }

  /// Watches all users ordered by createdAt descending.
  Stream<List<UserProfile>> watchAllUsers({int limit = 100}) {
    final safeLimit = limit.clamp(1, 100);
    return _collection
        .orderBy('createdAt', descending: true)
        .limit(safeLimit)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => UserProfile.fromFirestore(d.data(), d.id))
            .toList());
  }

  /// Searches users by email or name prefix (best-effort).
  /// Firestore limitation: prefix search only, case-sensitive.
  Stream<List<UserProfile>> searchUsers(String query) {
    if (query.trim().isEmpty) {
      return watchAllUsers(limit: 50);
    }

    final searchTerm = query.trim();
    final endTerm = '$searchTerm\uf8ff';

    // Try email prefix search first
    return _collection
        .where('email', isGreaterThanOrEqualTo: searchTerm)
        .where('email', isLessThanOrEqualTo: endTerm)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => UserProfile.fromFirestore(d.data(), d.id))
            .toList());
  }

  /// Searches users by phone number (phoneE164 or phone field).
  Future<List<UserProfile>> searchByPhone(String phone) async {
    if (phone.trim().isEmpty) return [];

    final searchTerm = phone.trim();

    // Try exact match on phoneE164 first
    var snap = await _collection
        .where('phoneE164', isEqualTo: searchTerm)
        .limit(20)
        .get();

    // Fallback: exact match on phone field
    if (snap.docs.isEmpty) {
      snap = await _collection
          .where('phone', isEqualTo: searchTerm)
          .limit(20)
          .get();
    }

    return snap.docs
        .map((d) => UserProfile.fromFirestore(d.data(), d.id))
        .toList();
  }

  /// Blocks a user with reason and admin tracking.
  Future<void> blockUser(String uid, String reason, String adminUid) async {
    if (uid.trim().isEmpty) {
      throw ArgumentError('uid cannot be empty');
    }
    if (reason.trim().isEmpty) {
      throw ArgumentError('reason cannot be empty');
    }
    if (adminUid.trim().isEmpty) {
      throw ArgumentError('adminUid cannot be empty');
    }

    await _collection.doc(uid).update({
      'isBlocked': true,
      'blockReason': reason.trim(),
      'blockedAt': FieldValue.serverTimestamp(),
      'blockedBy': adminUid.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Unblocks a user and clears block-related fields.
  Future<void> unblockUser(String uid) async {
    if (uid.trim().isEmpty) {
      throw ArgumentError('uid cannot be empty');
    }

    await _collection.doc(uid).update({
      'isBlocked': false,
      'blockReason': FieldValue.delete(),
      'blockedAt': FieldValue.delete(),
      'blockedBy': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Updates a user's role.
  Future<void> updateRole(String uid, String newRole) async {
    if (uid.trim().isEmpty) {
      throw ArgumentError('uid cannot be empty');
    }
    if (!UserRole.isValid(newRole)) {
      throw ArgumentError('Invalid role: $newRole');
    }

    await _collection.doc(uid).update({
      'role': newRole,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

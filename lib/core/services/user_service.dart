// PATH: lib/core/services/user_service.dart
// STATUS: RESTORED TO SIMPLE SINGLE-SOURCE (Matches Original UserModel)

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../data/models/user_model.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ✅ المحرك المباشر: يستمع فقط لوثيقة المستخدم الأساسية
  Stream<UserModel?> get currentUserStream {
    return _auth.authStateChanges().asyncExpand((firebaseUser) {
      if (firebaseUser == null) return Stream.value(null);

      return _db
          .collection('users')
          .doc(firebaseUser.uid)
          .snapshots()
          .map((doc) {
        if (!doc.exists || doc.data() == null) {
          debugPrint(
              "⚠️ [UserService] Document not found for UID: ${firebaseUser.uid}");
          return null;
        }
        // استخدام الـ factory الموثوق في الموديل الأصلي
        return UserModel.fromMap(doc.data()!, doc.id);
      });
    });
  }

  // ✅ تحديث البيانات في وثيقة users فقط
  Future<void> updateUserData(Map<String, dynamic> data) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      await _db.collection('users').doc(uid).set(data, SetOptions(merge: true));
      debugPrint("✅ [UserService] Update Success");
    } catch (e) {
      debugPrint("❌ [UserService] Update Failure: $e");
    }
  }
}

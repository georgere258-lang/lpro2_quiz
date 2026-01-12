import 'package:cloud_firestore/cloud_firestore.dart';

class ProInsightModel {
  final String id;
  final String hook;
  final String mindReset;
  final String coreInsight;
  final String? realityExample;
  final String mentalLock;
  final bool isActive;
  final DateTime createdAt;

  ProInsightModel({
    required this.id,
    required this.hook,
    required this.mindReset,
    required this.coreInsight,
    this.realityExample,
    required this.mentalLock,
    required this.isActive,
    required this.createdAt,
  });

  factory ProInsightModel.fromMap(Map<String, dynamic> data, String id) {
    return ProInsightModel(
      id: id,
      hook: data['hook'] ?? '',
      mindReset: data['mindReset'] ?? '',
      coreInsight: data['coreInsight'] ?? '',
      realityExample: data['realityExample'],
      mentalLock: data['mentalLock'] ?? '',
      isActive: data['isActive'] ?? true, // ✅ الافتراضي مفعل
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hook': hook,
      'mindReset': mindReset,
      'coreInsight': coreInsight,
      'realityExample': realityExample,
      'mentalLock': mentalLock,
      'isActive': isActive,
      'createdAt': FieldValue.serverTimestamp(), // ✅ الأصح
    };
  }
}

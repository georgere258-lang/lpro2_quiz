import 'package:cloud_firestore/cloud_firestore.dart';

class AdminNewsItem {
  final String id;
  final String textAr;
  final String textEn;
  final bool isActive;
  final bool withNotification;
  final int priority;
  final DateTime createdAt;
  final DateTime? startDate;
  final DateTime? endDate;

  AdminNewsItem({
    required this.id,
    required this.textAr,
    required this.textEn,
    required this.isActive,
    required this.withNotification,
    required this.priority,
    required this.createdAt,
    this.startDate,
    this.endDate,
  });

  factory AdminNewsItem.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return AdminNewsItem(
      id: doc.id,
      textAr: data['text_ar'] ?? '',
      textEn: data['text_en'] ?? '',
      isActive: data['isActive'] ?? false,
      withNotification: data['withNotification'] ?? false,
      priority: data['priority'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      startDate: (data['startDate'] as Timestamp?)?.toDate(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text_ar': textAr,
      'text_en': textEn,
      'isActive': isActive,
      'withNotification': withNotification,
      'priority': priority,
      'createdAt': FieldValue.serverTimestamp(),
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
    };
  }
}

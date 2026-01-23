import 'package:cloud_firestore/cloud_firestore.dart';

class HomeProCardModel {
  final String id;
  final String content;
  final bool isActive;
  final DateTime startDate;

  HomeProCardModel({
    required this.id,
    required this.content,
    required this.isActive,
    required this.startDate,
  });

  factory HomeProCardModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return HomeProCardModel(
      id: doc.id,
      content: (data['content'] ?? '').toString(),
      isActive: data['isActive'] ?? false,
      startDate: (data['startDate'] as Timestamp).toDate(),
    );
  }
}

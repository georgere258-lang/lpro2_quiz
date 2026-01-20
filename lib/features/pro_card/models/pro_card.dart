// PATH: lib/features/pro_card/models/pro_card.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class ProCard {
  final String id;
  final String text;
  final bool isActive;
  final bool pinned;
  final bool notify;
  final DateTime? publishAt;
  final DateTime? expireAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProCard({
    required this.id,
    required this.text,
    required this.isActive,
    required this.pinned,
    required this.notify,
    this.publishAt,
    this.expireAt,
    this.createdAt,
    this.updatedAt,
  });

  factory ProCard.fromFirestore(Map<String, dynamic> data, String id) {
    return ProCard(
      id: id,
      text: (data['text'] ?? '').toString(),
      isActive: data['isActive'] == true,
      pinned: data['pinned'] == true,
      notify: data['notify'] == true,
      publishAt: data['publishAt'] is Timestamp
          ? (data['publishAt'] as Timestamp).toDate()
          : null,
      expireAt: data['expireAt'] is Timestamp
          ? (data['expireAt'] as Timestamp).toDate()
          : null,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    final m = <String, dynamic>{
      'text': text,
      'isActive': isActive,
      'pinned': pinned,
      'notify': notify,
    };
    if (publishAt != null) m['publishAt'] = Timestamp.fromDate(publishAt!);
    if (expireAt != null) m['expireAt'] = Timestamp.fromDate(expireAt!);
    return m;
  }

  /// Map used to pass as [existing] into the Pro Card editor (includes Timestamps).
  /// Omits 'publishAt' and 'expireAt' when null (does not set them to null in the map).
  Map<String, dynamic> toExistingMap() {
    final m = <String, dynamic>{
      'text': text,
      'isActive': isActive,
      'pinned': pinned,
      'notify': notify,
    };
    if (publishAt != null) m['publishAt'] = Timestamp.fromDate(publishAt!);
    if (expireAt != null) m['expireAt'] = Timestamp.fromDate(expireAt!);
    return m;
  }

  ProCard copyWith({
    String? id,
    String? text,
    bool? isActive,
    bool? pinned,
    bool? notify,
    DateTime? publishAt,
    DateTime? expireAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProCard(
      id: id ?? this.id,
      text: text ?? this.text,
      isActive: isActive ?? this.isActive,
      pinned: pinned ?? this.pinned,
      notify: notify ?? this.notify,
      publishAt: publishAt ?? this.publishAt,
      expireAt: expireAt ?? this.expireAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

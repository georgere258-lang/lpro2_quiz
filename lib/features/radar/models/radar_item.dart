// PATH: lib/features/radar/models/radar_item.dart

import '../../../core/models/admin_control_models.dart';

class RadarItem {
  final String id;
  final String title;
  final String body;
  final bool isFeatured;
  final bool isImportant;
  final AdminControlFields control;

  const RadarItem({
    required this.id,
    required this.title,
    required this.body,
    required this.isFeatured,
    required this.isImportant,
    required this.control,
  });

  void validate() {
    if (title.trim().length < 3) {
      throw 'العنوان لازم يكون 3 حروف على الأقل';
    }
    if (body.trim().length < 20) {
      throw 'المحتوى لازم يكون 20 حرف على الأقل';
    }
  }

  RadarItem copyWith({
    String? id,
    String? title,
    String? body,
    bool? isFeatured,
    bool? isImportant,
    AdminControlFields? control,
  }) {
    return RadarItem(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      isFeatured: isFeatured ?? this.isFeatured,
      isImportant: isImportant ?? this.isImportant,
      control: control ?? this.control,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title.trim(),
      'body': body.trim(),
      'isFeatured': isFeatured,
      'isImportant': isImportant,
      'control': control.toFirestore(),
    };
  }

  factory RadarItem.fromFirestore(String id, Map<String, dynamic> data) {
    final rawControl = data['control'];
    final controlMap = rawControl is Map
        ? Map<String, dynamic>.from(rawControl)
        : <String, dynamic>{};

    return RadarItem(
      id: id,
      title: (data['title'] ?? '').toString(),
      body: (data['body'] ?? '').toString(),
      isFeatured: data['isFeatured'] == true,
      isImportant: data['isImportant'] == true,
      control: AdminControlFields.fromFirestore(controlMap, 'radar'),
    );
  }
}

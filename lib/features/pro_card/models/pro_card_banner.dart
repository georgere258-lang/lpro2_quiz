// PATH: lib/features/pro_card/models/pro_card_banner.dart

import '../../../core/constants/firestore_paths.dart';
import '../../../core/models/admin_control_models.dart';

enum ProCardContentType { text, image }

ProCardContentType _parseContentType(dynamic v) {
  final s = (v ?? '').toString().toLowerCase().trim();
  if (s == 'image') return ProCardContentType.image;
  return ProCardContentType.text;
}

/// Pro Card banner model implementing admin control interface.
class ProCardBanner implements IAdminControlled {
  @override
  final String id;

  /// محتوى النص (اختياري لو النوع صورة)
  final String text;

  /// رابط الصورة (اختياري لو النوع نص)
  final String imageUrl;

  final ProCardContentType contentType;

  final AdminControlFields control;

  ProCardBanner({
    required this.id,
    required this.text,
    required this.imageUrl,
    required this.contentType,
    required this.control,
  });

  @override
  bool get isActive => control.isActive;

  @override
  DateTime? get publishAt => control.publishAt;

  @override
  DateTime? get expireAt => control.expireAt;

  @override
  DateTime? get updatedAt => control.updatedAt;

  @override
  String get sectionKey => control.sectionKey;

  @override
  void validate() {
    // قواعد بسيطة: لو Text لازم نص غير فاضي، لو Image لازم URL غير فاضي
    if (contentType == ProCardContentType.text) {
      if (text.trim().isEmpty) {
        throw ArgumentError('text cannot be empty');
      }
      if (text.trim().length > 500) {
        throw ArgumentError('text cannot exceed 500 characters');
      }
    } else {
      if (imageUrl.trim().isEmpty) {
        throw ArgumentError('imageUrl cannot be empty');
      }
      // لا نعمل Regex معقدة هنا (خليها بسيطة لتجنب false negatives)
      if (!imageUrl.trim().startsWith('http')) {
        throw ArgumentError('imageUrl must start with http/https');
      }
    }

    control.validate();
  }

  @override
  Map<String, dynamic> toFirestore() {
    final map = control.toFirestore();

    // content fields
    map['contentType'] =
        contentType == ProCardContentType.image ? 'image' : 'text';
    map['text'] = text.trim();
    map['imageUrl'] = imageUrl.trim();

    // Remove createdAt/updatedAt - repository handles timestamps
    map.remove('createdAt');
    map.remove('updatedAt');
    return map;
  }

  factory ProCardBanner.fromFirestore(Map<String, dynamic> data, String id) {
    final type = _parseContentType(data['contentType']);
    return ProCardBanner(
      id: id,
      text: (data['text'] as String?) ?? '',
      imageUrl: (data['imageUrl'] as String?) ?? '',
      contentType: type,
      control: AdminControlFields.fromFirestore(
        data,
        FirestorePaths.sectionKeyProCard,
      ),
    );
  }

  bool get isText => contentType == ProCardContentType.text;
  bool get isImage => contentType == ProCardContentType.image;
}

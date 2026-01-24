// PATH: lib/features/kyc/models/kyc_item.dart

import '../../../core/constants/firestore_paths.dart';
import '../../../core/models/admin_control_models.dart';

/// Know Your Client item model implementing admin control interface.
class KycItem implements IAdminControlled {
  @override
  final String id;

  final String title;
  final String content;
  final String? imageUrl;
  final AdminControlFields control;

  KycItem({
    required this.id,
    required this.title,
    required this.content,
    this.imageUrl,
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

  int get orderInSection => control.orderInSection;

  @override
  void validate() {
    if (title.trim().length < 3) {
      throw ArgumentError('title must be at least 3 characters');
    }
    if (content.trim().length < 20) {
      throw ArgumentError('content must be at least 20 characters');
    }
    control.validate();
  }

  @override
  Map<String, dynamic> toFirestore() {
    final map = control.toFirestore();
    map['title'] = title.trim();
    map['content'] = content.trim();
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      map['imageUrl'] = imageUrl;
    }
    // Remove timestamps - repository handles serverTimestamp
    map.remove('createdAt');
    map.remove('updatedAt');
    return map;
  }

  factory KycItem.fromFirestore(Map<String, dynamic> data, String id) {
    return KycItem(
      id: id,
      title: (data['title'] as String?) ?? '',
      content: (data['content'] as String?) ?? '',
      imageUrl: data['imageUrl'] as String?,
      control: AdminControlFields.fromFirestore(
        data,
        FirestorePaths.sectionKeyKyc,
      ),
    );
  }
}

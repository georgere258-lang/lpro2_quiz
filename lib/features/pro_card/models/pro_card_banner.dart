// PATH: lib/features/pro_card/models/pro_card_banner.dart

import '../../../core/constants/firestore_paths.dart';
import '../../../core/models/admin_control_models.dart';

/// Pro Card banner model implementing admin control interface.
class ProCardBanner implements IAdminControlled {
  @override
  final String id;

  final String text;

  final AdminControlFields control;

  ProCardBanner({
    required this.id,
    required this.text,
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
    if (text.isEmpty) {
      throw ArgumentError('text cannot be empty');
    }
    if (text.length > 500) {
      throw ArgumentError('text cannot exceed 500 characters');
    }
    control.validate();
  }

  @override
  Map<String, dynamic> toFirestore() {
    final map = control.toFirestore();
    map['text'] = text;
    // Remove createdAt/updatedAt - repository handles timestamps
    map.remove('createdAt');
    map.remove('updatedAt');
    return map;
  }

  factory ProCardBanner.fromFirestore(Map<String, dynamic> data, String id) {
    return ProCardBanner(
      id: id,
      text: (data['text'] as String?) ?? '',
      control: AdminControlFields.fromFirestore(
        data,
        FirestorePaths.sectionKeyProCard,
      ),
    );
  }
}

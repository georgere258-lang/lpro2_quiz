// Admin flags attached to any topic/document

class AdminFlags {
  final bool isFeatured;
  final bool isImportant;
  final bool isHidden;

  const AdminFlags({
    required this.isFeatured,
    required this.isImportant,
    required this.isHidden,
  });

  factory AdminFlags.defaults() {
    return const AdminFlags(
      isFeatured: false,
      isImportant: false,
      isHidden: false,
    );
  }

  Map<String, dynamic> toMap() => {
        'isFeatured': isFeatured,
        'isImportant': isImportant,
        'isHidden': isHidden,
      };

  factory AdminFlags.fromMap(Map<String, dynamic>? map) {
    if (map == null) return AdminFlags.defaults();
    return AdminFlags(
      isFeatured: map['isFeatured'] ?? false,
      isImportant: map['isImportant'] ?? false,
      isHidden: map['isHidden'] ?? false,
    );
  }
}

// PATH: lib/core/data/models/user_model.dart
// STATUS: FULL FILE — ✅ Safe Legacy Read Doc + Num-safe parsing (no behavior change)
//
// Notes:
// - `starsPoints` is the canonical field for Stars League points.
// - `points_stars` is LEGACY fallback for backward compatibility ONLY.
//   Do NOT write to `points_stars`. It can be removed after legacy data migration.
// - All numeric reads are `num`-safe to avoid runtime type issues (int/double).

class UserModel {
  final String uid;
  final String phone;
  final String name;
  final String photoUrl;
  final int starsPoints;
  final int proPoints;
  final int points; // الحقل الرئيسي للإجمالي في الفايربيز
  final int avatarIndex;
  final String role;

  UserModel({
    required this.uid,
    required this.phone,
    this.name = "",
    this.photoUrl = "",
    this.starsPoints = 0,
    this.proPoints = 0,
    this.points = 0, // الإجمالي العام
    this.avatarIndex = 0,
    this.role = "user",
  });

  String get displayName => (name.trim().isEmpty) ? "Pro" : name;

  // ────────────────────────────────────────────────────────────────────────────
  // Helpers (num-safe reads)
  // ────────────────────────────────────────────────────────────────────────────
  static int _readInt(Map<String, dynamic> data, String key,
      {int fallback = 0}) {
    final v = data[key];
    if (v is num) return v.toInt();
    return fallback;
  }

  static String _readString(Map<String, dynamic> data, String key,
      {String fallback = ''}) {
    final v = data[key];
    if (v is String) return v;
    return fallback;
  }

  // تحويل البيانات القادمة من Firebase (النسخة الذكية)
  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    // 1) Stars League:
    // NOTE: `points_stars` is LEGACY fallback for backward compatibility only.
    // Do NOT write to it. The canonical field is `starsPoints`.
    final int sPoints = _readInt(
      data,
      'starsPoints',
      fallback: _readInt(data, 'points_stars', fallback: 0),
    );

    // 2) Pros League
    final int pPoints = _readInt(data, 'proPoints', fallback: 0);

    // 3) Total points
    // If `points` exists use it; otherwise fallback to sum(stars+pros).
    final int totalPoints =
        _readInt(data, 'points', fallback: (sPoints + pPoints));

    return UserModel(
      uid: documentId,
      phone: _readString(data, 'phone', fallback: ''),
      name: _readString(data, 'name', fallback: ''),
      photoUrl: _readString(data, 'photoUrl', fallback: ''),
      starsPoints: sPoints,
      proPoints: pPoints,
      points: totalPoints,
      avatarIndex: _readInt(data, 'avatarIndex', fallback: 0),
      role: _readString(data, 'role', fallback: 'user'),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'phone': phone,
      'name': name,
      'photoUrl': photoUrl,
      'starsPoints': starsPoints,
      'proPoints': proPoints,
      'points': points, // حفظ الإجمالي لضمان مزامنة الليدربورد
      'avatarIndex': avatarIndex,
      'role': role,
    };
  }
}

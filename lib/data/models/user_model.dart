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

  // تحويل البيانات القادمة من Firebase (النسخة الذكية)
  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    // 1. معالجة دوري النجوم (دعم المسميين القديم والجديد)
    int sPoints = data['starsPoints'] ?? data['points_stars'] ?? 0;

    // 2. معالجة دوري المحترفين
    int pPoints = data['proPoints'] ?? 0;

    // 3. معالجة الإجمالي (points)
    // لو حقل points موجود خده، لو مش موجود اجمع الدوريين
    int totalPoints = data['points'] ?? (sPoints + pPoints);

    return UserModel(
      uid: documentId,
      phone: data['phone'] ?? '',
      name: data['name'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      starsPoints: sPoints,
      proPoints: pPoints,
      points: totalPoints,
      avatarIndex: data['avatarIndex'] ?? 0,
      role: data['role'] ?? 'user',
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

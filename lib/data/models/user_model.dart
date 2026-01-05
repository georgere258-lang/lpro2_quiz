class UserModel {
  final String uid;
  final String phone;
  final String name;
  final String photoUrl;
  final int starsPoints; // نقاط دوري النجوم
  final int proPoints; // نقاط دوري المحترفين
  final int avatarIndex; // الفهرس الخاص بأيقونة المستخدم (Pro الافتراضية هي 0)
  final String role;

  UserModel({
    required this.uid,
    required this.phone,
    this.name = "",
    this.photoUrl = "",
    this.starsPoints = 0,
    this.proPoints = 0,
    this.avatarIndex = 0,
    this.role = "user",
  });

  // دالة ذكية لإرجاع الاسم: إذا كان فارغاً يرجع "Pro"
  String get displayName => (name.trim().isEmpty) ? "Pro" : name;

  // إجمالي النقاط للترتيب العام
  int get totalPoints => starsPoints + proPoints;

  // تحويل البيانات القادمة من Firebase إلى كائن (Model)
  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    return UserModel(
      uid: documentId,
      phone: data['phone'] ?? '',
      name: data['name'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      // دعم مسميات الحقول المختلفة لضمان استقرار البيانات
      starsPoints: data['starsPoints'] ?? 0,
      proPoints: data['proPoints'] ?? 0,
      avatarIndex: data['avatarIndex'] ?? 0,
      role: data['role'] ?? 'user',
    );
  }

  // تحويل الكائن إلى Map لرفعه إلى Firebase
  Map<String, dynamic> toMap() {
    return {
      'phone': phone,
      'name': name,
      'photoUrl': photoUrl,
      'starsPoints': starsPoints,
      'proPoints': proPoints,
      'avatarIndex': avatarIndex,
      'role': role,
    };
  }
}

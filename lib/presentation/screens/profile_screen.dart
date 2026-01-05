import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

// استيراد الثوابت والـ Model
import '../../core/constants/app_colors.dart';
import '../../data/models/user_model.dart';

// استيراد الشاشات
import 'about_screen.dart';
import 'login_screen.dart';
import 'admin_panel.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onSupportPressed;
  const ProfileScreen({super.key, this.onSupportPressed});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final Color deepTeal = AppColors.primaryDeepTeal;
  final Color safetyOrange = AppColors.secondaryOrange;

  final List<IconData> avatars = [
    Icons.workspace_premium,
    Icons.person_pin,
    Icons.face_retouching_natural,
    Icons.sentiment_very_satisfied,
    Icons.stars_rounded,
    Icons.account_circle,
  ];

  String _getMotivationalRank(int points) {
    if (points >= 5000) return "👑 مستشار المعرفة العقارية";
    if (points >= 1500) return "🔥 شغوف بالتطوير";
    if (points >= 500) return "🚀 منطلق نحو المعرفة";
    return "Pro جديد ✨";
  }

  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (c) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("اختر رمز المحترفين الخاص بك",
                style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10),
              itemCount: avatars.length,
              itemBuilder: (ctx, i) => InkWell(
                onTap: () async {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user!.uid)
                      .update({'avatarIndex': i});
                  if (mounted) Navigator.pop(c);
                },
                child: CircleAvatar(
                  backgroundColor: deepTeal.withOpacity(0.1),
                  child: Icon(avatars[i],
                      color: i == 0 ? safetyOrange : deepTeal, size: 40),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(String currentName) {
    TextEditingController nameEdit =
        TextEditingController(text: currentName == "Pro" ? "" : currentName);
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("تعديل الاسم",
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: nameEdit,
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: "اكتب اسمك الحقيقي لتظهر في الدوري",
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c), child: const Text("إلغاء")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: deepTeal,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              if (nameEdit.text.trim().isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user!.uid)
                    .update({'name': nameEdit.text.trim()});
                if (mounted) Navigator.pop(c);
              }
            },
            child: const Text("حفظ", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user?.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            var data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
            var userModel = UserModel.fromMap(data, user?.uid ?? "");
            int avatarIdx = data['avatarIndex'] ?? 0;
            int totalPoints = userModel.starsPoints + userModel.proPoints;

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                const SizedBox(height: 20),
                _buildProfileHeader(
                    userModel.displayName, totalPoints, avatarIdx),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                        child: _buildMiniPointCard(
                            "دوري النجوم", userModel.starsPoints, Colors.blue)),
                    const SizedBox(width: 15),
                    Expanded(
                        child: _buildMiniPointCard("دوري المحترفين",
                            userModel.proPoints, safetyOrange)),
                  ],
                ),
                const SizedBox(height: 35),
                Text("إعدادات الاحتراف",
                    style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: deepTeal.withOpacity(0.8))),
                const SizedBox(height: 10),
                _buildProfileBtn("تغيير اسم الـ Pro", Icons.edit_outlined,
                    () => _showEditDialog(userModel.displayName)),
                _buildProfileBtn(
                    "دعوة محترف جديد",
                    Icons.share_outlined,
                    () => Share.share(
                        "انضم لتحدي L Pro وطور مهاراتك العقارية! 🚀")),
                _buildProfileBtn(
                    "الدعم الفني المباشر",
                    Icons.headset_mic_outlined,
                    widget.onSupportPressed ?? () {},
                    iconColor: Colors.blueAccent),
                _buildProfileBtn("حول L Pro", Icons.info_outline_rounded, () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (c) => const AboutScreen()));
                }),
                if (userModel.role == "admin")
                  _buildProfileBtn(
                      "لوحة التحكم", Icons.admin_panel_settings_outlined, () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (c) => const AdminPanel()));
                  }, iconColor: safetyOrange),
                const Divider(height: 40),
                _buildProfileBtn(
                    "تسجيل الخروج", Icons.logout_rounded, _handleLogout,
                    isExit: true),
                const SizedBox(height: 20),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileHeader(String name, int totalPoints, int avatarIdx) {
    return Column(
      children: [
        GestureDetector(
          onTap: _showAvatarPicker,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: safetyOrange.withOpacity(0.3), width: 3)),
                child: CircleAvatar(
                  radius: 55,
                  backgroundColor: deepTeal,
                  child: Icon(
                    avatars[avatarIdx < avatars.length ? avatarIdx : 0],
                    size: 60,
                    color: avatarIdx == 0 ? safetyOrange : Colors.white,
                  ),
                ),
              ),
              CircleAvatar(
                  radius: 18,
                  backgroundColor: safetyOrange,
                  child: const Icon(Icons.edit, size: 16, color: Colors.white)),
            ],
          ),
        ),
        const SizedBox(height: 15),
        Text(name,
            style: GoogleFonts.cairo(
                fontSize: 24, fontWeight: FontWeight.w900, color: deepTeal)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          decoration: BoxDecoration(
              color: deepTeal.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: deepTeal.withOpacity(0.1))),
          child: Text(_getMotivationalRank(totalPoints),
              style: GoogleFonts.cairo(
                  fontSize: 14, color: deepTeal, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildMiniPointCard(String title, int points, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 5))
        ],
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Text(title,
              style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600])),
          const SizedBox(height: 10),
          Text("$points",
              style: GoogleFonts.poppins(
                  fontSize: 28, fontWeight: FontWeight.w900, color: color)),
          Text("نقطة",
              style: GoogleFonts.cairo(
                  fontSize: 12, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildProfileBtn(String title, IconData icon, VoidCallback onTap,
      {bool isExit = false, Color? iconColor}) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: Colors.grey.withOpacity(0.1))),
      child: ListTile(
        leading: Icon(icon,
            color: isExit ? Colors.redAccent : (iconColor ?? deepTeal),
            size: 24),
        title: Text(title,
            style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isExit ? Colors.redAccent : Colors.black87)),
        trailing: Icon(Icons.arrow_forward_ios_rounded,
            size: 14, color: Colors.grey[400]),
        onTap: onTap,
      ),
    );
  }

  Future<void> _handleLogout() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("تسجيل الخروج",
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: const Text("هل أنت متأكد أنك تريد مغادرة عالم المحترفين؟"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text("إلغاء")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(c, true),
            child: const Text("خروج", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false);
      }
    }
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

// استيراد الثوابت المركزية
import '../../core/constants/app_colors.dart';

// استيراد الشاشات
import 'about_screen.dart';
import 'login_screen.dart';
import 'admin_panel.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;

  // استخدام الألوان المركزية
  final Color deepTeal = AppColors.primaryDeepTeal;
  final Color safetyOrange = AppColors.secondaryOrange;
  final Color lightTeal = const Color(0xFF4FA8A8);

  // دالة تحديد اللقب التحفيزي بناءً على إجمالي النقاط
  String _getMotivationalRank(int points) {
    if (points >= 1500) return "مستشار L Pro العالمي 👑";
    if (points >= 1000) return "خبير L Pro المتميز 🔥";
    if (points >= 500) return "دائم التطور 🚀";
    if (points >= 100) return "دائم التعلم ✨";
    return "عضو جديد 🌱";
  }

  Future<void> _handleLogout() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("تسجيل الخروج",
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: const Text("هل أنت متأكد أنك تريد مغادرة تطبيق L Pro؟"),
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
          (route) => false,
        );
      }
    }
  }

  void _showEditDialog(String currentName) {
    TextEditingController nameEdit = TextEditingController(text: currentName);
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
            hintText: "اكتب اسمك الجديد",
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: deepTeal),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text("ملفي الشخصي",
            style: GoogleFonts.cairo(
                color: deepTeal, fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
      ),
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

            var data = snapshot.data?.data() as Map<String, dynamic>?;
            String name = data?['name'] ?? "عضو L Pro";
            int totalPoints = data?['points'] ?? 0;
            int starsPoints = data?['starsPoints'] ?? 0;
            int proPoints = data?['proPoints'] ?? 0;
            String role = data?['role'] ?? "user";

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                const SizedBox(height: 10),
                _buildProfileHeader(name, totalPoints),
                const SizedBox(height: 25),
                Row(
                  children: [
                    Expanded(
                        child: _buildMiniPointCard(
                            "دوري النجوم", starsPoints, Colors.blue)),
                    const SizedBox(width: 15),
                    Expanded(
                        child: _buildMiniPointCard(
                            "دوري المحترفين", proPoints, safetyOrange)),
                  ],
                ),
                const SizedBox(height: 35),
                Text("الإعدادات العامة",
                    style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: deepTeal.withOpacity(0.8))),
                const SizedBox(height: 10),
                _buildProfileBtn("تعديل الاسم", Icons.edit_outlined,
                    () => _showEditDialog(name)),
                _buildProfileBtn(
                    "دعوة صديق",
                    Icons.share_outlined,
                    () => Share.share(
                        "انضم لتحدي L Pro وطور مهاراتك العقارية! 🚀")),
                _buildProfileBtn("حول التطبيق", Icons.info_outline_rounded, () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (c) => const AboutScreen()));
                }),
                if (role == "admin" || user?.email == "admin@lpro.com")
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

  Widget _buildProfileHeader(String name, int totalPoints) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              border:
                  Border.all(color: safetyOrange.withOpacity(0.5), width: 2)),
          child: CircleAvatar(
            radius: 50,
            backgroundColor: deepTeal,
            child: Text(name.isNotEmpty ? name[0].toUpperCase() : "L",
                style: GoogleFonts.cairo(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ),
        ),
        const SizedBox(height: 12),
        Text(name,
            style: GoogleFonts.cairo(
                fontSize: 22, fontWeight: FontWeight.w900, color: deepTeal)),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          decoration: BoxDecoration(
              color: lightTeal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20)),
          child: Text(_getMotivationalRank(totalPoints),
              style: GoogleFonts.cairo(
                  fontSize: 13, color: lightTeal, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildMiniPointCard(String title, int points, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Text(title,
              style: GoogleFonts.cairo(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text("$points",
              style: GoogleFonts.poppins(
                  fontSize: 24, fontWeight: FontWeight.w900, color: color)),
          Text("نقطة",
              style: GoogleFonts.cairo(
                  fontSize: 11,
                  color: color.withOpacity(0.8),
                  fontWeight: FontWeight.bold)),
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
          side: BorderSide(color: Colors.grey.withOpacity(0.08))),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
        leading: Icon(icon,
            color: isExit ? Colors.redAccent : (iconColor ?? deepTeal),
            size: 22),
        title: Text(title,
            style: GoogleFonts.cairo(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: isExit ? Colors.redAccent : Colors.black87)),
        trailing: Icon(Icons.arrow_forward_ios_rounded,
            size: 14,
            color:
                isExit ? Colors.redAccent.withOpacity(0.5) : Colors.grey[400]),
        onTap: onTap,
      ),
    );
  }
}

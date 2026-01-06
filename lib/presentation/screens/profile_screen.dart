import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

// استيراد الثوابت والمديرين والـ Model
import '../../core/constants/app_colors.dart';
import '../../core/utils/sound_manager.dart'; // مدير الصوت الموحد
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
    SoundManager.playTap();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (c) => Container(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("اختر رمزك كـ Pro",
                style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                    color: deepTeal)),
            const SizedBox(height: 25),
            GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, mainAxisSpacing: 15, crossAxisSpacing: 15),
              itemCount: avatars.length,
              itemBuilder: (ctx, i) => InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () async {
                  SoundManager.playCorrect();
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user!.uid)
                      .update({'avatarIndex': i});
                  if (mounted) Navigator.pop(c);
                },
                child: CircleAvatar(
                  backgroundColor: deepTeal.withOpacity(0.05),
                  child: Icon(avatars[i],
                      color: i == 0 ? safetyOrange : deepTeal, size: 35),
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
    SoundManager.playTap();
    TextEditingController nameEdit =
        TextEditingController(text: currentName == "Pro" ? "" : currentName);
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: Text("تعديل الاسم",
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
                fontWeight: FontWeight.w900, color: deepTeal)),
        content: TextField(
          controller: nameEdit,
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: "اسمك الحقيقي في عالم المحترفين",
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: deepTeal.withOpacity(0.1))),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c),
              child:
                  Text("إلغاء", style: GoogleFonts.cairo(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: deepTeal),
            onPressed: () async {
              if (nameEdit.text.trim().isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user!.uid)
                    .update({'name': nameEdit.text.trim()});
                SoundManager.playCorrect();
                if (mounted) Navigator.pop(c);
              }
            },
            child: Text("حفظ", style: GoogleFonts.cairo(color: Colors.white)),
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
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            var data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
            var userModel = UserModel.fromMap(data, user?.uid ?? "");
            int avatarIdx = data['avatarIndex'] ?? 0;
            int totalPoints = userModel.starsPoints + userModel.proPoints;
            int dailyCount = data['dailyQuestionsCount'] ?? 0;

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                const SizedBox(height: 30),
                _buildProfileHeader(
                    userModel.displayName, totalPoints, avatarIdx),
                const SizedBox(height: 25),

                // كارت تقدم اليوم الجديد
                _buildDailyProgressCard(dailyCount),

                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                        child: _buildMiniPointCard("دوري النجوم",
                            userModel.starsPoints, const Color(0xFF3498DB))),
                    const SizedBox(width: 15),
                    Expanded(
                        child: _buildMiniPointCard("دوري المحترفين",
                            userModel.proPoints, safetyOrange)),
                  ],
                ),

                const SizedBox(height: 30),
                _buildSectionLabel("إعدادات الاحتراف"),
                _buildProfileBtn("تغيير اسم الـ Pro", Icons.edit_note_rounded,
                    () => _showEditDialog(userModel.displayName)),
                _buildProfileBtn("دعوة محترف جديد", Icons.ios_share_rounded,
                    () {
                  SoundManager.playTap();
                  Share.share("انضم لتحدي L Pro وطور مهاراتك العقارية! 🚀");
                }),
                _buildProfileBtn(
                    "الدعم الفني المباشر", Icons.support_agent_rounded, () {
                  SoundManager.playTap();
                  if (widget.onSupportPressed != null) {
                    widget.onSupportPressed!();
                  }
                }, iconColor: Colors.blueAccent),
                _buildProfileBtn("حول L Pro", Icons.info_outline_rounded, () {
                  SoundManager.playTap();
                  Navigator.push(context,
                      MaterialPageRoute(builder: (c) => const AboutScreen()));
                }),

                if (userModel.role == "admin")
                  _buildProfileBtn(
                      "لوحة التحكم (Admin)", Icons.admin_panel_settings_rounded,
                      () {
                    SoundManager.playTap();
                    Navigator.push(context,
                        MaterialPageRoute(builder: (c) => const AdminPanel()));
                  }, iconColor: safetyOrange),

                const Padding(
                    padding: EdgeInsets.symmetric(vertical: 15),
                    child: Divider(thickness: 0.5)),
                _buildProfileBtn(
                    "تسجيل الخروج", Icons.logout_rounded, _handleLogout,
                    isExit: true),
                const SizedBox(height: 30),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDailyProgressCard(int count) {
    double percent = (count / 20).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15)
          ],
          border: Border.all(color: deepTeal.withOpacity(0.05))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("إنجاز اليوم ⚡",
                  style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w900, color: deepTeal)),
              Text("$count / 20 سؤال",
                  style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: safetyOrange)),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: percent,
            backgroundColor: deepTeal.withOpacity(0.05),
            color: safetyOrange,
            minHeight: 8,
            borderRadius: BorderRadius.circular(10),
          ),
        ],
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
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                        colors: [deepTeal, safetyOrange.withOpacity(0.5)]),
                    boxShadow: [
                      BoxShadow(
                          color: deepTeal.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 10))
                    ]),
                child: CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 52,
                    backgroundColor: deepTeal,
                    child: Icon(
                        avatars[avatarIdx < avatars.length ? avatarIdx : 0],
                        size: 55,
                        color: avatarIdx == 0 ? safetyOrange : Colors.white),
                  ),
                ),
              ),
              CircleAvatar(
                  radius: 18,
                  backgroundColor: safetyOrange,
                  child: const Icon(Icons.camera_alt_rounded,
                      size: 16, color: Colors.white)),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(name,
            style: GoogleFonts.cairo(
                fontSize: 24, fontWeight: FontWeight.w900, color: deepTeal)),
        const SizedBox(height: 10),
        Text(_getMotivationalRank(totalPoints),
            style: GoogleFonts.cairo(
                fontSize: 13, color: deepTeal, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _buildMiniPointCard(String title, int points, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ],
        border: Border.all(color: color.withOpacity(0.08), width: 1.5),
      ),
      child: Column(
        children: [
          Text(title,
              style: GoogleFonts.cairo(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey[500])),
          const SizedBox(height: 8),
          Text("$points",
              style: GoogleFonts.poppins(
                  fontSize: 26, fontWeight: FontWeight.w900, color: color)),
          Text("نقطة",
              style: GoogleFonts.cairo(
                  fontSize: 11, color: color, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(text,
          style: GoogleFonts.cairo(
              fontWeight: FontWeight.w900,
              fontSize: 15,
              color: deepTeal.withOpacity(0.8))),
    );
  }

  Widget _buildProfileBtn(String title, IconData icon, VoidCallback onTap,
      {bool isExit = false, Color? iconColor}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ]),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: isExit
                  ? Colors.red.withOpacity(0.05)
                  : (iconColor?.withOpacity(0.05) ??
                      deepTeal.withOpacity(0.05)),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon,
              color: isExit ? Colors.redAccent : (iconColor ?? deepTeal),
              size: 22),
        ),
        title: Text(title,
            style: GoogleFonts.cairo(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: isExit ? Colors.redAccent : Colors.black87)),
        trailing: const Icon(Icons.arrow_back_ios_new_rounded,
            size: 14, color: Color(0xFFEEEEEE)),
        onTap: onTap,
      ),
    );
  }

  Future<void> _handleLogout() async {
    SoundManager.playWrong();
    bool? confirm = await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: Text("تسجيل الخروج",
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
                fontWeight: FontWeight.w900, color: Colors.redAccent)),
        content: Text("هل أنت متأكد أنك تريد مغادرة عالم المحترفين؟",
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(fontSize: 14)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child:
                  Text("إلغاء", style: GoogleFonts.cairo(color: Colors.grey))),
          ElevatedButton(
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () => Navigator.pop(c, true),
              child: const Text("خروج")),
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

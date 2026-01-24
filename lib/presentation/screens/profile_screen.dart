// PATH: lib/presentation/screens/profile_screen.dart
// STATUS: ELITE PREMIUM UPGRADE (Unified Shadows Library)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/sound_manager.dart';
import 'package:lpro2_quiz/core/data/models/user_model.dart';

import 'about_screen.dart';
import 'login_screen.dart';
import 'admin/admin_panel.dart';

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
              return Center(child: CircularProgressIndicator(color: deepTeal));
            }

            final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
            final userModel = UserModel.fromMap(data, user?.uid ?? '');

            return ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                const SizedBox(height: 35),
                _buildProfileHeader(
                  userModel.displayName,
                  userModel.points,
                  userModel.avatarIndex,
                ),
                const SizedBox(height: 35),
                if (widget.onSupportPressed != null)
                  _buildProfileBtn(
                    "الدعم الفني",
                    Icons.support_agent_outlined,
                    () {
                      SoundManager.playTap();
                      widget.onSupportPressed?.call();
                    },
                  ),
                if (userModel.role == 'admin')
                  _buildProfileBtn(
                    "لوحة التحكم (Admin)",
                    Icons.admin_panel_settings_rounded,
                    () {
                      SoundManager.playTap();
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AdminPanel()));
                    },
                    iconColor: safetyOrange,
                  ),
                _buildProfileBtn(
                  "حول L Pro",
                  Icons.info_outline_rounded,
                  () {
                    SoundManager.playTap();
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const AboutScreen()));
                  },
                ),
                _buildProfileBtn(
                  "تسجيل الخروج",
                  Icons.logout_rounded,
                  _handleLogout,
                  isExit: true,
                ),
                const SizedBox(height: 30),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileHeader(String name, int points, int avatarIndex) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // ✅ توحيد مصدر الضوء مع الهوم سكرين عبر المحرك المركزي
            boxShadow: AppColors.eliteShadowL2,
          ),
          child: CircleAvatar(
            radius: 55,
            backgroundColor: deepTeal,
            child: Icon(
              avatars[avatarIndex < avatars.length ? avatarIndex : 0],
              size: 55,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          name,
          style: GoogleFonts.cairo(
              fontSize: 24, fontWeight: FontWeight.w900, color: deepTeal),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: deepTeal.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: deepTeal.withValues(alpha: 0.1)),
          ),
          child: Text(
            _getMotivationalRank(points),
            style: GoogleFonts.cairo(
                fontSize: 13, fontWeight: FontWeight.w800, color: deepTeal),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileBtn(String title, IconData icon, VoidCallback onTap,
      {bool isExit = false, Color? iconColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          // ✅ توحيد ظلال الأزرار لتتبع نفس لغة الظلال العالمية في التطبيق
          boxShadow: AppColors.eliteShadowL1,
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isExit ? Colors.redAccent : (iconColor ?? deepTeal))
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon,
                color: isExit ? Colors.redAccent : (iconColor ?? deepTeal),
                size: 22),
          ),
          title: Text(
            title,
            style: GoogleFonts.cairo(
                fontWeight: FontWeight.w700,
                color: isExit ? Colors.redAccent : Colors.black87),
          ),
          onTap: onTap,
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }
}

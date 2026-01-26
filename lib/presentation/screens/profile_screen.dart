// PATH: lib/presentation/screens/profile_screen.dart
// STATUS: ELITE PREMIUM UPGRADE (Unified Shadows Library)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

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
                  userModel.starsPoints,
                  userModel.proPoints,
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
                _buildProfileBtn(
                  "دعوة Pro جديد",
                  Icons.person_add_rounded,
                  () {
                    SoundManager.playTap();
                    _invitePro();
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
                  "تغيير الاسم",
                  Icons.edit_rounded,
                  () {
                    SoundManager.playTap();
                    _showRenameBottomSheet();
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

  Widget _buildProfileHeader(String name, int points, int avatarIndex, int starsPoints, int proPoints) {
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
        _buildPointsCards(starsPoints, proPoints),
      ],
    );
  }

  Widget _buildPointsCards(int starsPoints, int proPoints) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildPointCard("نجوم", starsPoints, Icons.stars_rounded),
          const SizedBox(width: 12),
          _buildPointCard("محترفين", proPoints, Icons.workspace_premium),
        ],
      ),
    );
  }

  Widget _buildPointCard(String label, int points, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.eliteShadowL1,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: deepTeal),
          const SizedBox(width: 6),
          Text(
            "$label: ",
            style: GoogleFonts.cairo(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.grey[700],
            ),
          ),
          Text(
            "$points",
            style: GoogleFonts.cairo(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: deepTeal,
            ),
          ),
        ],
      ),
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

  Future<void> _invitePro() async {
    const message = "✨ انضم إلى L Pro — طريقك لتطوير نفسك في العقار.\nحمّل التطبيق وابدأ رحلتك الآن 💪";
    try {
      await Share.share(message);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("حدث خطأ في المشاركة", style: GoogleFonts.cairo()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showRenameBottomSheet() async {
    String currentName = '';
    if (user?.uid != null) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();
        if (snapshot.exists && snapshot.data() != null) {
          currentName = (snapshot.data() as Map<String, dynamic>)['name'] ?? '';
        }
      } catch (e) {
        // Fallback to empty
      }
    }

    final TextEditingController nameController = TextEditingController(text: currentName);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 20,
          left: 20,
          right: 20,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "تغيير الاسم",
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: deepTeal,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nameController,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                hintText: "أدخل اسمك",
                hintStyle: GoogleFonts.cairo(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              style: GoogleFonts.cairo(fontSize: 16),
              autofocus: true,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _handleRename(nameController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: deepTeal,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "حفظ",
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _handleRename(String newName) async {
    final trimmedName = newName.trim();
    
    if (trimmedName.length < 3) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("الاسم يجب أن يكون 3 أحرف على الأقل", style: GoogleFonts.cairo()),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({'name': trimmedName});
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("تم تحديث الاسم بنجاح ✅", style: GoogleFonts.cairo()),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        String errorMsg = "حدث خطأ";
        if (e.code == 'permission-denied') {
          errorMsg = "لا توجد صلاحية";
        } else if (e.code == 'unavailable' || e.message?.contains('network') == true) {
          errorMsg = "تحقق من الاتصال";
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg, style: GoogleFonts.cairo()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("حدث خطأ", style: GoogleFonts.cairo()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

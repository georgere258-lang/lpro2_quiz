// PATH: lib/presentation/screens/profile_screen.dart
// STATUS: ULTRA PREMIUM ELITE (Sleek Micro-Cards & Focal Glow)

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
import 'stats_screen.dart';

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

            return Stack(
              children: [
                // ✅ Ultra Premium Radial Glow
                Positioned(
                  top: -50,
                  left: 0,
                  right: 0,
                  height: 350,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0.0, -0.2),
                        radius: 0.8,
                        colors: [
                          deepTeal.withValues(alpha: 0.15),
                          deepTeal.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  children: [
                    const SizedBox(height: 55),
                    _buildProfileHeader(
                      userModel.displayName,
                      userModel.points,
                      userModel.avatarIndex,
                      userModel.starsPoints,
                      userModel.proPoints,
                    ),
                    const SizedBox(height: 35),
                    if (userModel.role == 'admin' ||
                        userModel.role == 'moderator' ||
                        userModel.role == 'manager')
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
                      "تغيير الاسم",
                      Icons.edit_rounded,
                      () {
                        SoundManager.playTap();
                        _showRenameBottomSheet();
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
                    _buildProfileBtn(
                      "حول L Pro",
                      Icons.info_outline_rounded,
                      () {
                        SoundManager.playTap();
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AboutScreen()));
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
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileHeader(String name, int points, int avatarIndex,
      int starsPoints, int proPoints) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            SoundManager.playTap();
            _showAvatarPicker();
          },
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: deepTeal.withValues(alpha: 0.12),
                  blurRadius: 40,
                  spreadRadius: 5,
                ),
                ...AppColors.eliteShadowL3,
              ],
            ),
            child: CircleAvatar(
              radius: 56,
              backgroundColor: deepTeal,
              child: Icon(
                avatars[avatarIndex < avatars.length ? avatarIndex : 0],
                size: 56,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          name,
          style: GoogleFonts.cairo(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: deepTeal,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: safetyOrange.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: safetyOrange.withValues(alpha: 0.15)),
          ),
          child: Text(
            _getMotivationalRank(points),
            style: GoogleFonts.cairo(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: safetyOrange,
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildPointsCards(starsPoints, proPoints),
      ],
    );
  }

  Widget _buildPointsCards(int starsPoints, int proPoints) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // ✅ Sleek Micro-Cards
        Expanded(
            child: _buildPointCard("نجوم", starsPoints, Icons.stars_rounded)),
        const SizedBox(width: 14),
        Expanded(
            child:
                _buildPointCard("محترفين", proPoints, Icons.workspace_premium)),
      ],
    );
  }

  Widget _buildPointCard(String label, int points, IconData icon) {
    final isStars = label == "نجوم";
    return InkWell(
      onTap: () {
        SoundManager.playTap();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StatsScreen(
              initialTab: isStars ? 'stars' : 'pros',
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
            ...AppColors.eliteShadowL1,
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: isStars ? Colors.amber : deepTeal),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey[500],
              ),
            ),
            Text(
              "$points",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: deepTeal,
                height: 1.2,
              ),
            ),
          ],
        ),
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
          boxShadow: AppColors.eliteShadowL1,
        ),
        child: ListTile(
          onTap: onTap,
          dense: true,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isExit ? Colors.redAccent : (iconColor ?? deepTeal))
                  .withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: isExit ? Colors.redAccent : (iconColor ?? deepTeal),
              size: 20,
            ),
          ),
          title: Text(
            title,
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: isExit ? Colors.redAccent : Colors.black87,
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios_rounded,
            size: 12,
            color: Colors.grey[300],
          ),
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
    const message =
        "✨ انضم إلى L Pro — طريقك لتطوير نفسك في العقار.\nحمّل التطبيق وابدأ رحلتك الآن 💪";
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
      } catch (e) {}
    }

    final TextEditingController nameController =
        TextEditingController(text: currentName);

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
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
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
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
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
                      borderRadius: BorderRadius.circular(15)),
                ),
                child: Text("حفظ",
                    style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ),
            const SizedBox(height: 15),
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
              content: Text("الاسم يجب أن يكون 3 أحرف على الأقل",
                  style: GoogleFonts.cairo()),
              backgroundColor: Colors.orange),
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
              content:
                  Text("تم تحديث الاسم بنجاح ✅", style: GoogleFonts.cairo()),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("حدث خطأ", style: GoogleFonts.cairo()),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showAvatarPicker() async {
    if (user == null || !mounted) return;
    int currentIndex = 0;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();
      if (snapshot.exists && snapshot.data() != null) {
        currentIndex = snapshot.data()!['avatarIndex'] ?? 0;
      }
    } catch (e) {}

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 15),
            Text("اختر الأفاتار",
                style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: deepTeal)),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 1.0,
              ),
              itemCount: avatars.length,
              itemBuilder: (context, index) {
                final isSelected = index == currentIndex;
                return GestureDetector(
                  onTap: () => _handleAvatarSelection(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? deepTeal : Colors.grey[50],
                      border: Border.all(
                          color: isSelected ? deepTeal : Colors.grey[200]!,
                          width: isSelected ? 3 : 1),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                  color: deepTeal.withValues(alpha: 0.2),
                                  blurRadius: 10)
                            ]
                          : null,
                    ),
                    child: Icon(avatars[index],
                        size: 35, color: isSelected ? Colors.white : deepTeal),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAvatarSelection(int selectedIndex) async {
    if (user == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({'avatarIndex': selectedIndex});
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text("تم تحديث الأفاتار بنجاح ✅", style: GoogleFonts.cairo()),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("حدث خطأ", style: GoogleFonts.cairo()),
              backgroundColor: Colors.red),
        );
      }
    }
  }
}

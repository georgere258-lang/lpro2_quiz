// PATH: lib/presentation/screens/profile_screen.dart
// STATUS: ULTRA PREMIUM ELITE (Clean UI, No Redundant Settings) - FULL INTEGRATED - FIX V4 (Surgical Fix)

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/sound_manager.dart';
import '../../core/services/user_service.dart';
import 'package:lpro2_quiz/core/data/models/user_model.dart';

import 'about_screen.dart';
import 'login_screen.dart';
import 'admin/admin_panel.dart';
import 'stats_screen.dart';
import 'account_settings_screen.dart';

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

  static const String _androidStoreUrl =
      'https://play.google.com/store/apps/details?id=com.george.lpro';
  static const String _iosStoreUrl =
      'https://apps.apple.com/app/lpro/id6758677424';
  static const String _whatsappChannelUrl =
      'https://whatsapp.com/channel/0029VbCKNM12phHUmptkga2b';
  static const String _whatsappContactUrl = 'https://wa.me/201060620315';

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

  String _buildInviteMessage(String uid) {
    final ref =
        uid.isEmpty ? '' : uid.substring(0, uid.length < 8 ? uid.length : 8);

    final buffer = StringBuffer()
      ..writeln("✨ انضم إلى L Pro — طريقك لتطوير نفسك في العقار.")
      ..writeln("ابدأ رحلتك الآن 💪")
      ..writeln("")
      ..writeln("Android: $_androidStoreUrl")
      ..writeln("iOS: $_iosStoreUrl");

    if (ref.isNotEmpty) buffer.writeln("كود دعوة: $ref");

    return buffer.toString().trim();
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        debugPrint('Could not launch $url');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      resizeToAvoidBottomInset: false,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: StreamBuilder<UserModel?>(
          stream: UserService().currentUserStream,
          builder: (context, snapshot) {
            // معالجة الخطأ لمنع التصفير
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off_rounded,
                        color: Colors.grey, size: 40),
                    const SizedBox(height: 10),
                    Text("خطأ في الاتصال بالسيرفر",
                        style: GoogleFonts.cairo(color: Colors.grey)),
                    TextButton(
                        onPressed: () => setState(() {}),
                        child: const Text("إعادة محاولة")),
                  ],
                ),
              );
            }

            // حالة التحميل (Loading)
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: deepTeal));
            }

            // في حالة عدم وجود داتا (يمنع الانهيار)
            if (!snapshot.hasData || snapshot.data == null) {
              return Center(child: CircularProgressIndicator(color: deepTeal));
            }

            final userModel = snapshot.data!;

            return Stack(
              children: [
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

                    // لوحة التحكم (Admin)
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

                    // تغيير الاسم
                    _buildProfileBtn(
                      "تغيير الاسم",
                      Icons.edit_rounded,
                      () {
                        SoundManager.playTap();
                        _showRenameBottomSheet(userModel.displayName);
                      },
                    ),

                    // دعوة صديق
                    _buildProfileBtn(
                      " دعوه صديق يستفيد ",
                      Icons.person_add_rounded,
                      () {
                        SoundManager.playTap();
                        final msg = _buildInviteMessage(userModel.uid);
                        Share.share(msg);
                      },
                    ),

                    _buildProfileBtn(
                      "قناة الواتساب (مهارات وتطوير)",
                      Icons.campaign_rounded,
                      () {
                        SoundManager.playTap();
                        _launchURL(_whatsappChannelUrl);
                      },
                      iconColor: const Color(0xFF25D366),
                    ),

                    _buildProfileBtn(
                      "اتصل بنا (واتساب)",
                      Icons.chat_bubble_outline_rounded,
                      () {
                        SoundManager.playTap();
                        _launchURL(_whatsappContactUrl);
                      },
                      iconColor: const Color(0xFF128C7E),
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
                      "إعدادات الحساب والخصوصية",
                      Icons.shield_outlined,
                      () {
                        SoundManager.playTap();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AccountSettingsScreen()),
                        );
                      },
                      iconColor: deepTeal,
                    ),

                    // تسجيل الخروج (تم تعديلها جراحياً)
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
            _showAvatarPicker(avatarIndex);
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
        // ✅ [تعطيل كروت النقط] تم إخفاء استدعاء _buildPointsCards بناءً على طلبك
      ],
    );
  }

  Widget _buildPointsCards(int starsPoints, int proPoints) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
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

  // ✅ [تعديل جراحي] حذفنا UserService().dispose() لمنع تعليقة الـ Loading
  Future<void> _handleLogout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  void _showRenameBottomSheet(String currentName) async {
    final TextEditingController nameController =
        TextEditingController(text: currentName);

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(20),
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
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    _handleRename(nameController.text);
                  },
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
      ),
    );
  }

  Future<void> _handleRename(String newName) async {
    final trimmedName = newName.trim();
    if (trimmedName.length < 3) return;

    try {
      await UserService().updateUserData({'name': trimmedName});
      if (mounted) Navigator.pop(context);
    } catch (_) {}
  }

  void _showAvatarPicker(int currentAvatarIndex) async {
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
                final isSelected = index == currentAvatarIndex;
                return GestureDetector(
                  onTap: () => _handleAvatarSelection(index),
                  child: CircleAvatar(
                    backgroundColor: isSelected ? deepTeal : Colors.grey[100],
                    child: Icon(avatars[index],
                        color: isSelected ? Colors.white : deepTeal),
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
    try {
      await UserService().updateUserData({'avatarIndex': selectedIndex});
      if (mounted) Navigator.pop(context);
    } catch (_) {}
  }
}

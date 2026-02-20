// PATH: lib/presentation/screens/account_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_functions/cloud_functions.dart'; // تأكد من وجودها في pubspec.yaml
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/sound_manager.dart';
import 'login_screen.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  bool _isLoading = false;

  Future<void> _executeCloudDelete() async {
    setState(() => _isLoading = true);

    try {
      // ✅ التصحيح: استخدام FirebaseFunctions.instance
      final HttpsCallable callable =
          FirebaseFunctions.instance.httpsCallable('deleteMyAccount');
      final result = await callable.call();

      final data = result.data;
      if (data is Map && data['success'] == true) {
        try {
          await FirebaseAuth.instance.signOut();
        } catch (e) {
          debugPrint("Auth SignOut Silent Error: $e");
        }

        if (mounted) {
          _showDeletionSuccess();
        }
      } else {
        _showErrorSnackBar("فشل حذف الحساب. يرجى مراجعة الإدارة.");
      }
    } catch (e) {
      debugPrint("❌ Cloud Delete Error: $e");
      _showErrorSnackBar("حدث خطأ في السيرفر أو أن الجلسة انتهت.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showPermanentDeleteDialog() {
    final TextEditingController confirmController = TextEditingController();
    bool isTextCorrect = false;

    showDialog(
      context: context,
      barrierDismissible: !_isLoading,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: PopScope(
            canPop: !_isLoading,
            child: AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Colors.redAccent),
                  const SizedBox(width: 10),
                  Text("حذف الحساب نهائياً",
                      style: GoogleFonts.cairo(
                          color: const Color(0xFF1E4D4D),
                          fontWeight: FontWeight.bold,
                          fontSize: 18)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "سيتم حذف كافة بياناتك فوراً. لا يمكن استعادة الحساب بعد هذه الخطوة.",
                    style: GoogleFonts.cairo(
                        fontSize: 14, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 20),
                  Text("اكتب كلمة 'حذف' للتأكيد:",
                      style: GoogleFonts.cairo(
                          fontSize: 12, color: Colors.grey[500])),
                  const SizedBox(height: 8),
                  TextField(
                    controller: confirmController,
                    textAlign: TextAlign.center,
                    onChanged: (val) => setDialogState(
                        () => isTextCorrect = val.trim() == "حذف"),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Colors.redAccent)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300)),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: Text("تراجع",
                        style: GoogleFonts.cairo(color: Colors.grey[600]))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isTextCorrect ? Colors.redAccent : Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: (isTextCorrect && !_isLoading)
                      ? () {
                          Navigator.pop(context);
                          _executeCloudDelete();
                        }
                      : null,
                  child: Text("حذف حسابي",
                      style: GoogleFonts.cairo(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryTeal = Color(0xFF1E4D4D);
    // جلب رقم الهاتف من FirebaseAuth
    final user = FirebaseAuth.instance.currentUser;
    final String userPhone = user?.phoneNumber ?? "غير متوفر";

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        title: Text("إعدادات الحساب",
            style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white)),
        backgroundColor: primaryTeal,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Directionality(
            textDirection: TextDirection.rtl,
            child: ListView(
              padding: const EdgeInsets.all(22),
              children: [
                Text("بيانات الحساب",
                    style: GoogleFonts.cairo(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: primaryTeal)),
                const SizedBox(height: 16),
                _buildStaticTile(
                  title: "رقم الهاتف المسجل",
                  subtitle: userPhone,
                  icon: Icons.phone_android_rounded,
                  color: primaryTeal,
                ),
                const SizedBox(height: 32),
                Text("الأمان والخصوصية",
                    style: GoogleFonts.cairo(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: primaryTeal)),
                const SizedBox(height: 16),
                _buildSettingTile(
                  title: "حذف الحساب نهائياً",
                  subtitle: "مسح بياناتك وفقاً لسياسة آبل",
                  icon: Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                  onTap: _showPermanentDeleteDialog,
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                  child: CircularProgressIndicator(color: primaryTeal)),
            ),
        ],
      ),
    );
  }

  Widget _buildStaticTile(
      {required String title,
      required String subtitle,
      required IconData icon,
      required Color color}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title,
            style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: const Color(0xFF1E4D4D))),
        subtitle: Text(subtitle,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.right,
            style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700])),
      ),
    );
  }

  Widget _buildSettingTile(
      {required String title,
      required String subtitle,
      required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title,
            style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: const Color(0xFF1E4D4D))),
        subtitle: Text(subtitle,
            style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey[600])),
        trailing: Icon(Icons.arrow_forward_ios_rounded,
            size: 12, color: Colors.grey.shade300),
      ),
    );
  }

  void _showDeletionSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("تم حذف الحساب",
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          content: Text("تمت عملية المسح بنجاح.", style: GoogleFonts.cairo()),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false),
                child: Text("إغلاق",
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold))),
          ],
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message, style: GoogleFonts.cairo()),
        backgroundColor: Colors.redAccent));
  }
}

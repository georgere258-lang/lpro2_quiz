// PATH: lib/presentation/screens/complete_profile_screen.dart
// STATUS: ELITE PREMIUM UPGRADE (Cinematic Contrast)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/constants/app_colors.dart';
import 'main_wrapper.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final Color deepTeal = AppColors.primaryDeepTeal;
  final Color safetyOrange = AppColors.secondaryOrange;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _expController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _expController.dispose();
    super.dispose();
  }

  String _replaceArabicNumbers(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    for (int i = 0; i < arabic.length; i++) {
      input = input.replaceAll(arabic[i], english[i]);
    }
    return input;
  }

  Future<void> _saveData({bool isSkipped = false}) async {
    if (!isSkipped && _nameController.text.trim().length < 3) {
      _showError("يرجى إدخال اسمك الكامل بشكل صحيح");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      String processedExp =
          isSkipped ? "0" : _replaceArabicNumbers(_expController.text.trim());

      await FirebaseFirestore.instance.collection('users').doc(user?.uid).set({
        'uid': user?.uid,
        'name': isSkipped ? "مستشار عقاري جديد" : _nameController.text.trim(),
        'email': isSkipped ? "" : _emailController.text.trim(),
        'experience': processedExp,
        'phone': user?.phoneNumber,
        'points': 0,
        'starsPoints': 0,
        'proPoints': 0,
        'level': 'مبتدئ عقاري',
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => const MainWrapper()));
      }
    } catch (e) {
      _showError("عذراً، تعذر حفظ البيانات: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style:
                GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: deepTeal,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [deepTeal, deepTeal.withValues(alpha: 0.85)],
          ),
        ),
        child: Stack(
          children: [
            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextButton(
                    onPressed:
                        _isLoading ? null : () => _saveData(isSkipped: true),
                    child: Text("تخطي",
                        style: GoogleFonts.cairo(
                            color: Colors.white60,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset('assets/logo.svg',
                        height: 90,
                        placeholderBuilder: (c) => const Icon(
                            Icons.business_center,
                            size: 80,
                            color: Colors.white)),
                    const SizedBox(height: 12),
                    Text("المعلومة بتفرق",
                        style: GoogleFonts.cairo(
                            color: safetyOrange,
                            fontSize: 18,
                            fontWeight: FontWeight.w900)),
                    const SizedBox(height: 40),
                    Text("أكملي بياناتكِ يا مريم",
                        style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 35),
                    _buildInput(_nameController, "الاسم الكامل",
                        Icons.person_outline_rounded),
                    const SizedBox(height: 18),
                    _buildInput(_emailController, "البريد الإلكتروني",
                        Icons.email_outlined,
                        type: TextInputType.emailAddress),
                    const SizedBox(height: 18),
                    _buildInput(_expController, "سنوات الخبرة",
                        Icons.trending_up_rounded,
                        type: TextInputType.number, isNumeric: true),
                    const SizedBox(height: 50),
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: safetyOrange,
                          foregroundColor: Colors.white,
                          elevation: 8,
                          shadowColor: safetyOrange.withValues(alpha: 0.3),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18)),
                        ),
                        onPressed: _isLoading
                            ? null
                            : () => _saveData(isSkipped: false),
                        child: _isLoading
                            ? const SizedBox(
                                height: 25,
                                width: 25,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : Text("حفظ ومتابعة",
                                style: GoogleFonts.cairo(
                                    fontWeight: FontWeight.bold, fontSize: 18)),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(
      TextEditingController controller, String label, IconData icon,
      {TextInputType type = TextInputType.text, bool isNumeric = false}) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: TextField(
        controller: controller,
        keyboardType: type,
        textAlign: TextAlign.right,
        style: GoogleFonts.cairo(
            fontSize: 15, color: Colors.white, fontWeight: FontWeight.w600),
        inputFormatters:
            isNumeric ? [FilteringTextInputFormatter.digitsOnly] : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.cairo(color: Colors.white60, fontSize: 13),
          prefixIcon: Icon(icon, color: Colors.white70, size: 22),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.08),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide:
                  BorderSide(color: Colors.white.withValues(alpha: 0.1))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: safetyOrange, width: 2)),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        ),
      ),
    );
  }
}

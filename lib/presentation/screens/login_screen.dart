// PATH: lib/presentation/screens/login_screen.dart
// STATUS: iOS-SAFE OTP (Full Version 56 - Hardened Architectural Fix)

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../core/constants/app_colors.dart';
import 'main_wrapper.dart';

// ✅ [تعديل جراحي v56] استيراد الـ main للوصول لـ LocaleController
import '../../main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isOtpStage = false;
  bool isLoading = false;
  String selectedCountry = "🇪🇬 +20";
  String verificationId = "";

  final TextEditingController phoneController = TextEditingController();

  // ✅ iOS-safe: OTP controllers & Focus
  final TextEditingController otpController = TextEditingController();
  final FocusNode otpFocusNode = FocusNode();

  static const String _bootAdminUid = 'nw2CackXK6PQavoGPAAbhyp6d1R2';

  void _activateNotifications(String uid) async {
    try {
      NotificationSettings settings =
          await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        criticalAlert: true,
        announcement: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        final messaging = FirebaseMessaging.instance;

        if (Platform.isIOS) {
          await messaging.getAPNSToken();
        }

        await messaging.subscribeToTopic('all_users');
        await messaging.subscribeToTopic(uid);

        if (uid == _bootAdminUid) {
          await messaging.subscribeToTopic('admin_notifications');
        }
      }
    } catch (e) {
      debugPrint("Notification Activation Error: $e");
    }
  }

  void _sendOtp() async {
    String phone = phoneController.text.trim();
    if (phone.startsWith('0')) {
      phone = phone.substring(1);
    }

    if (phone.isEmpty || phone.length < 10) {
      _showSnackBar("يرجى إدخال رقم هاتف صحيح", Colors.red);
      return;
    }

    setState(() => isLoading = true);

    // ✅ [تحسين تقني] جلب توكن APNs فوراً لضمان التحقق الصامت في iOS ومنع صفحة الروبوت
    if (Platform.isIOS) {
      try {
        await FirebaseMessaging.instance.getAPNSToken();
      } catch (e) {
        debugPrint("APNs fetch error during send: $e");
      }
    }

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: '${selectedCountry.split(' ')[1]}$phone',
        verificationCompleted: (PhoneAuthCredential credential) async {
          // ✅ [تعديل v56] استعادة اللغة العربية قبل الدخول التلقائي
          LocaleController().restoreArabic();
          await FirebaseAuth.instance.signInWithCredential(credential);
          _navigateUser();
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() => isLoading = false);
          _showSnackBar("خطأ: ${e.message}", Colors.red);
        },
        codeSent: (String verId, int? resendToken) {
          setState(() {
            verificationId = verId;
            isOtpStage = true;
            isLoading = false;
          });

          // ✅ [تعديل جراحي v56] خدعة اللغة: تحويل التطبيق لإنجليزي فوراً
          // هذا يمنع iOS من قلب الكيبورد للعربي عند وصول الـ SMS
          LocaleController().setEnglishTemporarily();

          // ✅ stable focus (iPad safe)
          Future.delayed(const Duration(milliseconds: 350), () {
            if (!mounted) return;
            otpFocusNode.requestFocus();
          });
        },
        codeAutoRetrievalTimeout: (String verId) {
          if (mounted) verificationId = verId;
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      setState(() => isLoading = false);
      _showSnackBar("حدث خطأ في الاتصال", Colors.red);
    }
  }

  void _verifyOtp() async {
    final otp = otpController.text.trim();

    if (otp.length < 6) {
      _showSnackBar("يرجى إدخال الـ 6 أرقام كاملة", Colors.orange);
      return;
    }

    setState(() => isLoading = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      _navigateUser();
    } catch (e) {
      setState(() => isLoading = false);
      _showSnackBar("الرمز غير صحيح، حاول مجدداً", Colors.red);
    }
  }

  void _navigateUser() async {
    final user = FirebaseAuth.instance.currentUser;
    final String? uid = user?.uid;

    if (user != null) {
      try {
        final usersRef = FirebaseFirestore.instance.collection('users');
        final statsRef = FirebaseFirestore.instance.collection('user_stats');
        final userRef = usersRef.doc(user.uid);

        final userDoc =
            await userRef.get().timeout(const Duration(seconds: 10));

        final isBootAdmin = user.uid == _bootAdminUid;

        if (!userDoc.exists) {
          await userRef.set({
            'uid': user.uid,
            'name': "عضو L Pro جديد",
            'phone': user.phoneNumber ?? phoneController.text,
            'points': 0,
            'starsPoints': 0,
            'proPoints': 0,
            'dailyStarsRounds': 0,
            'dailyProsRounds': 0,
            'dailyFreePlayRounds': 0,
            'role': isBootAdmin ? 'admin' : 'user',
            'isBlocked': false,
            'lastQuizDate': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

          await statsRef.doc(user.uid).set({
            'updatedAt': FieldValue.serverTimestamp(),
            'stars': {
              'roundsPlayed': 0,
              'totalPoints': 0,
              'correctAnswers': 0,
              'totalQuestions': 0,
              'wrongAnswers': 0
            },
            'pros': {
              'roundsPlayed': 0,
              'totalPoints': 0,
              'correctAnswers': 0,
              'totalQuestions': 0,
              'wrongAnswers': 0
            },
            'freeplay': {
              'roundsPlayed': 0,
              'totalPoints': 0,
              'correctAnswers': 0,
              'totalQuestions': 0,
              'wrongAnswers': 0
            },
          });
        } else {
          final data = userDoc.data() ?? {};
          final currentRole = (data['role'] ?? '').toString();

          final Map<String, dynamic> patch = {
            'updatedAt': FieldValue.serverTimestamp(),
          };

          if (isBootAdmin && currentRole != 'admin') {
            patch['role'] = 'admin';
          }

          if (data['uid'] == null) patch['uid'] = user.uid;
          if (data['phone'] == null) {
            patch['phone'] = user.phoneNumber ?? phoneController.text;
          }

          if (patch.length > 1) {
            await userRef.set(patch, SetOptions(merge: true));
          }
        }
      } catch (e) {
        debugPrint("⚠️ Network/Firestore Error during navigation: $e");
      }
    }

    if (mounted) {
      setState(() => isLoading = false);

      // ✅ [تعديل جراحي v56] استعادة العربية قبل الانتقال للرئيسية
      LocaleController().restoreArabic();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (c) => const MainWrapper()),
      );

      if (uid != null) {
        Future.delayed(const Duration(milliseconds: 600), () {
          _activateNotifications(uid);
        });
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.cairo()),
        backgroundColor: color,
      ),
    );
  }

  @override
  void dispose() {
    // ✅ [تعديل v56] ضمان استعادة اللغة العربية عند الخروج من الشاشة
    LocaleController().restoreArabic();
    phoneController.dispose();
    otpController.dispose();
    otpFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.3),
            radius: 1.3,
            colors: [
              Color(0xFF136161),
              AppColors.primaryDeepTeal,
            ],
          ),
        ),
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white))
            : Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 50),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          'assets/logo.svg',
                          height: 110,
                          placeholderBuilder: (c) => const Icon(
                            Icons.business,
                            size: 80,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "المعلومة بتفرق",
                          style: GoogleFonts.cairo(
                            color: AppColors.secondaryOrange,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                offset: const Offset(0, 2),
                                blurRadius: 8.0,
                                color: Colors.black.withValues(alpha: 0.3),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 60),
                        Text(
                          isOtpStage ? "تأكيد الرمز" : "تسجيل الدخول",
                          style: GoogleFonts.cairo(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                offset: const Offset(0, 3),
                                blurRadius: 10.0,
                                color: Colors.black.withValues(alpha: 0.4),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          isOtpStage
                              ? "أدخل الكود المرسل لهاتفك"
                              : "اكتب رقم الموبيل",
                          style: GoogleFonts.cairo(
                              fontSize: 14, color: Colors.white70),
                        ),
                        const SizedBox(height: 40),
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: isOtpStage
                              ? _LatinOtpField(
                                  controller: otpController,
                                  focusNode: otpFocusNode)
                              : _buildPhoneInput(),
                        ),
                        const SizedBox(height: 40),
                        Center(
                          child: Container(
                            width: 150,
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.secondaryOrange
                                      .withValues(alpha: 0.25),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.secondaryOrange,
                                elevation: 0,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              onPressed: isOtpStage ? _verifyOtp : _sendOtp,
                              child: Container(
                                alignment: Alignment.center,
                                child: Text(
                                  isOtpStage ? "تأكيد" : "إرسال",
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.cairo(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    height: 1.0,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (isOtpStage)
                          Padding(
                            padding: const EdgeInsets.only(top: 15),
                            child: TextButton(
                              onPressed: () {
                                setState(() {
                                  isOtpStage = false;
                                  otpController.clear();
                                });
                                // ✅ [تعديل v56] استعادة العربية عند التراجع عن الـ OTP
                                LocaleController().restoreArabic();
                              },
                              child: Text(
                                "تعديل رقم الهاتف؟",
                                style: GoogleFonts.cairo(color: Colors.white60),
                              ),
                            ),
                          )
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildPhoneInput() {
    return TextField(
      controller: phoneController,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        letterSpacing: 2,
      ),
      textAlign: TextAlign.left,
      decoration: InputDecoration(
        hintText: "10XXXXXXXX",
        hintStyle: const TextStyle(color: Colors.white38, letterSpacing: 0),
        prefixIcon: PopupMenuButton<String>(
          initialValue: selectedCountry,
          onSelected: (val) => setState(() => selectedCountry = val),
          itemBuilder: (context) => [
            const PopupMenuItem(value: "🇪🇬 +20", child: Text("مصر 🇪🇬")),
            const PopupMenuItem(
                value: "🇦🇪 +971", child: Text("الإمارات 🇦🇪")),
            const PopupMenuItem(
                value: "🇸🇦 +966", child: Text("السعودية 🇸🇦")),
          ],
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 12),
              Text(
                selectedCountry,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Icon(Icons.arrow_drop_down, color: Colors.white),
              const VerticalDivider(
                color: Colors.white24,
                indent: 15,
                endIndent: 15,
              ),
            ],
          ),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

// ✅ [تعديل جراحي v56 - iOS Triple Defense]
class _LatinOtpField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;

  const _LatinOtpField({required this.controller, required this.focusNode});

  @override
  Widget build(BuildContext context) {
    return Localizations.override(
      context: context,
      locale: const Locale('en', 'US'),
      child: SizedBox(
        width: 220,
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          textAlign: TextAlign.center,
          autocorrect: false,
          enableSuggestions: false,
          keyboardAppearance: Brightness.light,
          keyboardType: const TextInputType.numberWithOptions(
            signed: false,
            decimal: false,
          ),
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.oneTimeCode],
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
            _LatinDigitsFormatter(),
          ],
          showCursor: true,
          // ✅ [v56] الدفاع الطبقي: استخدام خط النظام مع Locale إنجليزي لضمان 123
          style: const TextStyle(
            color: Colors.black,
            fontSize: 24,
            height: 1.0,
            fontFamily: 'Roboto', // خط النظام يمنع قلب الأرقام
            fontWeight: FontWeight.bold,
            letterSpacing: 6,
            locale: Locale('en', 'US'),
          ),
          decoration: InputDecoration(
            hintText: "••••••",
            hintStyle: const TextStyle(
              color: Colors.black26,
              fontSize: 18,
              letterSpacing: 6,
              fontFamily: 'Roboto',
              locale: Locale('en', 'US'),
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          onEditingComplete: () {
            FocusScope.of(context).unfocus();
          },
        ),
      ),
    );
  }
}

class _LatinDigitsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    final converted = _convertToLatinDigits(text);

    if (converted != text) {
      return TextEditingValue(
        text: converted,
        selection: TextSelection.collapsed(offset: converted.length),
      );
    }
    return newValue;
  }

  String _convertToLatinDigits(String input) {
    const arabicNumerals = '٠١٢٣٤٥٦٧٨٩';
    const hindiNumerals = '०१२३४٥٦٧٨٩';
    const latinDigits = '0123456789';

    var result = input;
    for (var i = 0; i < arabicNumerals.length; i++) {
      result = result.replaceAll(arabicNumerals[i], latinDigits[i]);
    }
    for (var i = 0; i < hindiNumerals.length; i++) {
      result = result.replaceAll(hindiNumerals[i], latinDigits[i]);
    }
    return result;
  }
}

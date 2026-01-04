import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// تصحيح المسارات للوصول للثوابت والغلاف الرئيسي
import '../../core/constants/app_colors.dart';
import 'main_wrapper.dart';

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

  final List<TextEditingController> otpControllers =
      List.generate(6, (index) => TextEditingController());
  final List<FocusNode> otpFocusNodes =
      List.generate(6, (index) => FocusNode());

  void _activateNotifications(String uid) async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      await messaging.subscribeToTopic('all_users');
      await messaging.subscribeToTopic(uid);
      if (uid == 'nw2CackXK6PQavoGPAAbhyp6d1R2') {
        await messaging.subscribeToTopic('admin_notifications');
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

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: '${selectedCountry.split(' ')[1]}$phone',
        verificationCompleted: (PhoneAuthCredential credential) async {
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
        },
        codeAutoRetrievalTimeout: (String verId) {},
      );
    } catch (e) {
      setState(() => isLoading = false);
      _showSnackBar("حدث خطأ في الاتصال", Colors.red);
    }
  }

  void _verifyOtp() async {
    String otp = otpControllers.map((e) => e.text).join();
    if (otp.length < 6) {
      _showSnackBar("يرجى إدخال الـ 6 أرقام كاملة", Colors.orange);
      return;
    }

    setState(() => isLoading = true);

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
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
    if (user != null) {
      _activateNotifications(user.uid);

      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (!userDoc.exists) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'uid': user.uid,
            'name': "عضو L Pro جديد",
            'phone': user.phoneNumber ?? phoneController.text,
            'points': 0,
            'starsPoints': 0,
            'proPoints': 0,
            'role': 'user',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      } catch (e) {
        debugPrint("Error saving user data: $e");
      }
    }

    if (mounted) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (c) => const MainWrapper()));
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message, style: GoogleFonts.cairo()),
          backgroundColor: color),
    );
  }

  @override
  void dispose() {
    phoneController.dispose();
    for (var c in otpControllers) {
      c.dispose();
    }
    for (var n in otpFocusNodes) {
      n.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDeepTeal,
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 50),
                  child: Column(
                    children: [
                      SvgPicture.asset('assets/logo.svg',
                          height: 110,
                          placeholderBuilder: (c) => const Icon(Icons.business,
                              size: 80, color: Colors.white)),
                      const SizedBox(height: 12),
                      Text("المعلومة بتفرق",
                          style: GoogleFonts.cairo(
                              color: AppColors.secondaryOrange,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 60),
                      Text(isOtpStage ? "تأكيد الرمز" : "تسجيل الدخول",
                          style: GoogleFonts.cairo(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      const SizedBox(height: 10),
                      Text(
                          isOtpStage
                              ? "أدخل الكود المرسل لهاتفك"
                              : "سجل برقم هاتفك لتبدأ التحدي",
                          style: GoogleFonts.cairo(
                              fontSize: 14, color: Colors.white70)),
                      const SizedBox(height: 40),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child:
                            isOtpStage ? _buildOtpInput() : _buildPhoneInput(),
                      ),
                      const SizedBox(height: 40),

                      // --- الحل النهائي لمشكلة توسيط النص في المربع البرتقالي ---
                      Center(
                        child: SizedBox(
                          width: 150,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondaryOrange,
                              elevation: 0,
                              padding:
                                  EdgeInsets.zero, // إلغاء أي بادينج افتراضي
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15)),
                            ),
                            onPressed: isOtpStage ? _verifyOtp : _sendOtp,
                            child: Container(
                              alignment:
                                  Alignment.center, // إجبار التوسط الحسابي
                              child: Text(
                                isOtpStage ? "تأكيد" : "إرسال",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.cairo(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    height:
                                        1.0, // إلغاء المسافات العمودية الافتراضية
                                    fontSize: 18),
                              ),
                            ),
                          ),
                        ),
                      ),

                      if (isOtpStage)
                        Padding(
                          padding: const EdgeInsets.only(top: 15),
                          child: TextButton(
                            onPressed: () => setState(() => isOtpStage = false),
                            child: Text("تعديل رقم الهاتف؟",
                                style:
                                    GoogleFonts.cairo(color: Colors.white60)),
                          ),
                        )
                    ],
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
      style:
          const TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 2),
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
              Text(selectedCountry,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              const Icon(Icons.arrow_drop_down, color: Colors.white),
              const VerticalDivider(
                  color: Colors.white24, indent: 15, endIndent: 15),
            ],
          ),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.1),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildOtpInput() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        6,
        (index) => Container(
          width: 45,
          height: 55,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.fromSwatch()
                  .copyWith(primary: Colors.transparent),
            ),
            child: TextField(
              controller: otpControllers[index],
              focusNode: otpFocusNodes[index],
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 1,
              showCursor: false,
              onChanged: (val) {
                if (val.length == 1 && index < 5) {
                  otpFocusNodes[index + 1].requestFocus();
                }
                if (val.isEmpty && index > 0) {
                  otpFocusNodes[index - 1].requestFocus();
                }
              },
              style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontSize: 22,
                  height: 1.0,
                  fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                counterText: "",
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

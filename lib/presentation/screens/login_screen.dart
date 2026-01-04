import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  // نظام الـ 6 خانات
  final List<TextEditingController> otpControllers =
      List.generate(6, (index) => TextEditingController());
  final List<FocusNode> otpFocusNodes =
      List.generate(6, (index) => FocusNode());

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
    for (var controller in otpControllers) {
      controller.dispose();
    }
    for (var node in otpFocusNodes) {
      node.dispose();
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
                    mainAxisAlignment: MainAxisAlignment.center,
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
                      const SizedBox(height: 40),
                      Text(isOtpStage ? "تأكيد الرمز" : "تسجيل الدخول",
                          style: GoogleFonts.cairo(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      const SizedBox(height: 40),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child:
                            isOtpStage ? _buildOtpInput() : _buildPhoneInput(),
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondaryOrange,
                            elevation: 0,
                            padding: EdgeInsets.zero, // لضمان التوسط
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)),
                          ),
                          onPressed: isOtpStage ? _verifyOtp : _sendOtp,
                          child: Center(
                            child: Text(
                              isOtpStage ? "تأكيد" : "إرسال الرمز",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.cairo(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  height: 1.1),
                            ),
                          ),
                        ),
                      ),
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
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(selectedCountry,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                const Icon(Icons.arrow_drop_down, color: Colors.white),
              ],
            ),
          ),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildOtpInput() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(
        6,
        (index) => SizedBox(
          width: 45,
          child: TextField(
            controller: otpControllers[index],
            focusNode: otpFocusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            onChanged: (val) {
              if (val.length == 1 && index < 5) {
                otpFocusNodes[index + 1].requestFocus();
              }
              if (val.isEmpty && index > 0) {
                otpFocusNodes[index - 1].requestFocus();
              }
            },
            style: const TextStyle(
                color: Colors.black, fontSize: 22, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              counterText: "",
              filled: true,
              fillColor: Colors.white.withOpacity(0.9),
              contentPadding: EdgeInsets.zero, // لضمان توسط الرقم داخل المربع
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
            ),
          ),
        ),
      ),
    );
  }
}

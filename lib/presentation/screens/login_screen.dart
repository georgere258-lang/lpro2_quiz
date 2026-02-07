import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// استيراد الثوابت والصفحات حسب الهيكل المعتمد
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

  // ✅ UID الأدمن الأساسي (نفس اللي مستخدمه في تفعيل إشعارات الإدارة)
  static const String _bootAdminUid = 'nw2CackXK6PQavoGPAAbhyp6d1R2';

  // دالة تفعيل الإشعارات مع طلب الإذن الرسمي
  void _activateNotifications(String uid) async {
    try {
      // طلب الإذن لأجهزة أندرويد الحديثة و iOS
      NotificationSettings settings =
          await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        FirebaseMessaging messaging = FirebaseMessaging.instance;
        await messaging.subscribeToTopic('all_users');
        await messaging.subscribeToTopic(uid);

        // التحقق من الـ UID الخاص بالمسؤول لتفعيل إشعارات الإدارة
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
          // تركيز تلقائي على أول حقل OTP
          Future.delayed(const Duration(milliseconds: 300), () {
            otpFocusNodes[0].requestFocus();
          });
        },
        codeAutoRetrievalTimeout: (String verId) {
          verificationId = verId;
        },
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
    final String? uid = user?.uid;

    if (user != null) {
      try {
        final usersRef = FirebaseFirestore.instance.collection('users');
        final userRef = usersRef.doc(user.uid);

        final userDoc = await userRef.get();
        final isBootAdmin = user.uid == _bootAdminUid;

        if (!userDoc.exists) {
          // ✅ إنشاء أول مرة
          await userRef.set({
            'uid': user.uid,
            'name': "عضو L Pro جديد",
            'phone': user.phoneNumber ?? phoneController.text,
            'points': 0,
            'starsPoints': 0,
            'proPoints': 0,
            'role': isBootAdmin ? 'admin' : 'user',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          // ✅ موجود قبل كده: نثبت Role للأدمن الأساسي بدون مسح أي بيانات
          final data = userDoc.data() ?? {};
          final currentRole = (data['role'] ?? '').toString();

          final Map<String, dynamic> patch = {
            'updatedAt': FieldValue.serverTimestamp(),
          };

          if (isBootAdmin && currentRole != 'admin') {
            patch['role'] = 'admin';
          }

          // كمان نضمن وجود uid/phone لو ناقصين (بدون override للقيم الموجودة)
          if (data['uid'] == null) patch['uid'] = user.uid;
          if (data['phone'] == null) {
            patch['phone'] = user.phoneNumber ?? phoneController.text;
          }

          if (patch.length > 1 ||
              (patch.length == 1 && patch['updatedAt'] != null)) {
            await userRef.set(patch, SetOptions(merge: true));
          }
        }
      } catch (e) {
        debugPrint("Error saving user data: $e");
      }
    }

    if (mounted) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (c) => const MainWrapper()));

      // ✅ طلب إذن الإشعارات بعد دخول المستخدم للتطبيق (بعد نجاح OTP)
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
      // التعديل: استبدال اللون الثابت بتدرج شعاعي بريميوم
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.3),
            radius: 1.3,
            colors: [
              Color(0xFF136161), // درجة إضاءة مركزية
              AppColors.primaryDeepTeal,
            ],
          ),
        ),
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white))
            : Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 50),
                    child: Column(
                      children: [
                        SvgPicture.asset('assets/logo.svg',
                            height: 110,
                            placeholderBuilder: (c) => const Icon(
                                Icons.business,
                                size: 80,
                                color: Colors.white)),
                        const SizedBox(height: 12),
                        Text("المعلومة بتفرق",
                            style: GoogleFonts.cairo(
                                color: AppColors.secondaryOrange,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                // إضافة ظلال ناعمة للنص
                                shadows: [
                                  Shadow(
                                    offset: const Offset(0, 2),
                                    blurRadius: 8.0,
                                    color: Colors.black.withValues(alpha: 0.3),
                                  ),
                                ])),
                        const SizedBox(height: 60),
                        Text(isOtpStage ? "تأكيد الرمز" : "تسجيل الدخول",
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
                                ])),
                        const SizedBox(height: 10),
                        Text(
                            isOtpStage
                                ? "أدخل الكود المرسل لهاتفك"
                                : "اكتب رقم الموبيل",
                            style: GoogleFonts.cairo(
                                fontSize: 14, color: Colors.white70)),
                        const SizedBox(height: 40),
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: isOtpStage
                              ? _buildOtpInput()
                              : _buildPhoneInput(),
                        ),
                        const SizedBox(height: 40),
                        Center(
                          child: Container(
                            width: 150,
                            height: 50,
                            // إضافة ظل متوهج للزر لتحسين المظهر البريميوم
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
                                    borderRadius: BorderRadius.circular(15)),
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
                              onPressed: () =>
                                  setState(() => isOtpStage = false),
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
            // إضافة ظل بسيط لحقول الـ OTP لزيادة البروز
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
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
            ),
          ),
        ),
      ),
    );
  }
}

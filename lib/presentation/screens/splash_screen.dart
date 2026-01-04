import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';

// تصحيح المسارات للوصول للثوابت
import '../../core/constants/app_colors.dart';

// استيراد الشاشات
import 'login_screen.dart';
import 'main_wrapper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  Timer? _navigationTimer;
  bool isUserLoggedIn = false;

  @override
  void initState() {
    super.initState();

    // التحقق من حالة المستخدم
    final user = FirebaseAuth.instance.currentUser;
    isUserLoggedIn = (user != null);

    // إعداد الإنيميشن
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // تشغيل الإنيميشن
    _controller.forward().then((_) {
      if (mounted) _pulseController.repeat(reverse: true);
    });

    // التنقل التلقائي فقط إذا كان المستخدم مسجلاً دخوله
    _navigationTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && isUserLoggedIn) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (c) => const MainWrapper()),
        );
      }
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDeepTeal,
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // اللوجو (مع الحفاظ على الأنيميشن والمقاسات)
            ScaleTransition(
              scale: _scaleAnimation,
              child: SvgPicture.asset(
                'assets/logo.svg',
                width: MediaQuery.of(context).size.width * 0.9,
                fit: BoxFit.contain,
                placeholderBuilder: (c) =>
                    const Icon(Icons.business, size: 120, color: Colors.white),
              ),
            ),

            const SizedBox(height: 20),

            FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Text(
                      "المعلومة بتفرق",
                      style: GoogleFonts.cairo(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: AppColors.secondaryOrange,
                      ),
                    ),
                  ),
                  const SizedBox(height: 45),

                  // إذا لم يكن مسجلاً يظهر زر "يلا Pro"
                  if (!isUserLoggedIn)
                    SizedBox(
                      width: 170,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondaryOrange,
                          padding: EdgeInsets
                              .zero, // إزالة الحواف الداخلية لضمان التوسط
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)),
                        ),
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (c) => const LoginScreen()),
                          );
                        },
                        child: Center(
                          // توسيط النص تماماً
                          child: Text(
                            "يلا Pro",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cairo(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              height: 1.1, // لضبط التوسط الرأسي للنص العربي
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    const CircularProgressIndicator(
                        color: AppColors.secondaryOrange),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

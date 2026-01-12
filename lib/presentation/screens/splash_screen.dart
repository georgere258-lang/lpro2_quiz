import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/constants/app_colors.dart';
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

  bool isUserLoggedIn = false;
  bool showLoginButton = false;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  void _initApp() async {
    final user = FirebaseAuth.instance.currentUser;
    isUserLoggedIn = (user != null);

    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _controller.forward().then((_) {
      if (mounted) _pulseController.repeat(reverse: true);
    });

    // المنطق الوحيد المضاف: 3 ثوانٍ فحص للحالة
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      if (isUserLoggedIn) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (c) => const MainWrapper()));
      } else {
        setState(() => showLoginButton = true);
      }
    });

    _initNotifications();
  }

  void _initNotifications() async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      await messaging.subscribeToTopic('all_users');
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await messaging.subscribeToTopic(user.uid);
        if (user.uid == 'nw2CackXK6PQavoGPAAbhyp6d1R2') {
          await messaging.subscribeToTopic('admin_notifications');
        }
      }
    } catch (e) {
      debugPrint("FCM Error: $e");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDeepTeal,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // توسيط عمودي
          children: [
            // اللوجو بنفس مقاساتك الأصلية
            ScaleTransition(
              scale: _scaleAnimation,
              child: SvgPicture.asset(
                'assets/logo.svg',
                width: MediaQuery.of(context).size.width * 0.8, // المقاس الأصلي
                fit: BoxFit.contain,
                placeholderBuilder: (c) =>
                    const Icon(Icons.business, size: 100, color: Colors.white),
              ),
            ),
            const SizedBox(height: 15),
            FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Text(
                      "المعلومة بتفرق",
                      textAlign: TextAlign.center, // توسيط النص
                      style: GoogleFonts.cairo(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.secondaryOrange,
                      ),
                    ),
                  ),
                  const SizedBox(height: 35),
                  // الزر يظهر فقط للمستخدم الجديد بنفس تصميمك
                  if (showLoginButton)
                    SizedBox(
                      width: 160, // العرض الأصلي من كودك
                      height: 50, // الارتفاع الأصلي من كودك
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondaryOrange,
                          elevation: 0,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25)),
                        ),
                        onPressed: () {
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (c) => const LoginScreen()));
                        },
                        child: Text(
                          "يلا Pro",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                      ),
                    )
                  else if (isUserLoggedIn)
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

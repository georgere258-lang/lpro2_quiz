// PATH: lib/presentation/screens/splash_screen.dart
// STATUS: ULTRA-PREMIUM SMOOTHNESS & SLOW MOTION ✅

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

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
  late final AnimationController _logoController;
  late final AnimationController _textController;
  late final AnimationController _pulseController;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;

  late final Animation<double> _textFade;
  late final Animation<double> _pulseScale;

  bool isUserLoggedIn = false;
  bool showLoginButton = false;

  @override
  void initState() {
    super.initState();

    // ✅ 1. مدة زمنية طويلة (3.5 ثانية) للنعومة الفائقة
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // ✅ 2. استخدام Expo Curve: أهدأ وأفخم منحنى حركة في Flutter
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.9, curve: Curves.easeOutExpo),
      ),
    );

    // ✅ 3. شفافية ناعمة جداً تبدأ متأخرة قليلاً
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.1, 0.6, curve: Curves.easeIn),
      ),
    );

    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeInCirc),
    );

    _pulseScale = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );

    // البدء الفوري
    _logoController.forward();
    _initApp();
  }

  Future<void> _initApp() async {
    try {
      await _ensureFirebaseReady();
      final user = FirebaseAuth.instance.currentUser;
      if (mounted) {
        setState(() {
          isUserLoggedIn = (user != null);
        });
      }
    } catch (_) {
      if (mounted) setState(() => isUserLoggedIn = false);
    }

    // ظهور النص الترحيبي ببطء بعد استقرار اللوجو الجزئي
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      _textController.forward().then((_) {
        if (!mounted) return;
        _pulseController.repeat(reverse: true);
      });
    });

    // مهلة كافية للمستخدم للاستمتاع بالمنظر قبل الانتقال
    Future.delayed(const Duration(milliseconds: 5500), () {
      if (!mounted) return;
      if (isUserLoggedIn) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (c) => const MainWrapper()),
        );
      } else {
        setState(() => showLoginButton = true);
      }
    });
  }

  Future<void> _ensureFirebaseReady() async {
    int attempts = 0;
    while (Firebase.apps.isEmpty && attempts < 50) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }
    if (Firebase.apps.isEmpty) throw Exception('Firebase not ready');
    if (Platform.isIOS) await Future.delayed(const Duration(milliseconds: 400));
  }

  Widget _buildLogo(BuildContext context) {
    final w =
        MediaQuery.of(context).size.width * (Platform.isIOS ? 0.65 : 0.80);
    return Image.asset(
      'assets/logo.png',
      width: w,
      fit: BoxFit.contain,
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _pulseController.dispose();
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
            center: Alignment(0, -0.1),
            radius: 1.4,
            colors: [Color(0xFF136161), AppColors.primaryDeepTeal],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeTransition(
                opacity: _logoFade,
                child: ScaleTransition(
                  scale: _logoScale,
                  child: _buildLogo(context),
                ),
              ),
              const SizedBox(height: 20),
              FadeTransition(
                opacity: _textFade,
                child: Column(
                  children: [
                    ScaleTransition(
                      scale: _pulseScale,
                      child: Text(
                        "المعلومة بتفرق",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: AppColors.secondaryOrange,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 50),
                    if (showLoginButton)
                      _buildPremiumLoginButton()
                    else if (isUserLoggedIn)
                      const CircularProgressIndicator(
                          color: AppColors.secondaryOrange, strokeWidth: 2),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumLoginButton() {
    return AnimatedOpacity(
      opacity: showLoginButton ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 800),
      child: Container(
        width: 150,
        height: 45,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondaryOrange.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondaryOrange,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            elevation: 0,
          ),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (c) => const LoginScreen()),
            );
          },
          child: Text(
            "اهلا Pro",
            style: GoogleFonts.cairo(
              fontSize: 17,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

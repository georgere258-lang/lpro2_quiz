// PATH: lib/presentation/screens/splash_screen.dart
import 'dart:async';
import 'dart:io';
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
    _initApp();
  }

  void _initApp() {
    final user = FirebaseAuth.instance.currentUser;
    isUserLoggedIn = (user != null);

    // 1) Logo: أبطأ + أوضح
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    );

    // 2) Text/Button: يبدأ بعد اللوجو
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    // 3) Pulse بعد ما النص يظهر
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _logoScale = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutCubic),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeIn),
    );

    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );

    _pulseScale = Tween<double>(begin: 1.0, end: 1.035).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // تشغيل: اللوجو -> بعده النص -> بعده النبض
    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      _textController.forward().then((_) {
        if (!mounted) return;
        _pulseController.repeat(reverse: true);
      });
    });

    // وقت كافي لظهور الأنيميشن قبل الانتقال
    Future.delayed(const Duration(milliseconds: 4200), () {
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

    _initNotifications();
  }

  void _initNotifications() async {
    try {
      final messaging = FirebaseMessaging.instance;
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
    _logoController.dispose();
    _textController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  double _logoWidthFactorForPlatform() {
    // iPhone screenshot واضح إن الصورة كبيرة — نقللها على iOS فقط.
    return Platform.isIOS ? 0.62 : 0.78;
  }

  Widget _buildLogo(BuildContext context) {
    final w = MediaQuery.of(context).size.width * _logoWidthFactorForPlatform();

    if (Platform.isIOS) {
      return Image.asset(
        'assets/top_brand.png',
        width: w,
        fit: BoxFit.contain,
      );
    }

    return SvgPicture.asset(
      'assets/logo.svg',
      width: w,
      fit: BoxFit.contain,
      placeholderBuilder: (c) =>
          const Icon(Icons.business, size: 100, color: Colors.white),
    );
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
            radius: 1.2,
            colors: [
              Color(0xFF136161),
              AppColors.primaryDeepTeal,
            ],
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
              const SizedBox(height: 10),

              // النص + الزر يظهروا بعد اللوجو
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
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppColors.secondaryOrange,
                          shadows: [
                            Shadow(
                              offset: const Offset(0, 2),
                              blurRadius: 10.0,
                              color: Colors.black.withValues(alpha: 0.3),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 35),
                    if (showLoginButton)
                      Container(
                        width: 130,
                        height: 38,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(19),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.secondaryOrange
                                  .withValues(alpha: 0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondaryOrange,
                            elevation: 0,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(19),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (c) => const LoginScreen()),
                            );
                          },
                          child: Text(
                            "اهلا Pro",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cairo(
                              fontSize: 15,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              height: 1.0,
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
      ),
    );
  }
}

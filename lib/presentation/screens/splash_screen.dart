// PATH: lib/presentation/screens/splash_screen.dart

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

  void _initApp() {
    final user = FirebaseAuth.instance.currentUser;
    isUserLoggedIn = (user != null);

    // ✅ Logo: slower + stronger
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // ✅ Logo: stronger scale with smooth curve
    _scaleAnimation = Tween<double>(begin: 0.45, end: 1.02).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutExpo),
    );

    // ✅ Text: delayed fade (starts after logo has clearly appeared)
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.58, 1.0, curve: Curves.easeIn),
      ),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _controller.forward();

    // ✅ Start pulse after the text becomes visible
    Future.delayed(const Duration(milliseconds: 1700), () {
      if (!mounted) return;
      _pulseController.repeat(reverse: true);
    });

    // ✅ Navigation timing unchanged (3s)
    Future.delayed(const Duration(seconds: 3), () {
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
    _controller.dispose();
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
              ScaleTransition(
                scale: _scaleAnimation,
                child: SvgPicture.asset(
                  'assets/logo.svg',
                  width: MediaQuery.of(context).size.width * 0.8,
                  fit: BoxFit.contain,
                  placeholderBuilder: (c) => const Icon(
                    Icons.business,
                    size: 100,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    ScaleTransition(
                      scale: _pulseAnimation,
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
                        color: AppColors.secondaryOrange,
                      ),
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

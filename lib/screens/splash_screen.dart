import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';
import 'login_screen.dart';
import '../main_wrapper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  bool isUserLoggedIn = false;

  @override
  void initState() {
    super.initState();

    final user = FirebaseAuth.instance.currentUser;
    isUserLoggedIn = (user != null);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000), 
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    // أنيميشن النبض الهادئ
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _controller.forward().then((_) {
      _pulseController.repeat(reverse: true);
    });

    if (isUserLoggedIn) {
      Timer(const Duration(seconds: 4), () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (c) => const MainWrapper()),
          );
        }
      });
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
    const Color deepTeal = Color(0xFF1B4D57);
    const Color safetyOrange = Color(0xFFE67E22);

    return Scaffold(
      backgroundColor: deepTeal,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: SvgPicture.asset(
                'assets/logo.svg',
                width: MediaQuery.of(context).size.width * 0.6, 
                fit: BoxFit.contain,
              ),
            ),
            
            if (!isUserLoggedIn) ...[
              const SizedBox(height: 50),
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: Text(
                        "المعلومة بتفرق",
                        style: GoogleFonts.cairo(
                          fontSize: 24,
                          fontWeight: FontWeight.w900, // تم تغيير black إلى w900 لحل المشكلة
                          color: safetyOrange,
                          shadows: [
                            Shadow(
                              blurRadius: 8.0,
                              color: Colors.black.withOpacity(0.3),
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 35),
                    SizedBox(
                      width: 170,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: safetyOrange,
                          elevation: 8,
                          shadowColor: Colors.black45,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (c) => const LoginScreen()),
                          );
                        }, 
                        child: Text(
                          "يلا Pro",
                          style: GoogleFonts.cairo(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
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

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
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
      duration: const Duration(milliseconds: 1500),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // الأنيميشن يبدأ من 0.7 ليصل للحجم الطبيعي (1.0) بتأثير الارتداد
    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _controller.forward().then((_) {
      if (mounted) _pulseController.repeat(reverse: true);
    });

    // الانتقال التلقائي بعد 3 ثوانٍ
    Timer(const Duration(seconds: 3), () {
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
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // اللوجو الضخم (90% من عرض الشاشة)
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

            // تم تقليل المسافة هنا من 60 إلى 20 لرفع الجملة للأعلى
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
                        color: safetyOrange,
                      ),
                    ),
                  ),

                  // مسافة تحت النص لتعطي توازن للزرار
                  const SizedBox(height: 45),

                  if (!isUserLoggedIn)
                    SizedBox(
                      width: 170,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: safetyOrange,
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
                        child: Text(
                          "يلا Pro",
                          style: GoogleFonts.cairo(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  else
                    const CircularProgressIndicator(color: safetyOrange),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

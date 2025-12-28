import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // مدة الأنيميشن 2200 مللي ثانية عشان الحركة تكون واضحة ومحسوسة
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    );

    // 1. أنيميشن الظهور (Fade) - ناعم جداً في البداية
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller, 
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn)
      ),
    );

    // 2. أنيميشن التكبير (The Powerful Scale)
    // استخدمنا Curves.elasticOut عشان اللوجو يكبر بسرعة ويحصل فيه "هزة" خفيفة فخمة في الآخر
    _scaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller, 
        curve: const Interval(0.0, 0.8, curve: Curves.elasticOut), 
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // اللوجو بالأنيميشن المحسوس
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: child,
                  ),
                );
              },
              child: Image.asset(
                'assets/top_brand.png',
                height: 150, 
                fit: BoxFit.contain,
                colorBlendMode: BlendMode.dstATop, 
                color: deepTeal,
              ),
            ),
            const SizedBox(height: 25),
            // النص التحفيزي بيظهر بانزلاق خفيف للأعلى بعد استقرار اللوجو
            FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                "المعلومة بتفرق",
                style: GoogleFonts.cairo(
                  color: safetyOrange,
                  fontSize: 18, 
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 60),
            // الزرار الأنيق
            FadeTransition(
              opacity: _fadeAnimation,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: safetyOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  elevation: 10,
                ),
                onPressed: () {
                  Navigator.pushReplacement(
                    context, 
                    MaterialPageRoute(builder: (c) => const LoginScreen())
                  );
                },
                child: Text(
                  "ابدأ الآن", 
                  style: GoogleFonts.cairo(fontSize: 17, fontWeight: FontWeight.bold)
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
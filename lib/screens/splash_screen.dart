import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_wrapper.dart'; // صفحة الكروت
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  double _logoOpacity = 0.0;
  double _textOpacity = 0.0;
  double _buttonOpacity = 0.0;
  double _logoScale = 0.5;
  bool _isLoggedIn = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  static const Color brandOrange = Color(0xFFD3833B); 
  static const Color navyRoyalDeep = Color(0xFF1E2B3E); 
  static const Color navyRoyalMid = Color(0xFF2C3E50);  

  @override
  void initState() {
    super.initState();
    
    // أنيميشن نبض الزر
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _checkLoginStatus();
  }

  // فحص هل المستخدم مسجل دخول مسبقاً
  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    _startAnimations();
  }

  void _startAnimations() async {
    // 1. ظهور اللوجو
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() { _logoOpacity = 1.0; _logoScale = 1.0; });

    // 2. ظهور النصوص
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() { _textOpacity = 1.0; });

    if (_isLoggedIn) {
      // إذا كان مسجل دخول: انتظر ثانية ثم انتقل فوراً لصفحة الكروت
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const MainWrapper()));
      }
    } else {
      // إذا كان أول مرة: أظهر زر START
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) setState(() { _buttonOpacity = 1.0; });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navyRoyalDeep,
      body: Stack(
        children: [
          // خلفية الجزيئات الهندسية (Subtle Background Pattern)
          Positioned.fill(child: CustomPaint(painter: BackgroundPatternPainter())),
          
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [navyRoyalDeep.withOpacity(0.9), navyRoyalMid.withOpacity(0.9)],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedScale(
                  scale: _logoScale,
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOutBack,
                  child: AnimatedOpacity(
                    opacity: _logoOpacity,
                    duration: const Duration(milliseconds: 800),
                    child: SvgPicture.asset('assets/logo.svg', height: 125),
                  ),
                ),
                
                const SizedBox(height: 30),
                
                AnimatedOpacity(
                  opacity: _textOpacity,
                  duration: const Duration(milliseconds: 1000),
                  child: Column(
                    children: [
                      const Text(
                        "Your Real Estate Platform",
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 1.2),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "المعلومة بتفرق",
                        style: TextStyle(color: brandOrange, fontSize: 28, fontWeight: FontWeight.w900, fontFamily: 'Cairo'),
                      ),
                    ],
                  ),
                ),
                
                // تم تقليل المسافة لرفع الزرار
                const SizedBox(height: 50),
                
                // ظهور الزرار فقط في حالة عدم تسجيل الدخول
                if (!_isLoggedIn)
                  AnimatedOpacity(
                    opacity: _buttonOpacity,
                    duration: const Duration(milliseconds: 800),
                    child: ScaleTransition(
                      scale: _pulseAnimation,
                      child: InkWell(
                        onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const LoginScreen())),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10), // تصغير الزر
                          decoration: BoxDecoration(
                            color: brandOrange,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Text(
                            "START",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9), // تغميق لون النص قليلاً
                              fontWeight: FontWeight.bold, 
                              fontSize: 14, 
                              letterSpacing: 1.2
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// رسم خلفية جزيئات هندسية خفيفة جداً
class BackgroundPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04) // شفافة جداً لعدم الإزعاج
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (var i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i.toDouble(), 0), Offset(i.toDouble() + 50, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
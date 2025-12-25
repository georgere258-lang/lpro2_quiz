import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _opacity = 0.0;
  double _scale = 0.6;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() { _opacity = 1.0; _scale = 1.0; });
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color brandOrange = Color(0xFFFF8C42);

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1B3358), Color(0xFF061121)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // اللوجو المكبر
            AnimatedScale(
              scale: _scale,
              duration: const Duration(milliseconds: 1500),
              curve: Curves.easeOutBack,
              child: AnimatedOpacity(
                opacity: _opacity,
                duration: const Duration(milliseconds: 1000),
                child: SvgPicture.asset('assets/logo.svg', height: 140),
              ),
            ),
            const SizedBox(height: 20),
            // الجمل الدعائية الواضحة
            AnimatedOpacity(
              opacity: _opacity,
              duration: const Duration(milliseconds: 1800),
              child: Column(
                children: [
                  const Text(
                    "Your Real Estate Platform",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "المعلومة بتفرق",
                    style: TextStyle(color: brandOrange, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            // زر START المنسق
            AnimatedOpacity(
              opacity: _opacity,
              duration: const Duration(milliseconds: 2200),
              child: InkWell(
                onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const LoginScreen())),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 45, vertical: 12),
                  decoration: BoxDecoration(
                    color: brandOrange,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [BoxShadow(color: brandOrange.withOpacity(0.3), blurRadius: 10)],
                  ),
                  child: const Text("START", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
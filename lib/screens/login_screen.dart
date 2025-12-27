import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_wrapper.dart';

// --- ملف تسجيل الدخول الشامل (Login Screen) ---
// تم التصميم ليكون متوافقاً مع الهوية الملكية (Navy & Gold)

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  
  // =============================================================
  // [1] الإعدادات والمتغيرات (Controllers & State)
  // =============================================================
  final TextEditingController _phoneController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  String _completePhoneNumber = "";

  // أنيميشن العناصر
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // الألوان الموحدة
  static const Color brandOrange = Color(0xFFC67C32); 
  static const Color navyDeep = Color(0xFF1E2B3E); 
  static const Color navyLight = Color(0xFF2C3E50);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // =============================================================
  // [2] المنطق البرمجي (Login & Navigation Logic)
  // =============================================================

  Future<void> _processLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      // محاكاة عملية الاتصال بالسيرفر
      await Future.delayed(const Duration(seconds: 2));

      // حفظ بيانات الدخول والتحقق (الدائم)
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userPhone', _completePhoneNumber);

      if (mounted) {
        setState(() => _isLoading = false);
        _navigateToHome();
      }
    }
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const MainWrapper(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  // =============================================================
  // [3] بناء واجهة المستخدم (The Detailed UI)
  // =============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navyDeep,
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          _buildMainContent(),
        ],
      ),
    );
  }

  // خلفية متدرجة مع جزيئات
  Widget _buildAnimatedBackground() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [navyDeep, navyLight],
        ),
      ),
      child: CustomPaint(painter: BackgroundParticlePainter()),
    );
  }

  Widget _buildMainContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLogoSection(),
                const SizedBox(height: 40),
                _buildWelcomeText(),
                const SizedBox(height: 50),
                _buildPhoneInputField(),
                const SizedBox(height: 30),
                _buildLoginButton(),
                const SizedBox(height: 40),
                _buildFooterLinks(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Widgets فرعية مفصلة ---

  Widget _buildLogoSection() {
    return Column(
      children: [
        SvgPicture.asset(
          'assets/logo.svg',
          height: 100,
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
        ),
        const SizedBox(height: 15),
        Container(
          height: 2,
          width: 50,
          color: brandOrange,
        ),
      ],
    );
  }

  Widget _buildWelcomeText() {
    return Column(
      children: [
        Text(
          isArabic ? "مرحباً بكِ مجدداً" : "Welcome Back",
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isArabic ? "سجلي دخولك للوصول لأدوات المحترفين" : "Login to access Pro tools",
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(
            color: Colors.white.withOpacity(0.5),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneInputField() {
    return IntlPhoneField(
      controller: _phoneController,
      textAlign: isArabic ? TextAlign.right : TextAlign.left,
      dropdownTextStyle: const TextStyle(color: Colors.white),
      style: const TextStyle(color: Colors.white, fontSize: 18),
      cursorColor: brandOrange,
      autofocus: false,
      decoration: InputDecoration(
        labelText: isArabic ? 'رقم الهاتف' : 'Phone Number',
        labelStyle: GoogleFonts.cairo(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: brandOrange, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
      initialCountryCode: 'EG',
      languageCode: isArabic ? "ar" : "en",
      onChanged: (phone) {
        _completePhoneNumber = phone.completeNumber;
      },
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _processLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: brandOrange,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 10,
          shadowColor: brandOrange.withOpacity(0.4),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                isArabic ? "دخول آمن" : "Secure Login",
                style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _buildFooterLinks() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isArabic ? "ليس لديكِ حساب؟ " : "Don't have an account? ",
              style: GoogleFonts.cairo(color: Colors.white60),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                isArabic ? "سجلي الآن" : "Register Now",
                style: GoogleFonts.cairo(color: brandOrange, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          isArabic 
            ? "سيتم إرسال رمز تحقق عند تفعيل الخدمة" 
            : "Verification code will be sent upon activation",
          style: GoogleFonts.cairo(color: Colors.white24, fontSize: 10),
        ),
      ],
    );
  }

  bool get isArabic => Localizations.localeOf(context).languageCode == 'ar' || true;
}

// رسم جزيئات الخلفية لإعطاء عمق بصري (نفس فلسفة الـ Splash)
class BackgroundParticlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < size.width; i += 50) {
      canvas.drawLine(Offset(i.toDouble(), 0), Offset(i.toDouble() - 100, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
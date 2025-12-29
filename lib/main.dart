import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart'; // مكتبة الفايربيز الأساسية
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'main_wrapper.dart';

void main() async {
  // التأكد من تهيئة كل خدمات الـ Flutter قبل تشغيل التطبيق
  WidgetsFlutterBinding.ensureInitialized();
  
  // تهيئة الفايربيز (تأكدي إن ملف google-services.json موجود في مجلد android/app)
  await Firebase.initializeApp();

  runApp(const RealEstateQuizApp());
}

class RealEstateQuizApp extends StatelessWidget {
  const RealEstateQuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'دوري وحوش العقارات',
      debugShowCheckedModeBanner: false,
      
      // إعدادات اللغة العربية (مهمة جداً لظهور التصميم بشكل صحيح)
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar', 'EG')], // تم تعديلها لمصر أو AE حسب رغبتك
      locale: const Locale('ar', 'EG'),

      theme: ThemeData(
        useMaterial3: true,
        // الهوية البصرية الموحدة للفيروزي والبرتقالي
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B4D57),
          primary: const Color(0xFF1B4D57),
          secondary: const Color(0xFFE67E22),
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F7F8),
        textTheme: GoogleFonts.cairoTextTheme(),
      ),

      // تعريف الـ Routes لتسهيل التنقل بين الشاشات
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const MainWrapper(), // الماين ورابر هو اللي بيعرض الهوم
      },
    );
  }
}
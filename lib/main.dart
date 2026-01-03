import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// استيراد الشاشات الأساسية
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/about_screen.dart';
import 'screens/admin_panel.dart';
import 'main_wrapper.dart';

void main() async {
  // التأكد من تهيئة أدوات Flutter قبل بدء التطبيق
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة Firebase بناءً على خيارات المنصة (Android/iOS)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const RealEstateQuizApp());
}

class RealEstateQuizApp extends StatefulWidget {
  const RealEstateQuizApp({super.key});

  // دالة تغيير اللغة من أي مكان في التطبيق
  static void setLocale(BuildContext context, Locale newLocale) {
    _RealEstateQuizAppState? state =
        context.findAncestorStateOfType<_RealEstateQuizAppState>();
    state?.changeLanguage(newLocale);
  }

  @override
  State<RealEstateQuizApp> createState() => _RealEstateQuizAppState();
}

class _RealEstateQuizAppState extends State<RealEstateQuizApp> {
  // اللغة الافتراضية للتطبيق هي العربية
  Locale _locale = const Locale('ar', 'EG');

  void changeLanguage(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    // الألوان الرئيسية للهوية البصرية
    const Color deepTeal = Color(0xFF1B4D57);
    const Color safetyOrange = Color(0xFFE67E22);

    return MaterialApp(
      title: 'أبطال Pro',
      debugShowCheckedModeBanner: false,

      // إعدادات اللغات والترجمة
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar', 'EG'), Locale('en', 'US')],
      locale: _locale,

      // إعدادات التصميم الموحد (Theming)
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: deepTeal,
          primary: deepTeal,
          secondary: safetyOrange,
          surface: Colors.white,
        ),

        // إعدادات الخلفية العامة
        scaffoldBackgroundColor: const Color(0xFFF4F7F8),

        // تطبيق خط Cairo الفخم على كل نصوص التطبيق
        textTheme:
            GoogleFonts.cairoTextTheme(Theme.of(context).textTheme).apply(
          bodyColor: deepTeal,
          displayColor: deepTeal,
        ),

        // تحسين تصميم الأزرار بشكل افتراضي
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: deepTeal,
            foregroundColor: Colors.white,
            textStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),

      // إدارة التنقل (Routing System)
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const MainWrapper(),
        '/about': (context) => const AboutScreen(),
        '/admin': (context) => const AdminPanel(),
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';

// استخدام المسار الكامل المرتبط باسم المشروع (تأكدي أن الاسم lpro2_quiz مطابق لـ pubspec.yaml)
import 'package:lpro2_quiz/firebase_options.dart';
import 'package:lpro2_quiz/core/theme/app_theme.dart';
import 'package:lpro2_quiz/presentation/screens/splash_screen.dart';
import 'package:lpro2_quiz/presentation/screens/login_screen.dart';
import 'package:lpro2_quiz/presentation/screens/complete_profile_screen.dart';
import 'package:lpro2_quiz/presentation/screens/main_wrapper.dart';
import 'package:lpro2_quiz/presentation/screens/about_screen.dart';
import 'package:lpro2_quiz/presentation/screens/admin_panel.dart';

void main() async {
  // التأكد من تهيئة الـ Widgets قبل أي عملية أخرى
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // تهيئة Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase Initialization Error: $e");
  }

  // تثبيت اتجاه الشاشة رأسي فقط لضمان استقرار التصميم (Portrait Only)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const LProApp());
}

class LProApp extends StatefulWidget {
  const LProApp({super.key});

  // دالة لتغيير اللغة من أي مكان في التطبيق
  static void setLocale(BuildContext context, Locale newLocale) {
    _LProAppState? state = context.findAncestorStateOfType<_LProAppState>();
    state?.changeLanguage(newLocale);
  }

  @override
  State<LProApp> createState() => _LProAppState();
}

class _LProAppState extends State<LProApp> {
  // اللغة الافتراضية هي العربية (مصر)
  Locale _locale = const Locale('ar', 'EG');

  void changeLanguage(Locale locale) {
    setState(() => _locale = locale);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'L Pro Quiz',
      debugShowCheckedModeBanner: false,

      // إعدادات اللغات المدعومة
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar', 'EG'), Locale('en', 'US')],
      locale: _locale,

      // تطبيق السمة (Theme) المركزية التي صممناها
      theme: LproTheme.lightTheme,

      // إدارة المسارات (Navigation Management)
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/complete_profile': (context) =>
            const CompleteProfileScreen(), // الشاشة المفقودة سابقاً
        '/home': (context) => const MainWrapper(),
        '/about': (context) => const AboutScreen(),
        '/admin': (context) => const AdminPanel(),
      },
    );
  }
}

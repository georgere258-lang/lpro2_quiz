import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
// استيراد ملف الخيارات اللي ولدناه باستخدام الـ CLI
import 'firebase_options.dart';

// استيراد الشاشات
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'main_wrapper.dart';

void main() async {
  // تأمين ربط أدوات فلاتر قبل التشغيل
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة الفايربيز الرسمية والنهائية
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const RealEstateQuizApp());
}

class RealEstateQuizApp extends StatefulWidget {
  const RealEstateQuizApp({super.key});

  // دالة لتغيير اللغة من أي مكان (مثل زر الإعدادات)
  static void setLocale(BuildContext context, Locale newLocale) {
    _RealEstateQuizAppState? state =
        context.findAncestorStateOfType<_RealEstateQuizAppState>();
    state?.changeLanguage(newLocale);
  }

  @override
  State<RealEstateQuizApp> createState() => _RealEstateQuizAppState();
}

class _RealEstateQuizAppState extends State<RealEstateQuizApp> {
  // اللغة الافتراضية هي العربية (مصر)
  Locale _locale = const Locale('ar', 'EG');

  void changeLanguage(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'دوري وحوش العقارات',
      debugShowCheckedModeBanner: false,

      // إعدادات دعم اللغتين العربية والإنجليزية
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar', 'EG'),
        Locale('en', 'US'),
      ],
      locale: _locale,

      // الثيم الموحد لنسخة الـ Pro (ألوان هوية وحوش العقارات)
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B4D57), // اللون البترولي الأساسي
          primary: const Color(0xFF1B4D57),
          secondary: const Color(0xFFE67E22), // اللون البرتقالي للأزرار والتميز
        ),
        scaffoldBackgroundColor:
            const Color(0xFFF4F7F8), // خلفية هادئة مريحة للعين

        // استخدام خط Cairo لضمان المظهر العربي الاحترافي
        textTheme:
            GoogleFonts.cairoTextTheme(Theme.of(context).textTheme).copyWith(
          titleLarge: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          bodyMedium: GoogleFonts.cairo(),
        ),
      ),

      // خريطة التنقل في التطبيق
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const MainWrapper(),
      },
    );
  }
}

// كلاس النصوص الموحد - ده بيخلينا نغير أي كلمة في التطبيق من هنا في ثواني
class AppStrings {
  static final Map<String, Map<String, String>> _values = {
    'ar': {
      'home': 'الرئيسية',
      'maps': 'الماستر بلان',
      'league': 'الدوري',
      'profile': 'حسابي',
      'lang': 'English',
      'support': 'الدعم الفني',
      'about': 'عن التطبيق',
      'welcome': 'وحش العقارات المتألق',
    },
    'en': {
      'home': 'Home',
      'maps': 'Master Plan',
      'league': 'League',
      'profile': 'Profile',
      'lang': 'العربية',
      'support': 'Support',
      'about': 'About',
      'welcome': 'Brilliant Real Estate Beast',
    }
  };

  static String get(BuildContext context, String key) {
    String code = Localizations.localeOf(context).languageCode;
    return _values[code]?[key] ?? key;
  }
}

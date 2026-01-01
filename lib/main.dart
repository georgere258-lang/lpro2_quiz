import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// استيراد الشاشات
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'main_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const RealEstateQuizApp());
}

class RealEstateQuizApp extends StatefulWidget {
  const RealEstateQuizApp({super.key});

  static void setLocale(BuildContext context, Locale newLocale) {
    _RealEstateQuizAppState? state =
        context.findAncestorStateOfType<_RealEstateQuizAppState>();
    state?.changeLanguage(newLocale);
  }

  @override
  State<RealEstateQuizApp> createState() => _RealEstateQuizAppState();
}

class _RealEstateQuizAppState extends State<RealEstateQuizApp> {
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
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B4D57),
          primary: const Color(0xFF1B4D57),
          secondary: const Color(0xFFE67E22),
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F7F8),
        // تطبيق خط كايرو على كل ستايلات النص بشكل تلقائي
        textTheme: GoogleFonts.cairoTextTheme(Theme.of(context).textTheme),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const MainWrapper(),
      },
    );
  }
}

// كلاس النصوص (AppStrings) يظل كما هو في كودك

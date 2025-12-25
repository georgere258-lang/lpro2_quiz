import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/splash_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const LProApp());
}

class LProApp extends StatelessWidget {
  const LProApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color navyBG = Color(0xFF061121);
    const Color brandOrange = Color(0xFFFF8C42);

    return MaterialApp(
      title: 'LPro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: navyBG,
        fontFamily: 'Cairo',
        
        // الألوان الموحدة للبطاقات والأيقونات
        colorScheme: ColorScheme.dark(
          primary: brandOrange,
          surface: const Color(0xFF1B3358), // لون الأقسام لضمان الوضوح
        ),

        // إعدادات النصوص لتكون بيضاء واضحة
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(color: Colors.white, fontSize: 16),
          bodyMedium: TextStyle(color: Colors.white70, fontSize: 14),
        ),

        // تنسيق الأزرار الموحد
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: brandOrange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
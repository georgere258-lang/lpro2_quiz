// PATH: lib/main.dart
// STATUS: ✅ Integrated with SplashScreen (PNG) & Firebase Initialization Guard

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'presentation/screens/splash_screen.dart'; // تأكد من صحة المسار لديك
import 'core/constants/app_colors.dart';

void main() async {
  // 1. التأكد من تهيئة الروابط قبل أي عمليات Firebase أو UI
  WidgetsFlutterBinding.ensureInitialized();

  // 2. طباعة سجل للتأكد من بدء التنفيذ (مفيد جداً في سجلات Codemagic)
  print("🟢 [LPRO MAIN] Flutter Execution Started for Apple Branch");

  // 3. تهيئة Firebase قبل تشغيل التطبيق لضمان استقرار الخدمات
  try {
    await Firebase.initializeApp();
    print("✅ [FIREBASE] Initialized Successfully");
  } catch (e) {
    print("❌ [FIREBASE] Initialization Error: $e");
    // حتى في حالة الخطأ، سيستمر التطبيق ليعرض شاشة الـ Splash مع معالجة الأخطاء هناك
  }

  runApp(const LProApp());
}

class LProApp extends StatelessWidget {
  const LProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'L Pro Quiz',
      debugShowCheckedModeBanner: false,

      // ✅ ضبط الثيم ليكون له خلفية افتراضية (DeepTeal) بدلاً من الأسود
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF136161),
        useMaterial3: true,
      ),

      // ✅ نقطة الانطلاق هي شاشة الـ Splash التي عدلنا حجم اللوجو فيها
      home: const SplashScreen(),
    );
  }
}

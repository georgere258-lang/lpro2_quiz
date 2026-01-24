// PATH: lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ✅ ضروري جداً للتحكم في الزوايا السفلية
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lpro2_quiz/firebase_options.dart';
import 'package:lpro2_quiz/core/theme/app_theme.dart';
import 'package:lpro2_quiz/core/utils/sound_manager.dart';

import 'package:lpro2_quiz/presentation/screens/splash_screen.dart';
import 'package:lpro2_quiz/presentation/screens/login_screen.dart';
import 'package:lpro2_quiz/presentation/screens/complete_profile_screen.dart';
import 'package:lpro2_quiz/presentation/screens/main_wrapper.dart';
import 'package:lpro2_quiz/presentation/screens/about_screen.dart';
import 'package:lpro2_quiz/presentation/screens/admin/admin_panel.dart';
import 'package:lpro2_quiz/presentation/screens/know_client_screen.dart';

import 'core/curriculum/unit_repository.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'lpro_notifications',
  'L Pro Notifications',
  importance: Importance.max,
);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ التعديل الجذري: إخبار النظام بترك الزوايا السفلية للتطبيق ليلونها
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.transparent, // جعل شريط النظام شفافاً
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
    statusBarColor: Colors.transparent,
  ));

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  SoundManager.init();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await Permission.notification.request();

  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await messaging.subscribeToTopic('all_users');

  _subscribeToNotificationTopics();

  await messaging.requestPermission(alert: true, badge: true, sound: true);

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    RepositoryProvider<UnitRepository>(
      create: (_) => LocalUnitRepository(),
      child: const LProApp(),
    ),
  );
}

void _subscribeToNotificationTopics() {
  FirebaseAuth.instance.authStateChanges().listen((User? user) {
    if (user != null) {
      FirebaseMessaging.instance.subscribeToTopic(user.uid);
      if (user.uid == 'nw2CackXK6PQavoGPAAbhyp6d1R2') {
        FirebaseMessaging.instance.subscribeToTopic('admin_notifications');
      }
    }
  });
}

class LProApp extends StatefulWidget {
  const LProApp({super.key});
  static void setLocale(BuildContext context, Locale newLocale) {
    final state = context.findAncestorStateOfType<_LProAppState>();
    state?.changeLanguage(newLocale);
  }

  @override
  State<LProApp> createState() => _LProAppState();
}

class _LProAppState extends State<LProApp> {
  Locale _locale = const Locale('ar', 'EG');
  void changeLanguage(Locale locale) {
    setState(() => _locale = locale);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'L Pro Quiz',
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
      theme: LproTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (_) => const SplashScreen(),
        '/login': (_) => const LoginScreen(),
        '/complete_profile': (_) => const CompleteProfileScreen(),
        '/home': (_) => const MainWrapper(),
        '/about': (_) => const AboutScreen(),
        '/admin': (_) => const AdminPanel(),
        '/know_client': (_) => const KnowClientScreen(),
      },
    );
  }
}

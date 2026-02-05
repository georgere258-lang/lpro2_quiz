// PATH: lib/main.dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:lpro2_quiz/presentation/screens/main_wrapper.dart';
import 'package:lpro2_quiz/presentation/screens/about_screen.dart';
import 'package:lpro2_quiz/presentation/screens/admin/admin_panel.dart';
import 'package:lpro2_quiz/presentation/screens/know_client_screen.dart';

import 'core/curriculum/unit_repository.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {}
}

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'lpro_notifications',
  'L Pro Notifications',
  importance: Importance.max,
);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

bool _bootstrapStarted = false;

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
    statusBarColor: Colors.transparent,
  ));

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(
    RepositoryProvider<UnitRepository>(
      create: (_) => LocalUnitRepository(),
      child: const LProApp(),
    ),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_bootstrapStarted) return;
    _bootstrapStarted = true;
    unawaited(_bootstrapAfterRunApp());
  });
}

Future<void> _bootstrapAfterRunApp() async {
  try {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 12));

    SoundManager.init();

    // Local notifications init (Android + iOS) — بدون طلب permissions هنا.
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await flutterLocalNotificationsPlugin.initialize(initSettings);

    // Android-only: channel + Android 13+ permission
    if (Platform.isAndroid) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      await Permission.notification.request();
    }

    // ✅ iOS: ممنوع نطلب Permission على أول فتحة (ده كان بيطلع Prompt بدري)
    // هنفعل الإشعارات لاحقًا بعد Login/داخل Settings.
    if (Platform.isAndroid) {
      // Topics (non-fatal)
      unawaited(
        FirebaseMessaging.instance
            .subscribeToTopic('all_users')
            .timeout(const Duration(seconds: 5)),
      );
      _subscribeToNotificationTopics();
    }
  } catch (_) {
    // swallow intentionally to avoid startup crash/hang
  }
}

void _subscribeToNotificationTopics() {
  FirebaseAuth.instance.authStateChanges().listen((User? user) {
    if (user != null) {
      unawaited(FirebaseMessaging.instance.subscribeToTopic(user.uid));
      if (user.uid == 'nw2CackXK6PQavoGPAAbhyp6d1R2') {
        unawaited(
          FirebaseMessaging.instance.subscribeToTopic('admin_notifications'),
        );
      }
    }
  });
}

void unawaited(Future<void> future) {}

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
        '/home': (_) => const MainWrapper(),
        '/about': (_) => const AboutScreen(),
        '/admin': (_) => const AdminPanel(),
        '/know_client': (_) => const KnowClientScreen(),
      },
    );
  }
}

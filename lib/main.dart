// PATH: lib/main.dart
import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:lpro2_quiz/firebase_options.dart';
import 'package:lpro2_quiz/core/theme/app_theme.dart';
import 'package:lpro2_quiz/core/utils/sound_manager.dart';

import 'package:lpro2_quiz/presentation/screens/about_screen.dart';
import 'package:lpro2_quiz/presentation/screens/admin/admin_panel.dart';
import 'package:lpro2_quiz/presentation/screens/know_client_screen.dart';
import 'package:lpro2_quiz/presentation/screens/login_screen.dart';
import 'package:lpro2_quiz/presentation/screens/main_wrapper.dart';
import 'package:lpro2_quiz/presentation/screens/splash_screen.dart';

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

  // UI overlays (sync, safe)
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
    statusBarColor: Colors.transparent,
  ));

  // Background handler early (no Firebase init here)
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Crash handlers early (guarded: may run before Firebase init)
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    try {
      if (Firebase.apps.isNotEmpty) {
        FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      }
    } catch (_) {}
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    try {
      if (Firebase.apps.isNotEmpty) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      }
    } catch (_) {}
    return true;
  };

  // Render UI immediately (prevents iOS watchdog / black or grey screen)
  runApp(
    RepositoryProvider<UnitRepository>(
      create: (_) => LocalUnitRepository(),
      child: const LProApp(),
    ),
  );

  // Heavy work AFTER first frame
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_bootstrapStarted) return;
    _bootstrapStarted = true;
    unawaited(_bootstrapAfterFirstFrame());
  });
}

Future<void> _bootstrapAfterFirstFrame() async {
  try {
    // Orientation (post-frame)
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Firebase init (guarded + timeout)
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 12));

    // Optional: Crashlytics collection (safe after init)
    try {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    } catch (_) {}

    // Sounds
    SoundManager.init();

    // Local notifications init (NO iOS permission prompt here)
    await _initLocalNotifications();

    // Topics (non-fatal)
    _subscribeToNotificationTopics();
  } catch (_) {
    // swallow to avoid any startup crash/hang
  }
}

Future<void> _initLocalNotifications() async {
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

  if (Platform.isAndroid) {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Android 13+ notification permission
    await Permission.notification.request();
  }
}

void _subscribeToNotificationTopics() {
  final messaging = FirebaseMessaging.instance;

  // Non-fatal global topic
  unawaited(messaging.subscribeToTopic('all_users'));

  FirebaseAuth.instance.authStateChanges().listen((User? user) async {
    if (user == null) return;

    // Per-user topic
    unawaited(messaging.subscribeToTopic(user.uid));

    // Admin topic
    if (user.uid == 'nw2CackXK6PQavoGPAAbhyp6d1R2') {
      unawaited(messaging.subscribeToTopic('admin_notifications'));
    }

    // Ensure user doc exists (safe, no crash)
    try {
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      final snap = await userRef.get();
      if (!snap.exists) {
        await userRef.set({
          'uid': user.uid,
          'name': 'عضو L Pro جديد',
          'phone': user.phoneNumber,
          'points': 0,
          'starsPoints': 0,
          'proPoints': 0,
          'role':
              (user.uid == 'nw2CackXK6PQavoGPAAbhyp6d1R2') ? 'admin' : 'user',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await userRef.set({
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (_) {}
  });
}

/// Utility: fire-and-forget without analyzer noise.
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

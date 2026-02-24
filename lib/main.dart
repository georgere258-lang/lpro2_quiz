// PATH: lib/main.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lpro2_quiz/firebase_options.dart';
import 'package:lpro2_quiz/core/theme/app_theme.dart';
import 'package:lpro2_quiz/core/utils/sound_manager.dart';

import 'package:lpro2_quiz/presentation/screens/splash_screen.dart';
import 'package:lpro2_quiz/presentation/screens/login_screen.dart';
import 'package:lpro2_quiz/presentation/screens/main_wrapper.dart';
import 'package:lpro2_quiz/presentation/screens/about_screen.dart';
import 'package:lpro2_quiz/presentation/screens/admin/admin_panel.dart';
import 'package:lpro2_quiz/presentation/screens/know_client_screen.dart';

import 'package:lpro2_quiz/presentation/screens/fact_articles_screen.dart';
import 'package:lpro2_quiz/presentation/screens/know_client_articles_screen.dart';

import 'core/curriculum/unit_repository.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await _saveNotificationLocally(message);
  } catch (_) {}
}

final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'lpro_notifications',
  'LPro Notifications',
  importance: Importance.max,
);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

bool _postBootstrapStarted = false;

StreamSubscription<RemoteMessage>? _onMessageSub;
StreamSubscription<RemoteMessage>? _onOpenedSub;

StreamSubscription<User?>? _authSub;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
    statusBarColor: Colors.transparent,
  ));

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    RepositoryProvider<UnitRepository>(
      create: (_) => LocalUnitRepository(),
      child: const LProApp(),
    ),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_postBootstrapStarted) return;
    _postBootstrapStarted = true;
    unawaited(_postBootstrap());
  });
}

Future<void> _postBootstrap() async {
  try {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    SoundManager.init();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission:
          true, // تم التعديل لـ Apple لظهور النقطة على الجرس
      requestSoundPermission: true,
    );

    final initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload == null || payload.trim().isEmpty) return;

        final data = _safeDecodePayload(payload);
        if (data != null) {
          _handleNotificationTap(data);
        } else {
          _openHome();
        }
      },
    );

    if (Platform.isAndroid) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    _attachForegroundNotificationListener();
    _attachOnMessageOpenedListener();
    await _handleInitialMessageIfAny();

    final messaging = FirebaseMessaging.instance;

    // طلب الصلاحيات مع تفعيل الـ Badge للأيفون
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 🔥 خاص بـ Apple: إظهار التنبيه والنقطة حتى والتطبيق مفتوح
    if (Platform.isIOS) {
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    // 🔥 المزامنة القسرية الآمنة: تعمل في الخلفية بعد 5 ثوانٍ لضمان استقرار التطبيق
    Future.delayed(const Duration(seconds: 5), () async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          print('🚀 [FORCE SYNC] Starting background sync for ${user.uid}');
          String? token = await FirebaseMessaging.instance.getToken();
          if (token != null) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .set({
              'fcmToken': token,
              'platform': Platform.isIOS ? 'ios' : 'android',
              'lastTokenUpdate': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
            print('✅ [FORCE SYNC] Token updated successfully in Firestore');
          }
        } catch (e) {
          print('⚠️ [FORCE SYNC] Deferred: $e');
        }
      }
    });

    _subscribeToNotificationTopics();
  } catch (_) {}
}

void _subscribeToNotificationTopics() {
  _authSub?.cancel();

  _authSub =
      FirebaseAuth.instance.authStateChanges().listen((User? user) async {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🔔 [AUTH] حالة المستخدم تغيرت: ${user?.uid ?? "لا يوجد مستخدم"}');

    if (user != null) {
      print('🚀 [FCM] جاري بدء عملية مزامنة التوكن...');

      unawaited(FirebaseMessaging.instance.subscribeToTopic(user.uid));

      try {
        if (Platform.isIOS) {
          String? apnsToken = await FirebaseMessaging.instance.getAPNSToken();
          if (apnsToken == null) {
            print('⏳ [APNs] التوكن غير جاهز، سأنتظر 3 ثوانٍ...');
            await Future.delayed(const Duration(seconds: 3));
            apnsToken = await FirebaseMessaging.instance.getAPNSToken();
          }
          print('🔑 [APNs] الحالة: ${apnsToken != null ? "جاهز ✅" : "فارغ ❌"}');
        }

        String? token = await FirebaseMessaging.instance.getToken();
        print('🔥 [FCM] التوكن: ${token != null ? "OBTAINED ✅" : "NULL ❌"}');

        if (token != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'fcmToken': token,
            'fcmTokens': FieldValue.arrayUnion([token]),
            'platform': Platform.isIOS ? 'ios' : 'android',
            'lastTokenUpdate': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          print('✅ [SUCCESS] تم مزامنة التوكن في Firestore');
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        }
      } catch (e) {
        print('🔴 [ERROR] فشل في مزامنة التوكن: $e');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      }

      if (user.uid == 'nw2CackXK6PQavoGPAAbhyp6d1R2') {
        unawaited(
            FirebaseMessaging.instance.subscribeToTopic('admin_notifications'));
      }
    }
  });
}

void _attachForegroundNotificationListener() {
  _onMessageSub?.cancel();

  _onMessageSub =
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    try {
      await _saveNotificationLocally(message);

      final notif = message.notification;
      if (notif == null) return;

      final title = notif.title?.trim();
      final body = notif.body?.trim();

      if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
        return;
      }

      final androidDetails = AndroidNotificationDetails(
        channel.id,
        channel.name,
        importance: Importance.max,
        priority: Priority.high,
        icon: 'ic_stat_lpro',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true, // تفعيل تحديث البدج للأيفون
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);
      final payload = message.data.isEmpty ? null : jsonEncode(message.data);

      await flutterLocalNotificationsPlugin.show(
        id,
        title ?? 'LPro',
        body ?? '',
        details,
        payload: payload,
      );
    } catch (_) {}
  });
}

void _attachOnMessageOpenedListener() {
  _onOpenedSub?.cancel();

  _onOpenedSub =
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    final data = message.data;
    if (data.isNotEmpty) {
      _handleNotificationTap(data);
    } else {
      _openHome();
    }
  });
}

Future<void> _handleInitialMessageIfAny() async {
  try {
    final msg = await FirebaseMessaging.instance.getInitialMessage();
    if (msg == null) return;

    final data = msg.data;
    if (data.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 200), () {
        _handleNotificationTap(data);
      });
    } else {
      _openHome();
    }
  } catch (_) {}
}

Map<String, dynamic>? _safeDecodePayload(String payload) {
  try {
    final decoded = jsonDecode(payload);
    if (decoded is Map) {
      return decoded.map((k, v) => MapEntry(k.toString(), v));
    }
  } catch (_) {}
  return null;
}

void _openHome() {
  final nav = _navKey.currentState;
  if (nav == null) return;
  nav.pushNamedAndRemoveUntil('/home', (route) => false);
}

void _handleNotificationTap(Map<String, dynamic> data) {
  final nav = _navKey.currentState;
  if (nav == null) return;

  final collection = (data['collection'] ?? '').toString().trim();
  final docId = (data['docId'] ?? '').toString().trim();

  final route = (data['route'] ?? '').toString().trim();
  const allowedRoutes = {
    '/',
    '/login',
    '/home',
    '/about',
    '/admin',
    '/know_client',
    '/fact_article',
    '/know_client_article',
  };

  if (route.isNotEmpty && allowedRoutes.contains(route)) {
    nav.pushNamed(route, arguments: data);
    return;
  }

  if (collection == 'pro_insight') {
    final title = (data['title'] ?? '').toString().trim();
    final resolved =
        title.isNotEmpty ? title : (docId.isNotEmpty ? docId : 'Pro');

    nav.pushNamedAndRemoveUntil('/home', (r) => false);
    nav.pushNamed(
      '/fact_article',
      arguments: {'title': resolved, 'docId': docId},
    );
    return;
  }

  if (collection == 'know_your_client') {
    final title = (data['title'] ?? '').toString().trim();
    final resolved =
        title.isNotEmpty ? title : (docId.isNotEmpty ? docId : 'Pro');

    nav.pushNamedAndRemoveUntil('/home', (r) => false);
    nav.pushNamed(
      '/know_client_article',
      arguments: {'title': resolved, 'docId': docId},
    );
    return;
  }

  _openHome();
}

Future<void> _saveNotificationLocally(RemoteMessage message) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final String? notifsString = prefs.getString('saved_notifications');
    List<dynamic> notifs = notifsString != null ? jsonDecode(notifsString) : [];

    final now = DateTime.now();
    notifs.removeWhere((item) {
      final timestamp = item['timestamp'] as int?;
      if (timestamp == null) return true;
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      return now.difference(date).inHours > 48;
    });

    final title = message.notification?.title?.trim() ??
        message.data['title']?.toString().trim() ??
        'LPro';
    final body = message.notification?.body?.trim() ??
        message.data['body']?.toString().trim() ??
        '';

    if (title.isEmpty && body.isEmpty) return;

    final newNotif = {
      'id':
          message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'body': body,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'data': message.data,
      'isNew': true,
    };

    if (!notifs.any((n) => n['id'] == newNotif['id'])) {
      notifs.insert(0, newNotif);
    }

    await prefs.setString('saved_notifications', jsonEncode(notifs));
  } catch (e) {
    debugPrint('LPro Notification Save Error: $e');
  }
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
      navigatorKey: _navKey,
      builder: (context, child) {
        final mediaQueryData = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQueryData.copyWith(
            textScaler: mediaQueryData.textScaler.clamp(
              minScaleFactor: 0.9,
              maxScaleFactor: 1.1,
            ),
          ),
          child: child!,
        );
      },
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
      onGenerateRoute: (settings) {
        if (settings.name == '/fact_article') {
          final args = (settings.arguments is Map)
              ? (settings.arguments as Map)
                  .map((k, v) => MapEntry(k.toString(), v))
              : <String, dynamic>{};

          final title = (args['title'] ?? '').toString().trim();
          final docId = (args['docId'] ?? '').toString().trim();
          final resolved =
              title.isNotEmpty ? title : (docId.isNotEmpty ? docId : 'Pro');

          return MaterialPageRoute(
            settings: settings,
            builder: (_) => FactArticlesScreen(title: resolved),
          );
        }

        if (settings.name == '/know_client_article') {
          final args = (settings.arguments is Map)
              ? (settings.arguments as Map)
                  .map((k, v) => MapEntry(k.toString(), v))
              : <String, dynamic>{};

          final title = (args['title'] ?? '').toString().trim();
          final docId = (args['docId'] ?? '').toString().trim();
          final resolved =
              title.isNotEmpty ? title : (docId.isNotEmpty ? docId : 'Pro');

          return MaterialPageRoute(
            settings: settings,
            builder: (_) => KnowClientArticlesScreen(title: resolved),
          );
        }

        return null;
      },
    );
  }
}

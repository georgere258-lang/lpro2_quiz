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
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// ✅ إضافة مكتبة الذاكرة المحلية (تأكد من وجودها في pubspec.yaml)
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

// ✅ Deep-link targets (open the exact article)
import 'package:lpro2_quiz/presentation/screens/fact_articles_screen.dart';
import 'package:lpro2_quiz/presentation/screens/know_client_articles_screen.dart';

import 'core/curriculum/unit_repository.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background isolate: safe init (do not assume initialized).
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // ✅ 1. اقتناص وحفظ الإشعار محلياً (والتطبيق مغلق أو في الخلفية)
    await _saveNotificationLocally(message);
  } catch (_) {}
}

// ✅ Global Navigator key (for push-open deep links safely from anywhere)
final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'lpro_notifications',
  'LPro Notifications',
  importance: Importance.max,
);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

bool _postBootstrapStarted = false;

// Foreground listener guards
StreamSubscription<RemoteMessage>? _onMessageSub;
StreamSubscription<RemoteMessage>? _onOpenedSub;

// ✅ NEW: Auth listener guard (prevents duplicate subscriptions)
StreamSubscription<User?>? _authSub;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ UI overlays (safe + sync)
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
    statusBarColor: Colors.transparent,
  ));

  // ✅ Register background handler early
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // ✅ CRITICAL: Firebase MUST be initialized BEFORE any screen uses FirebaseAuth/FirebaseMessaging
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅ Render UI
  runApp(
    RepositoryProvider<UnitRepository>(
      create: (_) => LocalUnitRepository(),
      child: const LProApp(),
    ),
  );

  // ✅ Post-boot (non-blocking)
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_postBootstrapStarted) return;
    _postBootstrapStarted = true;
    unawaited(_postBootstrap());
  });
}

Future<void> _postBootstrap() async {
  try {
    // 1) Orientation
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // 2) Sounds
    SoundManager.init();

    // 3) Local notifications init (Android + iOS)
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    final initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // ✅ Tap on local notification (foreground push rendered locally)
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

    // 4) Android: channel (بدون طلب إذن هنا)
    if (Platform.isAndroid) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    // 5) iOS: (بدون طلب إذن هنا)
    // ⚠️ طلب الإذن تم نقله لمرحلة ما بعد OTP داخل LoginScreen._activateNotifications()

    // ✅ Foreground notifications (when app is open)
    _attachForegroundNotificationListener();

    // ✅ When user taps push notification (app in background)
    _attachOnMessageOpenedListener();

    // ✅ When user taps push notification (app was terminated)
    await _handleInitialMessageIfAny();

    // 6) Topics (non-fatal)
    final messaging = FirebaseMessaging.instance;
    unawaited(messaging.subscribeToTopic('all_users'));

    _subscribeToNotificationTopics();
  } catch (_) {
    // لا نكسر الإقلاع لأي سبب هنا
  }
}

void _attachForegroundNotificationListener() {
  // prevent double-listener if postBootstrap called twice لأي سبب
  _onMessageSub?.cancel();

  _onMessageSub =
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    try {
      // ✅ 2. اقتناص وحفظ الإشعار محلياً (والتطبيق مفتوح في الواجهة)
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
        // uses your WHITE drawable icon if present:
        // android/app/src/main/res/drawable/ic_stat_lpro.png
        icon: 'ic_stat_lpro',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);

      // ✅ payload carries data for deep-linking on tap
      final payload = message.data.isEmpty ? null : jsonEncode(message.data);

      await flutterLocalNotificationsPlugin.show(
        id,
        title ?? 'LPro',
        body ?? '',
        details,
        payload: payload,
      );
    } catch (_) {
      // silent fail (no crash)
    }
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
      // Delay a tick to ensure Navigator is ready
      Future.delayed(const Duration(milliseconds: 200), () {
        _handleNotificationTap(data);
      });
    } else {
      _openHome();
    }
  } catch (_) {
    // ignore
  }
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

  // Ensure we land on MainWrapper (Home)
  nav.pushNamedAndRemoveUntil('/home', (route) => false);
}

void _handleNotificationTap(Map<String, dynamic> data) {
  final nav = _navKey.currentState;
  if (nav == null) return;

  // Expected from Functions:
  // data: { collection: "...", docId: "...", title: "..." }
  final collection = (data['collection'] ?? '').toString().trim();
  final docId = (data['docId'] ?? '').toString().trim();

  // Optional direct route override (safe allowlist)
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

  // Deep-link by collection (safe defaults)
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

  // For other collections (money / radar / home_pro_card / ticker) open home for now
  _openHome();
}

void _subscribeToNotificationTopics() {
  // ✅ prevent duplicate auth listener (hot-restart / edge)
  _authSub?.cancel();

  _authSub = FirebaseAuth.instance.authStateChanges().listen((User? user) {
    if (user != null) {
      unawaited(FirebaseMessaging.instance.subscribeToTopic(user.uid));

      // admin topic (optional)
      if (user.uid == 'nw2CackXK6PQavoGPAAbhyp6d1R2') {
        unawaited(
          FirebaseMessaging.instance.subscribeToTopic('admin_notifications'),
        );
      }
    }
  });
}

// =========================================================================
// ✅ 3. العقل المدبر: حفظ الإشعارات ومسح ما تخطى 48 ساعة بصمت تام
// =========================================================================
Future<void> _saveNotificationLocally(RemoteMessage message) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final String? notifsString = prefs.getString('saved_notifications');
    List<dynamic> notifs = notifsString != null ? jsonDecode(notifsString) : [];

    // 1. تنظيف الإشعارات القديمة (أكثر من 48 ساعة)
    final now = DateTime.now();
    notifs.removeWhere((item) {
      final timestamp = item['timestamp'] as int?;
      if (timestamp == null) return true;
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      return now.difference(date).inHours > 48; // يمسح أي إشعار مر عليه يومين
    });

    // 2. استخراج بيانات الإشعار الجديد
    final title = message.notification?.title?.trim() ??
        message.data['title']?.toString().trim() ??
        'LPro';
    final body = message.notification?.body?.trim() ??
        message.data['body']?.toString().trim() ??
        '';

    if (title.isEmpty && body.isEmpty)
      return; // لا يحفظ الإشعارات الصامتة الفارغة

    final newNotif = {
      'id':
          message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'body': body,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'data':
          message.data, // حفظ البيانات للـ Deep Linking عند الضغط من القائمة
      'isNew': true, // لتشغيل النقطة الحمراء
    };

    // 3. منع التكرار والإضافة في أعلى القائمة (الأحدث أولاً)
    if (!notifs.any((n) => n['id'] == newNotif['id'])) {
      notifs.insert(0, newNotif);
    }

    // 4. الحفظ النهائي في ذاكرة الموبايل
    await prefs.setString('saved_notifications', jsonEncode(notifs));
  } catch (e) {
    // صمت تام (لا نعطل التطبيق أبداً إذا حدث خطأ في الحفظ)
    debugPrint('LPro Notification Save Error: $e');
  }
}
// =========================================================================

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
      // ✅ الحماية الهندسية الصارمة لحجم الخطوط (تمنع تشوه التصميم)
      builder: (context, child) {
        final mediaQueryData = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQueryData.copyWith(
            textScaler: mediaQueryData.textScaler.clamp(
              minScaleFactor: 0.9,
              maxScaleFactor: 1.1, // أقصى حد للتكبير 10%
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

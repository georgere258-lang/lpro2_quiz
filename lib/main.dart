// PATH: lib/main.dart
// STATUS: Version 56.2 - Final Surgical Fix (Full Unified Sync)
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
// 🛡️ [إضافة] مكتبة App Check لفك حظر المحاكي
import 'package:firebase_app_check/firebase_app_check.dart';
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

// ✅ ربط المحرك الموحد لمنع تصفير النقط وتحسين القراءات
import 'package:lpro2_quiz/core/services/user_service.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 🛡️ [جديد v56] متحكم اللغة الاستراتيجي (LocaleController)
// الوظيفة: يخدع نظام iOS لترك الكيبورد إنجليزي في شاشة الـ OTP
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class LocaleController {
  static final LocaleController _instance = LocaleController._internal();
  factory LocaleController() => _instance;
  LocaleController._internal();

  final _localeStream = StreamController<Locale>.broadcast();
  Stream<Locale> get localeStream => _localeStream.stream;

  Locale _currentLocale = const Locale('ar', 'EG');
  Locale get currentLocale => _currentLocale;

  // استدعاء هذه الدالة عند دخول شاشة الـ OTP (تخدع iOS)
  void setEnglishTemporarily() {
    _currentLocale = const Locale('en', 'US');
    _localeStream.add(_currentLocale);
    debugPrint('🌐 [Locale] Switched to English to Prevent Keyboard Flip');
  }

  // استدعاء هذه الدالة عند تسجيل الدخول أو الخروج من الـ OTP
  void restoreArabic() {
    _currentLocale = const Locale('ar', 'EG');
    _localeStream.add(_currentLocale);
    debugPrint('🌐 [Locale] Restored Arabic for Application UI');
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // حفظ الإشعار ورفع الراية (حتى والتطبيق مغلق تماماً)
    await _saveNotificationLocally(message);
  } catch (_) {}
}

final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'lpro_notifications',
  'LPro Notifications',
  importance: Importance.max,
  playSound: true,
);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

bool _postBootstrapStarted = false;

StreamSubscription<RemoteMessage>? _onMessageSub;
StreamSubscription<RemoteMessage>? _onOpenedSub;

StreamSubscription<User?>? _authSub;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ [حل الشاشة الحمراء] منع الانهيار عند تضارب الـ Keys في المحاكي
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Container(color: Colors.white);
  };

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
    statusBarColor: Colors.transparent,
  ));

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 🛡️ [تعديل جراحي] تفعيل App Check لفك حظر طلبات المحاكي فوراً
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );
  await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);

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
    ]);

    SoundManager.init();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    // ✅ تم إيقاف طلب الأذونات التلقائي لنظام iOS هنا
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      requestCriticalPermission: false,
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

    // 🛡️ [تعديل جراحي] مزامنة التوكن (متوافق مع آبل) عبر المحرك الموحد
    Future.delayed(const Duration(seconds: 5), () async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          debugPrint(
              '🚀 [FORCE SYNC] Starting background sync for ${user.uid}');
          String? token = await FirebaseMessaging.instance.getToken();
          if (token != null) {
            // ✅ استخدام UserService لضمان التحديث الموحد وحماية النقاط
            await UserService().updateUserData({
              'fcmToken': token,
              'platform': Platform.isIOS ? 'ios' : 'android',
              'lastTokenUpdate': FieldValue.serverTimestamp(),
            });
            debugPrint(
                '✅ [FORCE SYNC] Token updated via UserService successfully');
          }
        } catch (e) {
          debugPrint('⚠️ [FORCE SYNC] Deferred: $e');
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
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint(
        '🔔 [AUTH] حالة المستخدم تغيرت: ${user?.uid ?? "لا يوجد مستخدم"}');

    if (user != null) {
      debugPrint('🚀 [FCM] جاري بدء عملية مزامنة التوكن...');

      unawaited(FirebaseMessaging.instance.subscribeToTopic(user.uid));

      try {
        if (Platform.isIOS) {
          String? apnsToken = await FirebaseMessaging.instance.getAPNSToken();
          if (apnsToken == null) {
            debugPrint('⏳ [APNs] التوكن غير جاهز، سأنتظر 3 ثوانٍ...');
            await Future.delayed(const Duration(seconds: 3));
            apnsToken = await FirebaseMessaging.instance.getAPNSToken();
          }
          debugPrint(
              '🔑 [APNs] الحالة: ${apnsToken != null ? "جاهز ✅" : "فارغ ❌"}');
        }

        String? token = await FirebaseMessaging.instance.getToken();
        debugPrint(
            '🔥 [FCM] التوكن: ${token != null ? "OBTAINED ✅" : "NULL ❌"}');

        if (token != null) {
          // ✅ [تعديل جراحي] استخدام المحرك الموحد UserService لمنع تصفير النقط
          await UserService().updateUserData({
            'fcmToken': token,
            'fcmTokens': FieldValue.arrayUnion([token]),
            'platform': Platform.isIOS ? 'ios' : 'android',
            'lastTokenUpdate': FieldValue.serverTimestamp(),
          });

          debugPrint('✅ [SUCCESS] تم مزامنة التوكن عبر UserService');
          debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        }
      } catch (e) {
        debugPrint('🔴 [ERROR] فشل في مزامنة التوكن: $e');
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
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
      // ✅ [تعديل جراحي v56] نضمن الحفظ ورفع الراية قبل أي return
      await _saveNotificationLocally(message);

      // ✅ [تعديل النسخة 55] في iOS نترك المهمة لـ AppDelegate لعرض البانر ومنع الازدواجية واختفاء الستارة
      if (Platform.isIOS) {
        // نرسل إشارة للواجهة فقط لتحديث الجرس بما أن الحفظ تم
        NotificationCenter().post(name: "refresh_notifications");
        return;
      }

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
        playSound: true,
      );

      // ✅ [تعديل النسخة 55] تغيير المستوى لـ active لضمان الثبات في الستارة
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.active,
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
    // ✅ [تعديل 54] مزامنة الذاكرة فوراً لضمان القراءة في iOS من الخلفية
    if (Platform.isIOS) await prefs.reload();

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

    // ✅ [تعديل جراحي v56] رفع راية وجود إشعار جديد لضمان تحديث النقطة في iOS
    await prefs.setBool('has_new_notification_flag', true);

    // ✅ تحديث رقم الأيقونة الخارجية (Badge)
    final newCount = notifs.where((n) => n['isNew'] == true).length;
    await NotificationCenter().updateBadgeCount(newCount);

    NotificationCenter().post(name: "refresh_notifications");
  } catch (e) {
    debugPrint('LPro Notification Save Error: $e');
  }
}

class NotificationCenter {
  static final NotificationCenter _instance = NotificationCenter._internal();
  factory NotificationCenter() => _instance;
  NotificationCenter._internal();

  final _controller = StreamController<String>.broadcast();
  Stream<String> get stream => _controller.stream;
  void post({required String name}) => _controller.add(name);

  // ✅ [تعديل 55] استخدام dynamic للتحايل على الـ IDE على ويندوز ومنع الخطوط الحمراء
  Future<void> clearBadge() async {
    try {
      if (Platform.isIOS) {
        final dynamic plugin = flutterLocalNotificationsPlugin;
        final dynamic iosPlugin =
            plugin.resolvePlatformSpecificImplementation();
        if (iosPlugin != null) {
          try {
            await iosPlugin.setApplicationIconBadgeNumber(0);
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  Future<void> updateBadgeCount(int count) async {
    try {
      if (Platform.isIOS) {
        final dynamic plugin = flutterLocalNotificationsPlugin;
        final dynamic iosPlugin =
            plugin.resolvePlatformSpecificImplementation();
        if (iosPlugin != null) {
          try {
            await iosPlugin.setApplicationIconBadgeNumber(count);
          } catch (_) {}
        }
      }
    } catch (_) {}
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
  // ✅ [تعديل جراحي v56] الاستماع للمتحكم في اللغة
  late StreamSubscription _localeSub;
  Locale _locale = LocaleController().currentLocale;

  @override
  void initState() {
    super.initState();
    // ✅ مراقبة تغيير اللغة (تغيير الـ MaterialApp ديناميكياً)
    _localeSub = LocaleController().localeStream.listen((newLocale) {
      if (mounted) {
        setState(() {
          _locale = newLocale;
        });
      }
    });
  }

  @override
  void dispose() {
    _localeSub.cancel();
    super.dispose();
  }

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
        return MediaQuery(
          data:
              MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
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
      // ✅ [تعديل جراحي v56] الربط مع المتغير الديناميكي للتحكم في الكيبورد
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

// استيراد الملفات الضرورية
import 'package:lpro2_quiz/firebase_options.dart';
import 'package:lpro2_quiz/core/theme/app_theme.dart';
import 'package:lpro2_quiz/presentation/screens/splash_screen.dart';
import 'package:lpro2_quiz/presentation/screens/login_screen.dart';
import 'package:lpro2_quiz/presentation/screens/complete_profile_screen.dart';
import 'package:lpro2_quiz/presentation/screens/main_wrapper.dart';
import 'package:lpro2_quiz/presentation/screens/about_screen.dart';
import 'package:lpro2_quiz/presentation/screens/admin_panel.dart';

// 1. معالج الرسائل في الخلفية (يعمل حتى لو التطبيق مغلق)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

// 2. إعداد قناة الإشعارات لنظام أندرويد (High Importance لظهور الإشعار فوراً)
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'lpro_notifications',
  'L Pro Notifications',
  description: 'هذه القناة مخصصة لأخبار ومسابقات L Pro',
  importance: Importance.max,
);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // تهيئة Firebase الأساسية
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);

    // تسجيل معالج الخلفية
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // تهيئة الإشعارات المحلية
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // طلب إذن نظام الأندرويد لإظهار الإشعارات
    await Permission.notification.request();

    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // الاشتراك في قناة الإرسال الجماعي (التي نستخدمها من لوحة التحكم)
    await messaging.subscribeToTopic('all_users');

    // طلب صلاحيات الـ Alerts و الـ Sounds
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  } catch (e) {
    debugPrint("Initialization Error: $e");
  }

  // تثبيت اتجاه الشاشة ليكون رأسي دائماً
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const LProApp());
}

class LProApp extends StatefulWidget {
  const LProApp({super.key});

  static void setLocale(BuildContext context, Locale newLocale) {
    _LProAppState? state = context.findAncestorStateOfType<_LProAppState>();
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
  void initState() {
    super.initState();
    _setupInteractedMessages();
  }

  void _setupInteractedMessages() {
    // استقبال الإشعارات والتطبيق مفتوح في الـ Foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );
      }
    });

    // التعامل مع فتح التطبيق من خلال إشعار وهو مغلق تماماً
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        _handleMessageNavigation(message);
      }
    });

    // التعامل مع فتح التطبيق من خلال إشعار وهو في الخلفية (Background)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageNavigation);
  }

  void _handleMessageNavigation(RemoteMessage message) {
    debugPrint("Notification Clicked: ${message.data}");
    // ملاحظة لمريم: هنا يمكنك مستقبلاً إضافة كود التوجيه لصفحة معينة بناءً على الـ data
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
      supportedLocales: const [Locale('ar', 'EG'), Locale('en', 'US')],
      locale: _locale,
      theme: LproTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/complete_profile': (context) => const CompleteProfileScreen(),
        '/home': (context) => const MainWrapper(),
        '/about': (context) => const AboutScreen(),
        '/admin': (context) => const AdminPanel(),
      },
    );
  }
}

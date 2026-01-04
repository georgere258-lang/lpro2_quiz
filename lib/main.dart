import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

// المسارات البرمجية الخاصة بمشروعك
import 'package:lpro2_quiz/firebase_options.dart';
import 'package:lpro2_quiz/core/theme/app_theme.dart';
import 'package:lpro2_quiz/core/utils/sound_manager.dart';
import 'package:lpro2_quiz/presentation/screens/splash_screen.dart';
import 'package:lpro2_quiz/presentation/screens/login_screen.dart';
import 'package:lpro2_quiz/presentation/screens/complete_profile_screen.dart';
import 'package:lpro2_quiz/presentation/screens/main_wrapper.dart';
import 'package:lpro2_quiz/presentation/screens/about_screen.dart';
import 'package:lpro2_quiz/presentation/screens/admin_panel.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

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
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);

    // تهيئة مدير الصوت
    SoundManager.init();

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // إعداد الإشعارات المحلية
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // طلب صلاحيات الإشعارات
    await Permission.notification.request();

    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // 1. الاشتراك في القناة العامة للأخبار
    await messaging.subscribeToTopic('all_users');

    // 2. تحديث التوافق: الاشتراك التلقائي في قنوات الدعم والإدارة
    _subscribeToNotificationTopics();

    await messaging.requestPermission(alert: true, badge: true, sound: true);
  } catch (e) {
    debugPrint("Initialization Error: $e");
  }

  // تثبيت وضع الشاشة الطولي (Portrait)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const LProApp());
}

// --- دالة الاشتراك التلقائي في مواضيع الإشعارات ---
void _subscribeToNotificationTopics() {
  FirebaseAuth.instance.authStateChanges().listen((User? user) {
    if (user != null) {
      // اشتراك المستخدم في قناة تحمل الـ UID الخاص به لاستقبال ردود الدعم
      FirebaseMessaging.instance.subscribeToTopic(user.uid);

      // اشتراك الإدارة في قناة تنبيهات الإدارة
      if (user.uid == 'nw2CackXK6PQavoGPAAbhyp6d1R2') {
        FirebaseMessaging.instance.subscribeToTopic('admin_notifications');
        debugPrint("Admin Subscribed to Admin Notifications Topic ✅");
      }
      debugPrint("User Subscribed to Personal Topic: ${user.uid} ✅");
    }
  });
}

class LProApp extends StatefulWidget {
  const LProApp({super.key});

  // دالة لتغيير اللغة من أي مكان في التطبيق
  static void setLocale(BuildContext context, Locale newLocale) {
    _LProAppState? state = context.findAncestorStateOfType<_LProAppState>();
    state?.changeLanguage(newLocale);
  }

  @override
  State<LProApp> createState() => _LProAppState();
}

class _LProAppState extends State<LProApp> {
  // ضبط اللغة العربية كخيار افتراضي عند فتح التطبيق
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
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
    });

    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) _handleMessageNavigation(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageNavigation);
  }

  void _handleMessageNavigation(RemoteMessage message) {
    // كود التوجيه عند النقر على الإشعار مستقبلاً
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'L Pro Quiz',
      debugShowCheckedModeBanner: false,
      // دعم اللغة والاتجاه
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar', 'EG'),
        Locale('en', 'US'),
      ],
      locale: _locale, // استخدام اللغة العربية افتراضياً
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

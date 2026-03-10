// PATH: lib/presentation/screens/main_wrapper.dart
// STATUS: Version 57 - Final Consolidated Notification Sync Logic (Hardened with Always-setState Fix)
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/app_config_service.dart';
import 'home_screen.dart';
import 'leaderboard_screen.dart';
import 'chat_support_screen.dart';
import 'profile_screen.dart';
import '../../features/news_ticker/presentation/news_ticker_widget.dart';
import '../widgets/lpro_bottom_nav_bar.dart';

// ✅ ربط مع NotificationCenter الموجود في main.dart
import '../../main.dart';

class MainWrapper extends StatefulWidget {
  final int? initialIndex;
  const MainWrapper({super.key, this.initialIndex});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

// ✅ إضافة WidgetsBindingObserver لمراقبة عودة التطبيق من الخلفية (Lifecycle Observer)
class _MainWrapperState extends State<MainWrapper> with WidgetsBindingObserver {
  int _currentIndex = 0;
  late final List<Widget> _pages;
  final User? _user = FirebaseAuth.instance.currentUser;

  List<dynamic> _notifications = [];
  bool _hasNewNotification = false;

  StreamSubscription? _refreshSub;

  // ✅ [جديد v56/57] مؤقت فحص الإشعارات لضمان المزامنة في iOS (Safety Net)
  Timer? _notificationPollTimer;

  @override
  void initState() {
    super.initState();
    // ✅ تسجيل المراقب عند بدء الشاشة
    WidgetsBinding.instance.addObserver(this);

    // ✅ تصفير الأيقونة الخارجية فور الدخول الأول
    NotificationCenter().clearBadge();

    if (widget.initialIndex != null) {
      _currentIndex = widget.initialIndex!.clamp(0, 3);
    }

    _pages = [
      const HomeScreen(),
      const LeaderboardScreen(),
      ProfileScreen(onSupportPressed: _handleSupportPressed),
      const ChatSupportScreen(),
    ];

    _loadNotifications();

    // ✅ الاستماع لإشارة تحديث الإشعارات من NotificationCenter
    _refreshSub = NotificationCenter().stream.listen((name) {
      if (name == "refresh_notifications" && mounted) {
        debugPrint('🔔 [MainWrapper] Refresh signal received. Loading...');
        _loadNotifications();
      }
    });

    // ✅ تشغيل صمام الأمان لنظام iOS
    if (Platform.isIOS) {
      _startNotificationPolling();
    }
  }

  @override
  void dispose() {
    // ✅ إزالة المراقب والمؤقت عند إغلاق الشاشة
    WidgetsBinding.instance.removeObserver(this);
    _refreshSub?.cancel();
    _stopNotificationPolling();
    super.dispose();
  }

  // ✅ وظيفة مؤقت المزامنة لـ iOS
  void _startNotificationPolling() {
    _notificationPollTimer?.cancel();
    _notificationPollTimer =
        Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        _checkNotificationFlagSilently();
      }
    });
  }

  void _stopNotificationPolling() {
    _notificationPollTimer?.cancel();
  }

  // فحص صامت للراية في الخلفية دون إعادة تحميل الواجهة إلا عند الضرورة
  Future<void> _checkNotificationFlagSilently() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final bool hasNew = prefs.getBool('has_new_notification_flag') ?? false;

      if (hasNew && !_hasNewNotification) {
        debugPrint('🕵️ [Polling] New notification detected via Flag!');
        await _loadNotifications();
      }
    } catch (_) {}
  }

  // ✅ تنفيذ وظيفة الـ Lifecycle Observer
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint("🔄 [Lifecycle] App Resumed: Checking persistent flag...");
      _checkNotificationFlagSilently();
      NotificationCenter().clearBadge();
    }
  }

  // ✅ [تعديل جراحي v57 - دمج حل كلود لضمان الـ setState دائماً]
  Future<void> _loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (Platform.isIOS) await prefs.reload();

      final String? notifsString = prefs.getString('saved_notifications');

      // ✅ قراءة الراية المستمرة
      final bool hasNewFlag =
          prefs.getBool('has_new_notification_flag') ?? false;

      // ✅ تحضير البيانات أولاً (سواء كانت القائمة فارغة أو ممتلئة)
      List<dynamic> loaded = [];
      if (notifsString != null && notifsString.isNotEmpty) {
        try {
          loaded = jsonDecode(notifsString);
        } catch (e) {
          debugPrint("⚠️ Error parsing notifications: $e");
          loaded = [];
        }
      }

      // ✅ حساب وجود إشعارات جديدة من داخل القائمة
      final bool hasNewInList = loaded.any((n) => n['isNew'] == true);

      // ✅ القرار النهائي لظهور النقطة (راية الـ Background أو حالة القائمة)
      final bool shouldShowBadge = hasNewFlag || hasNewInList;

      // ✅ [CRITICAL FIX v57] استدعاء setState دائماً لضمان تحديث الواجهة حتى لو القائمة فارغة
      if (mounted) {
        setState(() {
          _notifications = loaded;
          _hasNewNotification = shouldShowBadge;
        });

        debugPrint(
            '✅ [LOAD v57] Sync Complete. Count: ${loaded.length}, Badge: $shouldShowBadge (Flag: $hasNewFlag, List: $hasNewInList)');
      }
    } catch (e) {
      debugPrint("🔴 Error loading notifications: $e");
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // ✅ تصفير الـ Badge الخارجي فوراً
      await NotificationCenter().clearBadge();

      // ✅ تصفير الراية المستمرة لضمان اختفاء النقطة
      await prefs.setBool('has_new_notification_flag', false);

      bool changed = false;
      for (var n in _notifications) {
        if (n['isNew'] == true) {
          n['isNew'] = false;
          changed = true;
        }
      }

      if (changed) {
        await prefs.setString(
            'saved_notifications', jsonEncode(_notifications));
      }

      if (mounted) {
        setState(() {
          _hasNewNotification = false;
        });
      }
    } catch (e) {
      debugPrint("Error in _markAllAsRead: $e");
    }
  }

  String _getTimeAgo(int timestamp) {
    final now = DateTime.now();
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final diff = now.difference(date);
    if (diff.inDays > 0) return "منذ ${diff.inDays} يوم";
    if (diff.inHours > 0) return "منذ ${diff.inHours} ساعة";
    if (diff.inMinutes > 0) return "منذ ${diff.inMinutes} دقيقة";
    return "الآن";
  }

  void _handleSupportPressed() {
    if (AppConfigService().supportChatEnabled) {
      setState(() => _currentIndex = 3);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'الدعم غير متاح حالياً',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          backgroundColor: AppColors.primaryDeepTeal,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      resizeToAvoidBottomInset: false,
      appBar: _buildDynamicAppBar(),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.6, -0.5),
                  radius: 1.3,
                  colors: [
                    AppColors.primaryDeepTeal.withValues(alpha: 0.12),
                    AppColors.scaffoldBackground,
                  ],
                ),
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            switchInCurve: Curves.easeInOutCubic,
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.01),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: Container(
              key: ValueKey<int>(_currentIndex),
              child: IndexedStack(
                index: _currentIndex,
                children: _pages,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: LProBottomNavBar(
        activeIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }

  PreferredSizeWidget _buildDynamicAppBar() {
    if (_currentIndex == 0) return _buildHomeAppBar();
    if (_currentIndex == 1) return _buildCustomTitleAppBar("ترتيب L Pro");
    if (_currentIndex == 2) return _buildCustomTitleAppBar("ملفي الشخصي");
    return _buildCustomTitleAppBar("الدعم الفني");
  }

  PreferredSizeWidget _buildHomeAppBar() {
    return AppBar(
      backgroundColor: AppColors.primaryDeepTeal,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      toolbarHeight: 60,
      leading: IconButton(
        icon: Badge(
          isLabelVisible: _hasNewNotification,
          backgroundColor: AppColors.secondaryOrange,
          smallSize: 10,
          child: const Icon(Icons.notifications_none_rounded,
              color: Colors.white, size: 26),
        ),
        onPressed: () async {
          await _loadNotifications();
          _showNotificationSheet();
          await _markAllAsRead();
        },
      ),
      actions: const [SizedBox(width: 48)],
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.6),
            radius: 1.6,
            colors: [Color(0xFF136161), AppColors.primaryDeepTeal],
          ),
        ),
      ),
      title: Transform.translate(
        offset: const Offset(0, 8),
        child: Image.asset('assets/top_brand.png',
            height: 22, fit: BoxFit.contain),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(42),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
          child: _user == null
              ? const _TickerBox(userName: "Pro")
              : StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(_user!.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    String name = "Pro";
                    if (snapshot.hasData && snapshot.data!.exists) {
                      name = (snapshot.data!.data() as Map)['name'] ?? "Pro";
                    }
                    return _TickerBox(userName: name);
                  },
                ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildCustomTitleAppBar(String title) {
    return AppBar(
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.5),
            radius: 1.5,
            colors: [Color(0xFF136161), AppColors.primaryDeepTeal],
          ),
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.cairo(
            fontWeight: FontWeight.w900,
            color: Colors.white,
            fontSize: 18,
            shadows: [
              Shadow(
                offset: const Offset(0, 2),
                blurRadius: 4.0,
                color: Colors.black.withValues(alpha: 0.3),
              ),
            ]),
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
    );
  }

  void _showNotificationSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.55,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 15, bottom: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10)),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("الإشعارات",
                        style: GoogleFonts.cairo(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primaryDeepTeal)),
                    Icon(Icons.notifications_active_outlined,
                        color: AppColors.secondaryOrange, size: 22),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: _notifications.isEmpty
                    ? Center(
                        child: Text("لا توجد إشعارات حديثة",
                            style: GoogleFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade500)))
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: _notifications.length,
                        itemBuilder: (context, index) {
                          final notif = _notifications[index];
                          return _buildNotificationItem(
                            title: notif['title'] ?? 'إشعار جديد',
                            body: notif['body'] ?? '',
                            time: _getTimeAgo(notif['timestamp'] ??
                                DateTime.now().millisecondsSinceEpoch),
                            isNew: notif['isNew'] ?? false,
                            onTap: () {},
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationItem(
      {required String title,
      required String body,
      required String time,
      required bool isNew,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isNew
              ? AppColors.primaryDeepTeal.withValues(alpha: 0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isNew
                  ? AppColors.primaryDeepTeal.withValues(alpha: 0.2)
                  : Colors.grey.shade200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: AppColors.primaryDeepTeal.withValues(alpha: 0.1),
                  shape: BoxShape.circle),
              child: Icon(Icons.flash_on_rounded,
                  color: AppColors.secondaryOrange, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.cairo(
                          fontWeight: isNew ? FontWeight.w900 : FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.primaryDeepTeal)),
                  const SizedBox(height: 4),
                  Text(body,
                      style: GoogleFonts.cairo(
                          fontSize: 12, color: Colors.black87, height: 1.4)),
                  const SizedBox(height: 8),
                  Text(time,
                      style: GoogleFonts.cairo(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade500)),
                ],
              ),
            ),
            if (isNew)
              Container(
                  margin: const EdgeInsets.only(top: 5),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                      color: AppColors.secondaryOrange,
                      shape: BoxShape.circle)),
          ],
        ),
      ),
    );
  }
}

class _TickerBox extends StatelessWidget {
  final String userName;
  const _TickerBox({required this.userName});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      width: double.infinity,
      color: Colors.transparent,
      alignment: Alignment.center,
      child: NewsTickerWidget(userName: userName),
    );
  }
}

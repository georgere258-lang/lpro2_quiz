// PATH: lib/presentation/screens/main_wrapper.dart
import 'dart:convert';
import 'dart:io';
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

class MainWrapper extends StatefulWidget {
  final int? initialIndex;
  const MainWrapper({super.key, this.initialIndex});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;
  late final List<Widget> _pages;
  final User? _user = FirebaseAuth.instance.currentUser;

  List<dynamic> _notifications = [];
  bool _hasNewNotification = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialIndex != null) {
      _currentIndex = widget.initialIndex!.clamp(0, 2);
    }

    _pages = [
      const HomeScreen(),
      const LeaderboardScreen(),
      ProfileScreen(onSupportPressed: _handleSupportPressed),
      const ChatSupportScreen(),
    ];

    _loadNotifications();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 1000));
        await _loadNotifications();
        setState(() {
          _hasNewNotification = true;
        });
      }
    });
  }

  Future<void> _loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (Platform.isIOS) await prefs.reload();

      final String? notifsString = prefs.getString('saved_notifications');
      if (notifsString != null) {
        final List<dynamic> loaded = jsonDecode(notifsString);
        if (mounted) {
          setState(() {
            _notifications = loaded;
            _hasNewNotification = loaded.any((n) => n['isNew'] == true);
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading notifications: $e");
    }
  }

  // ✅ الدالة المعدلة بإضافة سجلات المراقبة (Logs) لضمان تصفير العداد في أبل
  Future<void> _markAllAsRead() async {
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('🔔 [NOTIFICATION] _markAllAsRead started...');

    try {
      final prefs = await SharedPreferences.getInstance();

      if (Platform.isIOS) {
        final FlutterLocalNotificationsPlugin notificationsPlugin =
            FlutterLocalNotificationsPlugin();

        final dynamic iosImplementation =
            notificationsPlugin.resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>();

        if (iosImplementation != null) {
          await iosImplementation.setApplicationIconBadgeNumber(0);
          debugPrint(
              '✅ [iOS BADGE] setApplicationIconBadgeNumber(0) executed successfully');
        } else {
          debugPrint('⚠️ [iOS BADGE] IOSImplementation is NULL');
        }
      }

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
        debugPrint(
            '✅ [LOCAL STORE] saved_notifications updated (marks as read)');
      }

      if (mounted) {
        setState(() {
          _hasNewNotification = false;
        });
      }
      debugPrint('🔔 [NOTIFICATION] _markAllAsRead completed.');
    } catch (e) {
      debugPrint("🔴 [ERROR] in _markAllAsRead: $e");
    }
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
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
            duration: const Duration(milliseconds: 550),
            switchInCurve: Curves.easeInOutCubic,
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.02),
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
    if (_currentIndex == 0) {
      return _buildHomeAppBar();
    } else if (_currentIndex == 1) {
      return _buildCustomTitleAppBar("ترتيب L Pro");
    } else {
      return _buildCustomTitleAppBar("ملفي الشخصي");
    }
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
          _markAllAsRead();
        },
      ),
      actions: const [
        SizedBox(width: 48),
      ],
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.6),
            radius: 1.6,
            colors: [
              Color(0xFF136161),
              AppColors.primaryDeepTeal,
            ],
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
            colors: [
              Color(0xFF136161),
              AppColors.primaryDeepTeal,
            ],
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
                    Text(
                      "الإشعارات",
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryDeepTeal,
                      ),
                    ),
                    Icon(Icons.notifications_active_outlined,
                        color: AppColors.secondaryOrange, size: 22),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: _notifications.isEmpty
                    ? Center(
                        child: Text(
                          "لا توجد إشعارات حديثة",
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      )
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

  Widget _buildNotificationItem({
    required String title,
    required String body,
    required String time,
    required bool isNew,
    required VoidCallback onTap,
  }) {
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
                : Colors.grey.shade200,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryDeepTeal.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.flash_on_rounded,
                  color: AppColors.secondaryOrange, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.cairo(
                      fontWeight: isNew ? FontWeight.w900 : FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.primaryDeepTeal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    time,
                    style: GoogleFonts.cairo(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                    ),
                  ),
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
                  shape: BoxShape.circle,
                ),
              ),
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

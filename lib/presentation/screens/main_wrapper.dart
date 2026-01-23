// PATH: lib/presentation/screens/main_wrapper.dart
// STATUS: ELITE PREMIUM WRAPPER (Dynamic Header & Spacing Precision)
// ✅ UPDATED: Premium Radial Gradient Header

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_colors.dart';
import 'home_screen.dart';
import 'leaderboard_screen.dart';
import 'profile_screen.dart';
import 'chat_support_screen.dart';
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

  @override
  void initState() {
    super.initState();
    if (widget.initialIndex != null) {
      _currentIndex = widget.initialIndex!.clamp(0, 2);
    }
    _pages = [
      const HomeScreen(),
      const LeaderboardScreen(),
      ProfileScreen(onSupportPressed: () => setState(() => _currentIndex = 3)),
      const ChatSupportScreen(),
    ];
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
      // ✅ التعديل: تدرج شعاعي بريميوم بدلاً من التدرج الخطي
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.6),
            radius: 1.6,
            colors: [
              Color(0xFF136161), // إضاءة خلف اللوجو
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
        preferredSize: const Size.fromHeight(48),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
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
      // ✅ التعديل: تدرج شعاعي لشاشات الترتيب والبروفايل
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
                color: Colors.black.withOpacity(0.3),
              ),
            ]),
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          color: AppColors.secondaryOrange,
          alignment: Alignment.center,
          child: NewsTickerWidget(userName: userName),
        ),
      ),
    );
  }
}
// PATH: lib/presentation/screens/main_wrapper.dart
// STATUS: Full File – Stable Navigation (Support via tab switch, KnowClient via push from Profile)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// استيراد الثوابت المركزية
import '../../core/constants/app_colors.dart';

// استيراد الشاشات الأساسية للتنقل
import 'home_screen.dart';
import 'leaderboard_screen.dart';
import 'profile_screen.dart';
import 'chat_support_screen.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;

  // القائمة تحتوي على الشاشات الأربعة فقط
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const HomeScreen(),
      const LeaderboardScreen(),

      // ✅ البروفايل فقط يقدر يفتح الدعم بتبديل التبويب
      ProfileScreen(
        onSupportPressed: () {
          setState(() => _currentIndex = 3);
        },
      ),

      const ChatSupportScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    Widget getAppBarTitle() {
      if (_currentIndex == 0) {
        return Image.asset(
          'assets/top_brand.png',
          height: 35,
          errorBuilder: (context, error, stackTrace) => Text(
            "L Pro",
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.w900,
              color: Colors.white,
              fontSize: 22,
            ),
          ),
        );
      }

      final List<String> titles = [
        "",
        "دوري المحترفين 🏆",
        "ملفي الشخصي",
        "الدعم الفني المباشر",
      ];

      final safeIndex = (_currentIndex >= 0 && _currentIndex < titles.length)
          ? _currentIndex
          : 2;

      return Text(
        titles[safeIndex],
        style: GoogleFonts.cairo(
          fontWeight: FontWeight.w900,
          color: Colors.white,
          fontSize: 18,
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDeepTeal,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: getAppBarTitle(),

        // زر الرجوع يرجع للرئيسية
        leading: _currentIndex != 0
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () => setState(() => _currentIndex = 0),
              )
            : null,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            )
          ],
        ),
        child: BottomNavigationBar(
          // ✅ لو في الدعم (3)، يفضل زر "حسابي" هو المضاء
          currentIndex: _currentIndex >= 3 ? 2 : _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          selectedItemColor: AppColors.secondaryOrange,
          unselectedItemColor: Colors.grey[500],
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedLabelStyle:
              GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 12),
          unselectedLabelStyle:
              GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 11),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_outlined),
              activeIcon: Icon(Icons.grid_view_rounded),
              label: "الرئيسية",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events_outlined),
              activeIcon: Icon(Icons.emoji_events),
              label: "دوري Pro",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: "حسابي",
            ),
          ],
        ),
      ),
    );
  }
}

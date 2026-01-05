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

  // القائمة تحتوي على الشاشات الأربعة، شاشة الدعم في الفهرس رقم 3
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const HomeScreen(),
      const LeaderboardScreen(),
      // نمرر وظيفة تغيير التبويب لصفحة البروفايل لكي تتمكن من فتح الدعم
      ProfileScreen(onSupportPressed: () {
        setState(() => _currentIndex = 3);
      }),
      const ChatSupportScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // دالة لتحديد عنوان الـ AppBar بناءً على الفهرس الحالي (عربي فقط)
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
              fontSize: 20,
            ),
          ),
        );
      }

      List<String> titles = [
        "",
        "دوري المتصدرين",
        "ملفي الشخصي",
        "الدعم الفني المباشر",
      ];

      return Text(
        titles[_currentIndex],
        style: GoogleFonts.cairo(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 17,
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
        // زر الرجوع يظهر في الشاشات الفرعية ليعيد المستخدم للرئيسية
        leading: _currentIndex != 0
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 18,
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
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, -4),
            )
          ],
        ),
        child: BottomNavigationBar(
          // إذا كنا في صفحة الدعم (3)، يظل زر الحساب (2) هو المضاء
          currentIndex: _currentIndex >= 3 ? 2 : _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          selectedItemColor: AppColors.secondaryOrange,
          unselectedItemColor: Colors.grey[400],
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedLabelStyle:
              GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 11),
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
              label: "الترتيب",
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

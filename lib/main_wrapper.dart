import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// استيراد الشاشات من مساراتها الصحيحة
import 'screens/home_screen.dart';
import 'screens/leaderboard_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/chat_support_screen.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    const Color deepTeal = Color(0xFF1B4D57);
    const Color safetyOrange = Color(0xFFE67E22);
    bool isAr = Localizations.localeOf(context).languageCode == 'ar';

    // قائمة الشاشات الأربعة الأساسية
    final List<Widget> pages = [
      const HomeScreen(),
      const LeaderboardScreen(),
      const ChatSupportScreen(), // الدعم الفني
      const ProfileScreen(),
    ];

    // دالة لجلب العنوان المناسب للـ AppBar بناءً على الصفحة الحالية
    Widget _getAppBarTitle() {
      if (_currentIndex == 0) {
        return Image.asset(
          'assets/top_brand.png',
          height: 35,
          errorBuilder: (context, error, stackTrace) => Text(
            "LPro Hero",
            style: GoogleFonts.cairo(
                fontWeight: FontWeight.w900, color: Colors.white),
          ),
        );
      }

      List<String> titles = [
        "",
        isAr ? "ترتيب الدوري العقاري" : "Real Estate League",
        isAr ? "الدعم الفني المباشر" : "Live Support",
        isAr ? "حسابي الشخصي" : "My Profile"
      ];

      return Text(
        titles[_currentIndex],
        style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: deepTeal,
        elevation: 0,
        centerTitle: true,
        // تمكين زر الرجوع التلقائي إذا كان هناك صفحات في الذاكرة
        automaticallyImplyLeading: true,
        title: _getAppBarTitle(),
        // إضافة زر رجوع يدوي للعودة للهوم إذا كنا في صفحة فرعية
        leading: _currentIndex != 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
                onPressed: () => setState(() => _currentIndex = 0),
              )
            : null,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
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
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          selectedItemColor: safetyOrange,
          unselectedItemColor: Colors.grey[400],
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedLabelStyle:
              GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 10),
          unselectedLabelStyle:
              GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 10),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.grid_view_outlined),
              activeIcon: const Icon(Icons.grid_view_rounded),
              label: isAr ? "الرئيسية" : "Home",
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.emoji_events_outlined),
              activeIcon: const Icon(Icons.emoji_events),
              label: isAr ? "الترتيب" : "Rank",
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.chat_bubble_outline),
              activeIcon: const Icon(Icons.chat_bubble),
              label: isAr ? "دعم" : "Support",
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              activeIcon: const Icon(Icons.person),
              label: isAr ? "حسابي" : "Profile",
            ),
          ],
        ),
      ),
    );
  }
}

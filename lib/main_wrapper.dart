import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// استيراد الشاشات - تأكدي من صحة المسارات في مشروعك
import 'screens/home_screen.dart';
import 'screens/leaderboard_screen.dart';
import 'screens/quiz_screen.dart';
import 'screens/profile_screen.dart';

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

    // فحص اللغة مباشرة بدون الاعتماد على كلاسات خارجية مؤقتاً لحل الخطأ
    bool isAr = Localizations.localeOf(context).languageCode == 'ar';

    // قائمة الشاشات
    final List<Widget> pages = [
      const HomeScreen(),
      LeaderboardScreen(),
      const QuizScreen(categoryTitle: "دوري النجوم"),
      ProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: deepTeal,
        elevation: 0,
        centerTitle: true,
        title: Image.asset(
          'assets/top_brand.png',
          height: 35,
          // في حال عدم وجود الصورة لا يظهر خطأ بل تظهر أيقونة
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.business_center, color: Colors.white),
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          selectedItemColor: deepTeal,
          unselectedItemColor: Colors.grey[400],
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedLabelStyle:
              GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 11),
          unselectedLabelStyle:
              GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 11),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.grid_view_outlined),
              activeIcon: const Icon(Icons.grid_view_rounded),
              label: isAr ? "الرئيسية" : "Home",
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.emoji_events_outlined),
              activeIcon: const Icon(Icons.emoji_events),
              label: isAr ? "الدوري" : "League",
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.rocket_launch_outlined),
              activeIcon: const Icon(Icons.rocket_launch),
              label: isAr ? "تحدي" : "Challenge",
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

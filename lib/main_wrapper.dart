import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart';
import 'screens/home_screen.dart';
// تأكدي أن هذا المسار صحيح لملف شاشة المتصدرين عندك
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

    // قائمة الشاشات - بدون const للملفات التي تجلب بيانات من الإنترنت
    final List<Widget> pages = [
      const HomeScreen(),
      LeaderboardScreen(), // تم التأكد من إزالة const هنا
      const QuizScreen(categoryTitle: "دوري النجوم"),
      ProfileScreen(), // وأيضاً هنا لبيانات البروفايل
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: deepTeal,
        elevation: 0,
        centerTitle: true,
        title: Image.asset(
          'assets/top_brand.png',
          height: 30,
          errorBuilder: (c, e, s) =>
              const Icon(Icons.business, color: Colors.white),
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: deepTeal,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle:
            GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: GoogleFonts.cairo(fontSize: 12),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: AppStrings.get(context, 'home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.emoji_events_outlined),
            activeIcon: const Icon(Icons.emoji_events),
            label: AppStrings.get(context, 'league'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.psychology_outlined),
            activeIcon: const Icon(Icons.psychology),
            label: isArabic(context) ? "تحدي" : "Challenge",
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            label: AppStrings.get(context, 'profile'),
          ),
        ],
      ),
    );
  }

  bool isArabic(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'ar';
}

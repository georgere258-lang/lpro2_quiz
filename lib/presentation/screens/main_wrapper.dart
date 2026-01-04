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

  // قائمة الشاشات - تم الحفاظ عليها كثوابت لتحسين الأداء
  final List<Widget> _pages = [
    const HomeScreen(),
    const LeaderboardScreen(),
    const ChatSupportScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // تحديد اللغة لضبط العناوين
    bool isAr = Localizations.localeOf(context).languageCode == 'ar';

    // وظيفة لتحديد عنوان الـ AppBar بناءً على القسم الحالي
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

      // مسميات العناوين المتوافقة مع الهوية الجديدة
      List<String> titles = [
        "",
        isAr ? "دوري المتصدرين" : "Leaderboard",
        isAr ? "الدعم الفني المباشر" : "Live Support",
        isAr ? "ملفي الشخصي" : "My Profile"
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
        automaticallyImplyLeading: false, // منع سهم الرجوع التلقائي عند الدخول
        title: getAppBarTitle(),
        // إظهار زر العودة للرئيسية في التبويبات الأخرى
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

      // IndexedStack يحافظ على حالة الشاشات (State) أثناء التنقل لمنع إعادة التحميل
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
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          selectedItemColor: AppColors.secondaryOrange,
          unselectedItemColor: Colors.grey[400],
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedLabelStyle: GoogleFonts.cairo(
            fontWeight: FontWeight.w900,
            fontSize: 11,
          ),
          unselectedLabelStyle: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
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

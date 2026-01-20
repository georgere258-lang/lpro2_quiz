// PATH: lib/presentation/screens/main_wrapper.dart
// STATUS: Single REAL header only (AppBar) + ticker INSIDE AppBar (fixed, no scroll cut)

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

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

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
    _pages = [
      const HomeScreen(),
      const LeaderboardScreen(),
      ProfileScreen(
        onSupportPressed: () => setState(() => _currentIndex = 3),
      ),
      const ChatSupportScreen(),
    ];
  }

  PreferredSizeWidget _buildHomeAppBar() {
    // ✅ AppBar واحد فقط: لوجو + شريط الأخبار ثابت
    return AppBar(
      backgroundColor: AppColors.primaryDeepTeal,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,

      // ✅ مهم: علشان نزول اللوجو ما يتقصّش
      toolbarHeight: 62,

      title: Transform.translate(
        offset: const Offset(0, 10), // نزّل اللوجو قريب من الشريط
        child: Image.asset(
          'assets/top_brand.png',
          height: 24,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Text(
            "L Pro",
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.w900,
              color: Colors.white,
              fontSize: 22,
            ),
          ),
        ),
      ),

      // ✅ الشريط جوّه الهيدر الحقيقي (ثابت ومش بيتقطع)
      bottom: PreferredSize(
        // ✅ لازم يطابق الحجم الحقيقي (Padding + Height)
        preferredSize: const Size.fromHeight(52),
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
                      final data =
                          snapshot.data!.data() as Map<String, dynamic>? ?? {};
                      name = (data['name'] ?? "Pro").toString();
                    }
                    return _TickerBox(userName: name);
                  },
                ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildDefaultAppBar() {
    Widget titleWidget() {
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

    return AppBar(
      backgroundColor: AppColors.primaryDeepTeal,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      title: titleWidget(),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: _currentIndex == 0 ? _buildHomeAppBar() : _buildDefaultAppBar(),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            )
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex >= 3 ? 2 : _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          selectedItemColor: AppColors.secondaryOrange,
          unselectedItemColor: Colors.grey[500],
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedLabelStyle: GoogleFonts.cairo(
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
          unselectedLabelStyle: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
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

class _TickerBox extends StatelessWidget {
  final String userName;
  const _TickerBox({required this.userName});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.secondaryOrange,
          boxShadow: [
            BoxShadow(
              color: AppColors.secondaryOrange.withValues(alpha: 0.22),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: NewsTickerWidget(userName: userName),
      ),
    );
  }
}

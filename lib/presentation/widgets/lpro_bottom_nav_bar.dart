import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

class LProBottomNavBar extends StatelessWidget {
  final int activeIndex;
  final ValueChanged<int> onTap;

  const LProBottomNavBar({
    super.key,
    required this.activeIndex,
    required this.onTap,
  });

  int _safeIndex(int i) {
    if (i < 0) return 0;
    if (i > 2) return 2; // maps 3 (support) -> 2 (profile tab)
    return i;
  }

  @override
  Widget build(BuildContext context) {
    final int safeActive = _safeIndex(activeIndex);

    // ✅ iOS fix:
    // - BottomNavigationBar adds SafeArea bottom padding internally (on iPhone).
    // - With our floating margin, this makes the bar look too tall and icons shift upward.
    // Solution:
    // 1) Remove bottom padding from the bar itself.
    // 2) Move the whole bar up by increasing ONLY the outer bottom margin with iOS inset.
    final double bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      // ✅ Keep the same floating look, but account for iPhone safe area without inflating bar height.
      margin: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottomInset),
      decoration: BoxDecoration(
        color: AppColors.primaryDeepTeal,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 25,
            spreadRadius: -5,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: MediaQuery.removePadding(
          context: context,
          removeBottom:
              true, // ✅ prevents iOS safe-area padding from expanding the bar
          child: BottomNavigationBar(
            currentIndex: safeActive,
            onTap: (i) {
              if (i == safeActive) return;
              onTap(i);
            },
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: AppColors.secondaryOrange,
            unselectedItemColor: Colors.white.withValues(alpha: 0.5),
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            selectedLabelStyle:
                GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 12),
            unselectedLabelStyle:
                GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 11),
            items: const [
              BottomNavigationBarItem(
                  icon: Icon(Icons.grid_view_rounded), label: "الرئيسية"),
              BottomNavigationBarItem(
                  icon: Icon(Icons.emoji_events), label: "دوري Pro"),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: "حسابي"),
            ],
          ),
        ),
      ),
    );
  }
}

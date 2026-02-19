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

    return Container(
      // إضافة هوامش لجعل الشريط عائماً (Floating)
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.primaryDeepTeal,
        // زوايا دائرية بالكامل للشكل العائم
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
        // ضمان قص محتوى الـ BottomNavigationBar ليناسب الزوايا الدائرية
        borderRadius: BorderRadius.circular(35),
        child: BottomNavigationBar(
          currentIndex: safeActive,
          onTap: (i) {
            // Guard: prevent re-triggering navigation when tapping the same tab
            if (i == safeActive) return;
            onTap(i);
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppColors.secondaryOrange,
          unselectedItemColor: Colors.white.withValues(alpha: 0.5),
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          // استخدام أحجام خطوط متزنة لضمان الاستقرار مع التكبير
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
    );
  }
}

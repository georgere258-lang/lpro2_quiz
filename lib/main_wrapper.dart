import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';
import 'screens/leaderboard_screen.dart';
import 'screens/quiz_screen.dart';
import 'screens/profile_screen.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});
  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _ctrl;
  late Animation<Offset> _anim;

  final List<String> _newsItems = [
    "🔥 مريم جرجس وحش العقارات تتألق اليوم.. التميز قرارك! 🔥",
    "💡 نصيحة عقارية: العميل لا يشتري عقاراً، بل يشتري مستقبلاً وآماناً.",
    "🚀 خبر: ارتفاع الطلب على الوحدات الإدارية في العاصمة الإدارية بنسبة 15%.",
    "📊 قول بيزنس: النجاح ليس نهائياً، بل الشجاعة هي التي تستمر.",
    "🏠 المعلومة بتفرق: التجمع الخامس يظل الوجهة الأولى للاستثمار.",
    "🌟 وحوش LPro: تذكر أن كل 'لا' تقربك خطوة من الـ 'نعم' القادمة.",
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: const Duration(seconds: 40), vsync: this)..repeat();
    // ضبط الـ Offset ليكون متناسباً مع طول النص
    _anim = Tween<Offset>(begin: const Offset(1.5, 0), end: const Offset(-3.5, 0)).animate(_ctrl);
  }

  @override
  void dispose() { 
    _ctrl.dispose(); 
    super.dispose(); 
  }

  @override
  Widget build(BuildContext context) {
    const Color deepTeal = Color(0xFF1B4D57);
    const Color safetyOrange = Color(0xFFE67E22);
    
    String fullTickerText = _newsItems.join("      |      ");

    // [قائمة الشاشات الحقيقية التي اعتمدناها]
    final List<Widget> _pages = [
      const HomeScreen(),
      const LeaderboardScreen(),
      const QuizScreen(categoryTitle: "تحدي اليوم", isTextQuiz: false),
      const ProfileScreen(),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: deepTeal,
          elevation: 0,
          centerTitle: true,
          // استخدام اللوجو من الـ Assets
          title: Image.asset('assets/top_brand.png', height: 40, 
            errorBuilder: (c,e,s) => const Icon(Icons.business, color: Colors.white)),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(40),
            child: Container(
              height: 40, 
              width: double.infinity, 
              color: safetyOrange.withOpacity(0.9), // جعل شريط الأخبار برتقالي ليتماشى مع الهوية
              child: ClipRect(
                child: SlideTransition(
                  position: _anim,
                  child: Center(
                    child: Text(
                      fullTickerText,
                      style: GoogleFonts.cairo(
                        color: Colors.white, 
                        fontSize: 13, 
                        fontWeight: FontWeight.bold,
                      ),
                      softWrap: false,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // عرض الصفحات الحقيقية
        body: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          selectedItemColor: deepTeal,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: GoogleFonts.cairo(fontSize: 12),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: "الرئيسية"),
            BottomNavigationBarItem(icon: Icon(Icons.emoji_events_outlined), activeIcon: Icon(Icons.emoji_events), label: "الدوري"),
            BottomNavigationBarItem(icon: Icon(Icons.psychology_outlined), activeIcon: Icon(Icons.psychology), label: "تحدي"),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: "حسابي"),
          ],
        ),
      ),
    );
  }
}
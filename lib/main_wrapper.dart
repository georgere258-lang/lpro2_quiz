import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});
  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _ctrl;
  late Animation<Offset> _anim;

  // [قائمة المحتوى المتنوع]: أخبار، نصائح، بيزنس، وتشجيع
  final List<String> _newsItems = [
    "🔥 مريم جرجس وحش العقارات تتألق اليوم.. التميز قرارك! 🔥",
    "💡 نصيحة عقارية: العميل لا يشتري عقاراً، بل يشتري مستقبلاً وآماناً.",
    "🚀 خبر: ارتفاع الطلب على الوحدات الإدارية في العاصمة الإدارية بنسبة 15%.",
    "📊 قول بيزنس: 'النجاح ليس نهائياً، والفشل ليس قاتلاً، إنما الشجاعة هي التي تستمر'.",
    "🏠 المعلومة بتفرق: التجمع الخامس يظل الوجهة الأولى للاستثمار طويل الأمد.",
    "🌟 وحوش LPro: تذكر أن كل 'لا' تسمعها تقربك خطوة من الـ 'نعم' القادمة.",
  ];

  @override
  void initState() {
    super.initState();
    // زيادة المدة لـ 40 ثانية لأن النص أصبح طويلاً جداً لنسمح بالقراءة بتمهل
    _ctrl = AnimationController(duration: const Duration(seconds: 40), vsync: this)..repeat();
    _anim = Tween<Offset>(begin: const Offset(1.2, 0), end: const Offset(-2.5, 0)).animate(_ctrl);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    const Color deepTeal = Color(0xFF1B4D57);
    
    // دمج القائمة في نص واحد طويل بفاصل مميز
    String fullTickerText = _newsItems.join("      |      ");

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: deepTeal,
          elevation: 0,
          centerTitle: true,
          title: Image.asset('assets/top_brand.png', height: 40, colorBlendMode: BlendMode.dstATop, color: deepTeal),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(40),
            child: Container(
              height: 40, 
              width: double.infinity, 
              color: Colors.white.withOpacity(0.1), // خلفية خفيفة جداً لتمييز الشريط
              child: ClipRect(
                child: SlideTransition(
                  position: _anim,
                  child: Center(
                    child: Text(
                      fullTickerText,
                      style: GoogleFonts.cairo(
                        color: Colors.white, 
                        fontSize: 13, 
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                      softWrap: false,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: const [HomeScreen(), Center(child: Text("الدوري")), Center(child: Text("تحدي")), Center(child: Text("حسابي"))],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          selectedItemColor: deepTeal,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "الرئيسية"),
            BottomNavigationBarItem(icon: Icon(Icons.leaderboard), label: "الدوري"),
            BottomNavigationBarItem(icon: Icon(Icons.psychology), label: "تحدي"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "حسابي"),
          ],
        ),
      ),
    );
  }
}
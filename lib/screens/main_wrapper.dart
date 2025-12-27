import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

// [الاستيرادات الأساسية لربط المنظومة]
import 'profile_screen.dart';
import 'real_estate_league.dart';
import 'quiz_screen.dart';

/**
 * [MainWrapper] - الإصدار الملكي الأضخم (Premium Colored Version)
 * تم تصميم هذا الملف ليتجاوز 480 سطر لضمان التفصيل البرمجي والبصري الكامل.
 * تم استخدام التدرجات اللونية (Gradients) لكسر بياض الشاشة وزيادة الفخامة.
 */

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> with SingleTickerProviderStateMixin {
  
  // =============================================================
  // [1] قسم إدارة الحالة والبيانات (Deep State Management)
  // =============================================================
  
  int _currentIndex = 0; 
  String userName = "مريم جرجس"; 
  int userPoints = 2450; 
  int userLevel = 18;
  String userRank = "وحش العقارات 🦁";
  bool isArabic = true; 

  // الميثاق اللوني المطور (The Premium Palette)
  static const Color brandOrange = Color(0xFFC67C32); // الذهبي الملكي
  static const Color navyDeep = Color(0xFF1E2B3E);    // الكحلي الملكي
  static const Color navyLight = Color(0xFF2C3E50);   // الكحلي المساعد
  static const Color iceGray = Color(0xFFF2F4F7);     // الرمادي الثلجي
  static const Color pureWhite = Color(0xFFFFFFFF);    // الأبيض الناصع
  static const Color premiumGold = Color(0xFFD4AF37);  // ذهبي لامع
  static const Color softCream = Color(0xFFFDFBF7);    // كريمي هادئ (بديل للأبيض)

  // عناصر التحكم في المؤقتات (Logic Engines)
  late ScrollController _newsScrollController;
  Timer? _newsTimer;
  Timer? _motivationTimer; 
  Timer? _rewardTimer;     

  final List<String> _encouragingAlerts = [
    "عاش يا وحش.. كمل متابعة شغلك! 🚀",
    "مجهودك النهاردة هيعمل فرق كبير.. استمري! ✨",
    "إنتي ماشية صح.. طريقك للقمة يبدأ من هنا! 🏆",
    "تركيزك عالي جداً.. الله ينور عليكِ! 🔥",
    "الاستمرارية هي سر النجاح في العقارات.. كملي! 💪",
  ];

  // =============================================================
  // [2] دورة حياة التطبيق والمحركات الذكية (Lifecycle & Logic)
  // =============================================================

  @override
  void initState() {
    super.initState();
    _newsScrollController = ScrollController();
    
    // بدء المحركات بعد اكتمال رسم الواجهة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startMarqueeLogic();      
      _initMotivationEngine();   
      _initRewardEngine();       
    });
    
    _refreshRankLabel(); 
  }

  void _initMotivationEngine() {
    _motivationTimer = Timer.periodic(const Duration(minutes: 10), (timer) {
      _triggerVisualMotivation();
    });
  }

  void _initRewardEngine() {
    _rewardTimer = Timer.periodic(const Duration(minutes: 30), (timer) {
      _applyPassiveRewardBonus();
    });
  }

  void _triggerVisualMotivation() {
    if (!mounted) return;
    final msg = _encouragingAlerts[(DateTime.now().second % _encouragingAlerts.length)];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: pureWhite)),
        backgroundColor: navyDeep,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  void _applyPassiveRewardBonus() {
    if (!mounted) return;
    setState(() => userPoints += 10);
    _showRewardNotification();
  }

  void _showRewardNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.stars_rounded, color: brandOrange),
            const SizedBox(width: 12),
            Text(isArabic ? "مبروك! إضافة 10 نقاط لرصيدك ✨" : "+10 Pts Bonus! ✨", 
                 style: GoogleFonts.cairo(fontWeight: FontWeight.w900, color: navyDeep)),
          ],
        ),
        backgroundColor: pureWhite,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: brandOrange, width: 2)),
      ),
    );
  }

  void _startMarqueeLogic() {
    _newsTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (_newsScrollController.hasClients) {
        if (_newsScrollController.offset >= _newsScrollController.position.maxScrollExtent) {
          _newsScrollController.jumpTo(0);
        } else {
          _newsScrollController.animateTo(_newsScrollController.offset + 2.0, duration: const Duration(milliseconds: 30), curve: Curves.linear);
        }
      }
    });
  }

  void _refreshRankLabel() {
    setState(() {
      if (userPoints > 1000) userRank = isArabic ? "حوت التجمع 🐳" : "RE Whale 🐳";
      else userRank = isArabic ? "برو جونيور 🐣" : "Pro Junior 🐣";
    });
  }

  @override
  void dispose() { 
    _newsTimer?.cancel(); 
    _motivationTimer?.cancel();
    _rewardTimer?.cancel();
    _newsScrollController.dispose(); 
    super.dispose(); 
  }

  // =============================================================
  // [3] بناء واجهة المستخدم (Master UI Build)
  // =============================================================

  @override
  Widget build(BuildContext context) {
    final List<Widget> _mainPages = [
      _buildHomeScreenScrollableBody(), 
      _buildInternalPlaceholder(isArabic ? "استكشف العقارات" : "Explore"), 
      _buildInternalPlaceholder(isArabic ? "الإشعارات" : "Alerts"), 
      const ProfileScreen(), 
    ];

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: iceGray,
        bottomNavigationBar: _buildDetailedBottomNav(),
        body: IndexedStack(index: _currentIndex, children: _mainPages),
      ),
    );
  }

  Widget _buildHomeScreenScrollableBody() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildRoyalAppBarHeader(), 
        SliverPadding(
          padding: const EdgeInsets.only(top: 15, bottom: 40),
          sliver: SliverToBoxAdapter(
            child: Column(
              children: [
                _buildPremiumUserCard(),     // كارت المستخدم المطور
                _buildVisibleMotivationText(),  
                _buildQuickActionSuggestion(),   
                _buildNewsTickerMarquee(),      
                
                const SizedBox(height: 30),
                _buildSectionLabel(isArabic ? "بوابات التعلم" : "Learning Gates"),
                _buildGatewaysGrid(),            
                
                const SizedBox(height: 35),
                _buildSectionLabel(isArabic ? "الأدوات والمنافسات" : "Pro Services"),
                _buildDetailedActionList(),       
                
                const SizedBox(height: 100), 
              ],
            ),
          ),
        ),
      ],
    );
  }

  // =============================================================
  // [4] تفصيل الأجزاء البصرية (The Atomic UI Components)
  // =============================================================

  Widget _buildRoyalAppBarHeader() {
    return SliverAppBar(
      expandedHeight: 110,
      floating: true, pinned: true, elevation: 10,
      backgroundColor: navyDeep,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [navyDeep, navyLight],
            ),
          ),
        ),
      ),
      title: SvgPicture.asset('assets/logo.svg', height: 35),
      centerTitle: true,
      actions: [
        IconButton(icon: const Icon(Icons.language, color: pureWhite, size: 26), onPressed: () => setState(() => isArabic = !isArabic)),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildPremiumUserCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [softCream, pureWhite], // كسر بياض الكارت بلون كريمي
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: brandOrange.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(color: navyDeep.withOpacity(0.08), blurRadius: 25, offset: const Offset(0, 10))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isArabic ? "أهلاً بكِ" : "Welcome", 
                   style: GoogleFonts.cairo(color: brandOrange, fontSize: 13, fontWeight: FontWeight.bold)),
              Text(userName, 
                   style: GoogleFonts.cairo(color: navyDeep, fontSize: 28, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              _buildRankBadge(),
            ],
          ),
          _buildPointsInfoWidget(),
        ],
      ),
    );
  }

  Widget _buildRankBadge() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    decoration: BoxDecoration(color: navyDeep, borderRadius: BorderRadius.circular(12)),
    child: Text(userRank, style: GoogleFonts.cairo(color: pureWhite, fontSize: 11, fontWeight: FontWeight.bold)),
  );

  Widget _buildPointsInfoWidget() => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: brandOrange.withOpacity(0.1), shape: BoxShape.circle),
    child: Column(
      children: [
        const Icon(Icons.stars_rounded, color: brandOrange, size: 40),
        Text("$userPoints", style: GoogleFonts.poppins(color: navyDeep, fontWeight: FontWeight.bold, fontSize: 18)),
      ],
    ),
  );

  Widget _buildVisibleMotivationText() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 25),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_awesome, color: brandOrange, size: 22),
          const SizedBox(width: 12),
          Text(
            isArabic ? "النهاردة يوم جديد.. استعدي لإنجاز كبير! ✨" : "Ready for a big win! ✨",
            style: GoogleFonts.cairo(color: brandOrange, fontWeight: FontWeight.w900, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedActionList() {
    return Column(
      children: [
        _buildActionItem(
          title: isArabic ? "الدوري العقاري" : "RE League", 
          icon: Icons.emoji_events_outlined, 
          hasBadge: true,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const RealEstateLeague())),
        ),
        _buildActionItem(
          title: isArabic ? "نشط ذهنك" : "Quiz Zone", 
          icon: Icons.psychology_outlined, 
          hasBadge: false,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const QuizScreen())),
        ),
        _buildActionItem(title: isArabic ? "مكتبة المحتوى" : "Library", icon: Icons.library_books_outlined, hasBadge: false),
        _buildActionItem(title: isArabic ? "حاسبة التمويل" : "Calc", icon: Icons.calculate_outlined, hasBadge: false),
        _buildActionItem(title: isArabic ? "خريطة المشاريع" : "Map", icon: Icons.map_outlined, hasBadge: false),
      ],
    );
  }

  Widget _buildActionItem({required String title, required IconData icon, required bool hasBadge, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: pureWhite,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: navyDeep.withOpacity(0.05)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: brandOrange.withOpacity(0.08), shape: BoxShape.circle),
              child: Icon(icon, color: brandOrange, size: 26),
            ),
            const SizedBox(width: 20),
            Expanded(child: Text(title, style: GoogleFonts.cairo(color: navyDeep, fontWeight: FontWeight.bold, fontSize: 17))),
            if (hasBadge) const CircleAvatar(radius: 4, backgroundColor: brandOrange),
            const SizedBox(width: 10),
            const Icon(Icons.arrow_forward_ios_rounded, color: navyDeep, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsTickerMarquee() {
    return Container(
      margin: const EdgeInsets.only(top: 25),
      height: 52,
      color: navyDeep, // كسر البياض بشريط كحلي ملكي
      child: ListView.builder(
        controller: _newsScrollController,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 35),
            alignment: Alignment.center,
            child: Row(
              children: [
                const Icon(Icons.bolt_rounded, color: premiumGold, size: 20),
                const SizedBox(width: 12),
                Text(
                  isArabic ? "عاجل: تحديثات السوق العقاري في العاصمة الآن" : "🔥 Market Update", 
                  style: GoogleFonts.cairo(color: pureWhite, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGatewaysGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildGatewayItem(isArabic ? "فريش" : "FRESH", "https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?w=600"),
          const SizedBox(width: 15),
          _buildGatewayItem(isArabic ? "محترف" : "PRO", "https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=400"),
        ],
      ),
    );
  }

  Widget _buildGatewayItem(String title, String url) {
    return Expanded(
      child: Container(
        height: 230,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Stack(fit: StackFit.expand, children: [
            Image.network(url, fit: BoxFit.cover),
            Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [navyDeep.withOpacity(0.8), Colors.transparent]))),
            Center(child: Text(title, style: GoogleFonts.cairo(color: pureWhite, fontSize: 26, fontWeight: FontWeight.w900))),
          ]),
        ),
      ),
    );
  }

  Widget _buildQuickActionSuggestion() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: softCream,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: brandOrange.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.tips_and_updates, color: brandOrange, size: 38),
          const SizedBox(width: 18),
          Expanded(
            child: Text(
              isArabic ? "رأيك إيه نراجع مشروع في التجمع النهاردة؟ 🚀" : "Review New Cairo! 🚀", 
              style: GoogleFonts.cairo(color: navyDeep, fontSize: 14, fontWeight: FontWeight.w700, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
      child: Align(
        alignment: isArabic ? Alignment.centerRight : Alignment.centerLeft,
        child: Text(label, style: GoogleFonts.cairo(color: navyDeep, fontSize: 19, fontWeight: FontWeight.w900)),
      ),
    );
  }

  Widget _buildDetailedBottomNav() {
    return Container(
      decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)]),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: brandOrange,
        unselectedItemColor: navyDeep.withOpacity(0.35),
        backgroundColor: pureWhite,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: "الرئيسية"),
          BottomNavigationBarItem(icon: Icon(Icons.explore_rounded), label: "استكشف"),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_active_rounded), label: "تنبيهات"),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: "بروفايل"),
        ],
      ),
    );
  }

  Widget _buildInternalPlaceholder(String t) => Center(child: Text(t, style: GoogleFonts.cairo(fontSize: 20, color: navyDeep)));
}
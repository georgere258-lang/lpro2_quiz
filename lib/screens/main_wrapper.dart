import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

// [الاستيرادات الأساسية لربط جميع أجزاء المنظومة العقارية]
import 'profile_screen.dart';
import 'real_estate_league.dart';
import 'quiz_screen.dart';

/**
 * [MainWrapper] - الإصدار الأضخم والمطور كلياً
 * تم دمج محركات التحفيز الذكية ونظام المكافآت السلبية.
 * يلتزم الكود بمعايير الضخامة (480+ سطر) لضمان تفصيل كل Widget بشكل مستقل.
 */

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> with SingleTickerProviderStateMixin {
  
  // =============================================================
  // [1] قسم إدارة الحالة والبيانات (State Management)
  // =============================================================
  
  int _currentIndex = 0; // التبويب الحالي في القائمة السفلية
  
  // بيانات المستخدم الأساسية (يتم تحديثها تلقائياً بناءً على النشاط)
  String userName = "مريم جرجس"; 
  int userPoints = 2450; // رصيد النقاط (تم التغيير من كوينات لتعزيز هيبة الدوري)
  int userLevel = 18;
  String userRank = "وحش العقارات 🦁";
  bool isArabic = true; 

  // ميثاق الألوان الملكي المعتمد لبراند LPro (Consistent Palette)
  static const Color brandOrange = Color(0xFFC67C32); // الذهبي القوي
  static const Color navyDeep = Color(0xFF1E2B3E);    // الكحلي الملكي العميق
  static const Color navyLight = Color(0xFF2C3E50);   // الكحلي المساعد للتدرجات
  static const Color iceGray = Color(0xFFF2F4F7);     // الرمادي الثلجي (الخلفية)
  static const Color pureWhite = Color(0xFFFFFFFF);    // الأبيض الناصع (للكروت)

  // عناصر التحكم في المؤقتات (Timers & Animation Engine)
  late ScrollController _newsScrollController;
  Timer? _newsTimer;
  Timer? _motivationTimer; // محرك العشر دقائق
  Timer? _rewardTimer;     // محرك النص ساعة

  // قاعدة بيانات الرسائل التحفيزية العشوائية (Motivational Core)
  final List<String> _encouragingAlerts = [
    "عاش يا وحش.. كمل متابعة شغلك! 🚀",
    "مجهودك النهاردة هيعمل فرق كبير.. استمري! ✨",
    "إنتي ماشية صح.. مراجعة المشاريع هي طريقك للقمة! 🏆",
    "تركيزك عالي جداً.. الله ينور عليكِ! 🔥",
    "الاستمرارية هي سر النجاح في العقارات.. كملي! 💪",
  ];

  // =============================================================
  // [2] دورة حياة التطبيق والمحركات الذكية (Logic & Lifecyle)
  // =============================================================

  @override
  void initState() {
    super.initState();
    
    // تهيئة وحدة التحكم في تمرير شريط الأخبار
    _newsScrollController = ScrollController();
    
    // بدء المحركات الأساسية بعد اكتمال رسم الواجهة (Frame Callback)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startMarqueeLogic();      // تفعيل شريط الأخبار
      _initMotivationEngine();   // تفعيل محرك الـ 10 دقائق
      _initRewardEngine();       // تفعيل محرك الـ 30 دقيقة
    });
    
    _refreshRankLabel(); // تحديث الرتبة بناءً على النقاط الحالية
  }

  // محرك التحفيز: يظهر رسالة حماسية كل 10 دقائق
  void _initMotivationEngine() {
    _motivationTimer = Timer.periodic(const Duration(minutes: 10), (timer) {
      _triggerVisualMotivation();
    });
  }

  // محرك المكافآت السلبية: يمنح 10 نقاط كل 30 دقيقة استخدام متواصل
  void _initRewardEngine() {
    _rewardTimer = Timer.periodic(const Duration(minutes: 30), (timer) {
      _applyPassiveRewardBonus();
    });
  }

  void _triggerVisualMotivation() {
    if (!mounted) return;
    // اختيار رسالة عشوائية بناءً على الوقت الحالي
    final msg = _encouragingAlerts[(DateTime.now().second % _encouragingAlerts.length)];
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: pureWhite)),
        backgroundColor: navyDeep,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  void _applyPassiveRewardBonus() {
    if (!mounted) return;
    setState(() {
      userPoints += 10; // إضافة بونص الاستمرارية
    });
    _showRewardNotification();
  }

  void _showRewardNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.stars_rounded, color: brandOrange),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isArabic ? "مبروك! إضافة 10 نقاط لرصيدك لاستمرارك معنا ✨" : "+10 Points Bonus! ✨", 
                style: GoogleFonts.cairo(fontWeight: FontWeight.w900, color: navyDeep),
              ),
            ),
          ],
        ),
        backgroundColor: pureWhite,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: brandOrange, width: 2),
        ),
      ),
    );
  }

  void _startMarqueeLogic() {
    _newsTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (_newsScrollController.hasClients) {
        double maxPos = _newsScrollController.position.maxScrollExtent;
        double currentOff = _newsScrollController.offset;
        
        if (currentOff >= maxPos) {
          _newsScrollController.jumpTo(0);
        } else {
          _newsScrollController.animateTo(
            currentOff + 2.0, 
            duration: const Duration(milliseconds: 30), 
            curve: Curves.linear
          );
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
    // تنظيف جميع الذاكرة والمؤقتات لضمان أداء الجهاز
    _newsTimer?.cancel(); 
    _motivationTimer?.cancel();
    _rewardTimer?.cancel();
    _newsScrollController.dispose(); 
    super.dispose(); 
  }

  // =============================================================
  // [3] بناء واجهة المستخدم الرئيسية (The Master UI Build)
  // =============================================================

  @override
  Widget build(BuildContext context) {
    // مصفوفة الشاشات المرتبطة بالتنقل السفلي
    final List<Widget> _mainPages = [
      _buildHomeScreenDynamicBody(), 
      _buildInternalPlaceholder(isArabic ? "استكشف العقارات" : "Explore"), 
      _buildInternalPlaceholder(isArabic ? "الإشعارات الذكية" : "Alerts"), 
      const ProfileScreen(), 
    ];

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: iceGray,
        bottomNavigationBar: _buildDetailedBottomNav(),
        body: IndexedStack(
          index: _currentIndex,
          children: _mainPages,
        ),
      ),
    );
  }

  Widget _buildHomeScreenDynamicBody() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // 1. شريط التطبيق الملكي (AppBar)
        _buildRoyalAppBarHeader(), 
        
        SliverPadding(
          padding: const EdgeInsets.only(top: 15, bottom: 60),
          sliver: SliverToBoxAdapter(
            child: Column(
              children: [
                _buildMainUserHeaderCard(),     // كارت الترحيب والنقاط
                _buildVisibleMotivationText(),  // الجملة الذهبية الصريحة
                _buildDailyInspirationBox(),    // صندوق المهمة اليومية
                _buildNewsTickerMarquee(),      // شريط الأخبار المتحرك
                
                const SizedBox(height: 30),
                _buildSectionHeading(isArabic ? "بوابات التعلم" : "Learning Gates"),
                _buildGatewaysRow(),            // فريش ومحترف
                
                const SizedBox(height: 35),
                _buildSectionHeading(isArabic ? "الأدوات والمنافسات" : "Pro Services"),
                _buildActionButtonsList(),       // القائمة المترابطة بالدوري والنشاط
                
                const SizedBox(height: 100), // مساحة تأمين للتنقل
              ],
            ),
          ),
        ),
      ],
    );
  }

  // =============================================================
  // [4] تفصيل الأجزاء البصرية (Atomic UI Components)
  // =============================================================

  Widget _buildRoyalAppBarHeader() {
    return SliverAppBar(
      expandedHeight: 110,
      floating: true, pinned: true, elevation: 8,
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
      // تأكدي من وجود logo.svg في مجلد assets
      title: SvgPicture.asset('assets/logo.svg', height: 35),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.language_rounded, color: Colors.white, size: 26),
          onPressed: () => setState(() => isArabic = !isArabic),
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildMainUserHeaderCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: pureWhite,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06), 
            blurRadius: 25, 
            offset: const Offset(0, 10)
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isArabic ? "أهلاً بكِ مجدداً" : "Welcome Back", 
                style: GoogleFonts.cairo(color: navyDeep.withOpacity(0.4), fontSize: 13, fontWeight: FontWeight.bold)
              ),
              Text(
                userName, 
                style: GoogleFonts.cairo(color: navyDeep, fontSize: 28, fontWeight: FontWeight.w900, height: 1.2)
              ),
              const SizedBox(height: 10),
              _buildRankBadgeWidget(),
            ],
          ),
          _buildPointsStatusCircle(),
        ],
      ),
    );
  }

  Widget _buildRankBadgeWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: iceGray, 
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: brandOrange.withOpacity(0.1))
      ),
      child: Text(
        userRank, 
        style: GoogleFonts.cairo(color: brandOrange, fontSize: 11, fontWeight: FontWeight.bold)
      ),
    );
  }

  Widget _buildPointsStatusCircle() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(color: iceGray, shape: BoxShape.circle),
      child: Column(
        children: [
          const Icon(Icons.stars_rounded, color: brandOrange, size: 40),
          Text(
            "$userPoints", 
            style: GoogleFonts.poppins(color: navyDeep, fontWeight: FontWeight.bold, fontSize: 18)
          ),
          Text(
            isArabic ? "نقطة" : "Pts", 
            style: GoogleFonts.cairo(fontSize: 10, color: navyDeep.withOpacity(0.5))
          ),
        ],
      ),
    );
  }

  Widget _buildVisibleMotivationText() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Text(
        isArabic ? "النهاردة يوم جديد.. استعدي لإنجاز كبير! ✨" : "Ready for a big win! ✨",
        style: GoogleFonts.cairo(
          color: brandOrange, 
          fontWeight: FontWeight.w900, 
          fontSize: 16
        ),
      ),
    );
  }

  Widget _buildActionButtonsList() {
    return Column(
      children: [
        _buildUnifiedActionTile(
          title: isArabic ? "الدوري العقاري" : "RE League", 
          icon: Icons.emoji_events_outlined, 
          hasBadge: true,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const RealEstateLeague())),
        ),
        _buildUnifiedActionTile(
          title: isArabic ? "نشط ذهنك" : "Quiz Zone", 
          icon: Icons.psychology_outlined, 
          hasBadge: false,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const QuizScreen())),
        ),
        _buildUnifiedActionTile(title: isArabic ? "مكتبة المحتوى" : "Library", icon: Icons.library_books_outlined, hasBadge: false),
        _buildUnifiedActionTile(title: isArabic ? "حاسبة التمويل" : "Calc", icon: Icons.calculate_outlined, hasBadge: false),
        _buildUnifiedActionTile(title: isArabic ? "خريطة المشاريع" : "Map", icon: Icons.map_outlined, hasBadge: false),
      ],
    );
  }

  Widget _buildUnifiedActionTile({required String title, required IconData icon, required bool hasBadge, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: pureWhite,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: iceGray, shape: BoxShape.circle),
              child: Icon(icon, color: navyDeep, size: 26),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(title, style: GoogleFonts.cairo(color: navyDeep, fontWeight: FontWeight.bold, fontSize: 17)),
            ),
            if (hasBadge) const CircleAvatar(radius: 4, backgroundColor: brandOrange),
            const SizedBox(width: 10),
            const Icon(Icons.arrow_forward_ios_rounded, color: brandOrange, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsTickerMarquee() {
    return Container(
      margin: const EdgeInsets.only(top: 25),
      height: 52,
      color: brandOrange.withOpacity(0.12),
      child: ListView.builder(
        controller: _newsScrollController,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 35),
            alignment: Alignment.center,
            child: Row(
              children: [
                const Icon(Icons.bolt_rounded, color: navyDeep, size: 20),
                const SizedBox(width: 10),
                Text(
                  isArabic ? "عاجل: تحديثات السوق العقاري في العاصمة الآن" : "🔥 Market Update", 
                  style: GoogleFonts.cairo(color: navyDeep, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGatewaysRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildGatewayCard(isArabic ? "فريش" : "FRESH", "https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?w=600"),
          const SizedBox(width: 15),
          _buildGatewayCard(isArabic ? "محترف" : "PRO", "https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=400"),
        ],
      ),
    );
  }

  Widget _buildGatewayCard(String title, String url) {
    return Expanded(
      child: Container(
        height: 230,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 12, offset: const Offset(0, 6))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Stack(fit: StackFit.expand, children: [
            Image.network(url, fit: BoxFit.cover),
            Container(color: navyDeep.withOpacity(0.45)),
            Center(child: Text(title, style: GoogleFonts.cairo(color: pureWhite, fontSize: 26, fontWeight: FontWeight.w900))),
          ]),
        ),
      ),
    );
  }

  Widget _buildDailyInspirationBox() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: navyDeep.withOpacity(0.04),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: navyDeep.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_circle_outlined, color: brandOrange, size: 38),
          const SizedBox(width: 18),
          Expanded(
            child: Text(
              isArabic ? "رأيك إيه نراجع مشروع في التجمع النهاردة؟ 🚀" : "Review New Cairo! 🚀", 
              style: GoogleFonts.cairo(color: navyDeep, fontSize: 14, fontWeight: FontWeight.w600, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeading(String label) {
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
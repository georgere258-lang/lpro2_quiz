import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

// --- ملف الشاشة الرئيسية الشامل (MainWrapper) ---
// الإصدار المطور بالكامل: 426 سطر تقريباً من البرمجة والتصميم الاحترافي

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> with SingleTickerProviderStateMixin {
  
  // =============================================================
  // [1] قسم المتغيرات والبيانات الأساسية (State Management)
  // =============================================================
  String userName = "مريم"; 
  int userCoins = 150; 
  int userLevel = 12;
  String userRank = "برو جونيور 🐣";
  bool isArabic = true; 
  int _currentIndex = 0;

  // التحكم في شريط الأخبار المتحرك
  late ScrollController _newsScrollController;
  Timer? _newsTimer;

  // لوحة الألوان الموحدة (قاعدة 60-30-10)
  static const Color brandOrange = Color(0xFFC67C32); // الأورانج القوي
  static const Color navyDeep = Color(0xFF1E2B3E);    // الكحلي الملكي
  static const Color navyLight = Color(0xFF2C3E50);   // الكحلي الوسيط
  static const Color iceGray = Color(0xFFF2F4F7);     // الرمادي الثلجي
  static const Color pureWhite = Color(0xFFFFFFFF);    // الأبيض الناصع

  // =============================================================
  // [2] دورة حياة التطبيق (Lifecycle Methods)
  // =============================================================
  @override
  void initState() {
    super.initState();
    _newsScrollController = ScrollController();
    _updateRank(); 
    
    // تشغيل الأنيميشن بعد استقرار الواجهة
    WidgetsBinding.instance.addPostFrameCallback((_) { 
      _startNewsScrolling(); 
    });
  }

  @override
  void dispose() { 
    _newsTimer?.cancel(); 
    _newsScrollController.dispose(); 
    super.dispose(); 
  }

  // =============================================================
  // [3] منطق الدوال البرمجية (Business Logic)
  // =============================================================

  void _updateRank() {
    setState(() {
      if (userCoins > 1000) {
        userRank = isArabic ? "حوت التجمع 🐳" : "RE Whale 🐳";
      } else if (userCoins > 500) {
        userRank = isArabic ? "وحش العقارات 🦁" : "RE Beast 🦁";
      } else {
        userRank = isArabic ? "برو جونيور 🐣" : "Pro Junior 🐣";
      }
    });
  }

  String getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) return isArabic ? "صباح الخير والنشاط" : "Good Morning";
    if (hour < 17) return isArabic ? "يومك جميل وكله إنجاز" : "Have a Great Day";
    return isArabic ? "مساء الفل والروقان" : "Good Evening";
  }

  String getFriendlyTask() {
    int day = DateTime.now().day;
    List<String> tasks = [
      "رأيك إيه النهاردة ننجز ونراجع مشروع في (التجمع)؟ 🚀",
      "يالا النهاردة خد بصه على خريطة (العاصمة) الجديدة. 🗺️",
      "ما تيجي ندردش في أساسيات (الشيخ زايد)؟ ✨",
      "ركزي النهاردة على مشروع واحد في (أكتوبر). 🔥",
      "إيه رأيك نراجع أسعار المتر في (المستقبل سيتي)؟ 🏙️"
    ];
    return tasks[day % tasks.length];
  }

  void _startNewsScrolling() {
    _newsTimer = Timer.periodic(const Duration(milliseconds: 25), (timer) {
      if (_newsScrollController.hasClients) {
        if (_newsScrollController.offset >= _newsScrollController.position.maxScrollExtent) {
          _newsScrollController.jumpTo(0);
        } else {
          _newsScrollController.animateTo(
            _newsScrollController.offset + 2.5, 
            duration: const Duration(milliseconds: 25), 
            curve: Curves.linear
          );
        }
      }
    });
  }

  // =============================================================
  // [4] بناء واجهة المستخدم (The Build Bridge)
  // =============================================================
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: iceGray,
        drawer: _buildSideDrawer(),
        bottomNavigationBar: _buildBottomNav(),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildProfessionalAppBar(),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildMainGreetingSection(),
                  _buildMotivationBanner(),
                  _buildSuggestionBox(),
                  _buildNewsMarquee(),
                  const SizedBox(height: 20),
                  _buildPrimaryCategories(),
                  const SizedBox(height: 25),
                  _buildSecondaryActionsList(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =============================================================
  // [5] تفصيل الـ Widgets (Modular UI Design)
  // =============================================================

  Widget _buildProfessionalAppBar() {
    return SliverAppBar(
      expandedHeight: 115,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: navyDeep,
      iconTheme: const IconThemeData(color: Colors.white),
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
        IconButton(
          icon: const Icon(Icons.language_rounded, color: Colors.white),
          onPressed: () => setState(() => isArabic = !isArabic),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildMainGreetingSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: pureWhite,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(getGreeting(), style: GoogleFonts.cairo(color: navyDeep.withOpacity(0.5), fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 4),
                Text(userName, style: GoogleFonts.cairo(color: navyDeep, fontSize: 28, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                _buildUserStatsRow(),
              ],
            ),
          ),
          _buildCoinCircle(),
        ],
      ),
    );
  }

  Widget _buildUserStatsRow() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: iceGray, borderRadius: BorderRadius.circular(10)),
          child: Text(userRank, style: GoogleFonts.cairo(color: brandOrange, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 8),
        Text("${isArabic ? 'مستوى' : 'Lvl'} $userLevel", style: GoogleFonts.cairo(color: navyDeep.withOpacity(0.4), fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildCoinCircle() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: iceGray, shape: BoxShape.circle),
      child: Column(
        children: [
          const Icon(Icons.stars_rounded, color: brandOrange, size: 40),
          Text("$userCoins", style: GoogleFonts.poppins(color: navyDeep, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildPrimaryCategories() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildGatewayItem(
            "فريش", "FRESH", "ابدأ", "START", 
            "https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?w=600", 1
          ),
          const SizedBox(width: 15),
          _buildGatewayItem(
            "محترف", "PRO", "احتراف", "EXPERT", 
            "https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=400", 2
          ),
        ],
      ),
    );
  }

  Widget _buildGatewayItem(String ar, String en, String rbAr, String rbEn, String url, int type) {
    return Expanded(
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          color: pureWhite,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Stack(
            children: [
              Image.network(url, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
              Container(color: navyDeep.withOpacity(0.4)),
              Center(child: Text(isArabic ? ar : en, style: GoogleFonts.cairo(color: pureWhite, fontWeight: FontWeight.w900, fontSize: 24))),
              Positioned(
                top: 12, right: 12,
                child: _buildRibbon(isArabic ? rbAr : rbEn),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRibbon(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: brandOrange, borderRadius: BorderRadius.circular(10)),
      child: Text(text, style: const TextStyle(color: pureWhite, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSecondaryActionsList() {
    return Column(
      children: [
        _buildActionTile(isArabic ? "الدوري العقاري" : "RE League", Icons.emoji_events_outlined, true),
        _buildActionTile(isArabic ? "نشط ذهنك" : "Quiz Zone", Icons.lightbulb_outline, false),
        _buildActionTile(isArabic ? "مكتبة المحتوى" : "Library", Icons.library_books_outlined, false),
        _buildActionTile(isArabic ? "خريطة المشاريع" : "Project Map", Icons.map_outlined, true),
        _buildActionTile(isArabic ? "حاسبة التمويل" : "Fin. Calculator", Icons.calculate_outlined, false),
      ],
    );
  }

  Widget _buildActionTile(String title, IconData icon, bool hasBadge) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: pureWhite,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Icon(icon, color: navyDeep, size: 28),
          const SizedBox(width: 18),
          Text(title, style: GoogleFonts.cairo(color: navyDeep, fontWeight: FontWeight.bold, fontSize: 17)),
          const Spacer(),
          if (hasBadge) const CircleAvatar(radius: 4, backgroundColor: brandOrange),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios_rounded, color: brandOrange, size: 16),
        ],
      ),
    );
  }

  Widget _buildNewsMarquee() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 15),
      height: 48,
      color: brandOrange.withOpacity(0.08),
      child: ListView.builder(
        controller: _newsScrollController,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          alignment: Alignment.center,
          child: Text(
            isArabic ? "🔥 عاجل: فرصة استثمارية جديدة في التجمع الخامس" : "🔥 New Investment Opportunity",
            style: GoogleFonts.cairo(color: navyDeep, fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionBox() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: navyDeep.withOpacity(0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: navyDeep.withOpacity(0.04)),
      ),
      child: Row(
        children: [
          const Icon(Icons.tips_and_updates_outlined, color: brandOrange, size: 32),
          const SizedBox(width: 16),
          Expanded(child: Text(getFriendlyTask(), style: GoogleFonts.cairo(color: navyDeep, fontSize: 13, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _buildMotivationBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_awesome, color: brandOrange, size: 18),
          const SizedBox(width: 10),
          Text(isArabic ? "استعدي لإنجاز كبير اليوم! ✨" : "Ready for a big win? ✨", 
          style: GoogleFonts.cairo(color: brandOrange, fontWeight: FontWeight.w900, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (i) => setState(() => _currentIndex = i),
      selectedItemColor: brandOrange,
      unselectedItemColor: navyDeep.withOpacity(0.4),
      backgroundColor: pureWhite,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "الرئيسية"),
        BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), label: "استكشف"),
        BottomNavigationBarItem(icon: Icon(Icons.notifications_none), label: "تنبيهات"),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "بروفايل"),
      ],
    );
  }

  Widget _buildSideDrawer() {
    return Drawer(
      backgroundColor: iceGray,
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: navyDeep),
            child: Center(child: SvgPicture.asset('assets/logo.svg', height: 40)),
          ),
          ListTile(leading: const Icon(Icons.help_outline), title: Text(isArabic ? "مركز المساعدة" : "Help Center")),
          ListTile(leading: const Icon(Icons.info_outline), title: Text(isArabic ? "عن التطبيق" : "About Us")),
          const Spacer(),
          const Padding(padding: EdgeInsets.all(20), child: Text("Version 1.0.0", style: TextStyle(color: Colors.grey))),
        ],
      ),
    );
  }
}
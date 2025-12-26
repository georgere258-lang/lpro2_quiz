import 'dart:async';
import 'package:flutter/material.dart';
import 'package:carousel_slider_plus/carousel_slider_plus.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'real_estate_league.dart';
import 'quiz_screen.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});
  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  String userName = "مريم"; 
  int userCoins = 150; 
  String userRank = "برو جونيور 🐣";

  late ScrollController _newsScrollController;
  Timer? _newsTimer;

  static const Color brandOrange = Color(0xFFFF4D00); 
  static const Color electricBlue = Color(0xFF00D2FF); 
  static const Color navyDark = Color(0xFF080E1D); 

  @override
  void initState() {
    super.initState();
    _newsScrollController = ScrollController();
    _updateRank(); 
    WidgetsBinding.instance.addPostFrameCallback((_) { _startNewsScrolling(); });
  }

  // --- دالة التحية الديناميكية المشجعة ---
  String getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) return "صباح الخير والنشاط ☀️";
    if (hour < 17) return "يومك جميل وكله إنجاز ✨";
    return "مساء الفل والروقان 🌙";
  }

  void _navigateToCategory(String title, Color themeColor, Widget content) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => 
      CategoryDetailScreen(title: title, themeColor: themeColor, content: content)));
  }

  void _updateRank() {
    setState(() {
      if (userCoins > 1000) userRank = "حوت التجمع 🐳";
      else if (userCoins > 500) userRank = "وحش العقارات 🦁";
      else userRank = "برو جونيور 🐣";
    });
  }

  void _addCoins(int amount) {
    setState(() { userCoins += amount; _updateRank(); });
  }

  void _startNewsScrolling() {
    _newsTimer = Timer.periodic(const Duration(milliseconds: 25), (timer) {
      if (_newsScrollController.hasClients) {
        if (_newsScrollController.offset >= _newsScrollController.position.maxScrollExtent) {
          _newsScrollController.jumpTo(0);
        } else {
          _newsScrollController.animateTo(_newsScrollController.offset + 2.5, duration: const Duration(milliseconds: 25), curve: Curves.linear);
        }
      }
    });
  }

  @override
  void dispose() { _newsTimer?.cancel(); _newsScrollController.dispose(); super.dispose(); }

  // --- محتويات الأقسام الداخلية ---
  Widget _buildFreshContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.auto_awesome, color: electricBlue, size: 80),
          SizedBox(height: 20),
          Text("اتعلم . اتطور . برو", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          Padding(
            padding: EdgeInsets.all(20),
            child: Text("هنا هتبدأ رحلتك التعليمية من الصفر لحد الاحتراف", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  Widget _buildKabeerContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.sports_esports, color: brandOrange, size: 80),
          SizedBox(height: 20),
          Text("ملعب الحريفة", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          Padding(
            padding: EdgeInsets.all(20),
            child: Text("ده مكان الوحوش اللي فاهمة السوق ومستعدة للتحدي", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: RadialGradient(center: Alignment(-0.5, -0.6), radius: 1.5, colors: [Color(0xFF1E293B), navyDark])),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              floating: true, backgroundColor: Colors.transparent, elevation: 0, centerTitle: true,
              title: _buildLogoWithPlayButton(brandOrange),
              leading: const Icon(Icons.menu_rounded, color: Colors.white),
            ),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildHeaderCard(),
                  _buildMotivationQuote(),
                  _buildSuggestionZone(),
                  _buildNewsTicker(brandOrange),

                  const SizedBox(height: 25),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStaticGatewayCard(
                            title: "تعالى يا فريش",
                            subtitle: "اتعلم . اتطور . برو 🐣",
                            image: "https://images.unsplash.com/photo-1560514483-8444758b710b?w=400",
                            accentColor: electricBlue,
                            onTap: () => _navigateToCategory("تعالى يا فريش 🐣", electricBlue, _buildFreshContent()),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _buildStaticGatewayCard(
                            title: "تعالى يا كبير",
                            subtitle: "ملعب الحريفة 🦁",
                            image: "https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=400",
                            accentColor: brandOrange,
                            onTap: () => _navigateToCategory("تعالى يا كبير 🦁", brandOrange, _buildKabeerContent()),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),
                  _buildWideActionCard(context, "الدوري العقاري", "https://images.unsplash.com/photo-1511467687858-23d96c32e4ae?w=600", brandOrange),
                  _buildWideActionCard(context, "نشط ذهنك", "https://images.unsplash.com/photo-1557426272-fc759fdf7a8d?w=600", electricBlue),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- دوال بناء الـ Widgets الفرعية ---
  Widget _buildHeaderCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(25, 20, 25, 0),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(25), color: const Color(0xFF1E293B), border: Border.all(color: Colors.white10)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(getGreeting(), style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13)),
          Text(userName, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
        ]),
        const Icon(Icons.stars_rounded, color: Colors.amber, size: 35),
      ]),
    );
  }

  Widget _buildMotivationQuote() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 35, vertical: 12),
      child: Row(children: [
        Icon(Icons.auto_awesome, color: Colors.amber, size: 16),
        SizedBox(width: 10),
        Text("النهاردة يوم جديد.. استعدي لإنجاز كبير! ✨", style: TextStyle(color: Colors.amberAccent, fontSize: 13, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _buildSuggestionZone() {
    int day = DateTime.now().day;
    List<String> headers = ["لو فيكِ دماغ النهاردة.. 🧠", "إيه رأيك تنجزي دي؟ 🔥", "يلا بينا يا مريم.. 🚀"];
    List<String> projects = ["التجمع الخامس", "الشيخ زايد", "العاصمة الإدارية"];
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: electricBlue.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.psychology_alt, color: electricBlue, size: 24)),
        const SizedBox(width: 15),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(headers[day % headers.length], style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.w900, fontSize: 15)),
          const SizedBox(height: 4),
          Text("راجعي النهاردة مشروع في (${projects[day % projects.length]}) عشان تثبتي معلوماتك.", style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
        ])),
      ]),
    );
  }

  Widget _buildNewsTicker(Color orange) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      height: 45,
      decoration: BoxDecoration(color: orange.withOpacity(0.05), border: Border(top: BorderSide(color: orange.withOpacity(0.2)), bottom: BorderSide(color: orange.withOpacity(0.2)))),
      child: Row(children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 15), color: orange, alignment: Alignment.center, child: const Text("حصل إيه؟ ⚡", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
        Expanded(child: ListView.builder(
          controller: _newsScrollController,
          scrollDirection: Axis.horizontal,
          itemBuilder: (context, index) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.center,
            child: const Text("🔥 عاجل: انطلاق أكبر مشروع سكني في شرق القاهرة اليوم.. تابع التفاصيل", style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
        )),
      ]),
    );
  }

  Widget _buildStaticGatewayCard({required String title, required String subtitle, required String image, required Color accentColor, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          image: DecorationImage(image: NetworkImage(image), fit: BoxFit.cover, colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.4), BlendMode.darken)),
          border: Border.all(color: accentColor.withOpacity(0.5), width: 3),
          boxShadow: [BoxShadow(color: accentColor.withOpacity(0.2), blurRadius: 10, spreadRadius: 1)],
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 5),
          Text(subtitle, style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 13)),
        ]),
      ),
    );
  }

  Widget _buildWideActionCard(BuildContext context, String title, String img, Color accent) {
    return GestureDetector(
      onTap: () { 
        if (title == "الدوري العقاري") Navigator.push(context, MaterialPageRoute(builder: (context) => const RealEstateLeague()));
        if (title == "نشط ذهنك") Navigator.push(context, MaterialPageRoute(builder: (context) => const QuizScreen()));
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
        height: 90,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(25), image: DecorationImage(image: NetworkImage(img), fit: BoxFit.cover, colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.darken))),
        child: Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(borderRadius: BorderRadius.circular(25), gradient: LinearGradient(colors: [Colors.black.withOpacity(0.8), Colors.transparent])), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)), Icon(Icons.play_circle_fill, color: accent, size: 35)])),
      ),
    );
  }

  Widget _buildLogoWithPlayButton(Color triangleColor) {
    return Row(mainAxisSize: MainAxisSize.min, children: [Stack(alignment: Alignment.center, children: [const Text("L", style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)), Positioned(left: 11, bottom: 20, child: CustomPaint(size: const Size(9, 9), painter: TrianglePainter(color: triangleColor)))]), const Text("Pro", style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900))]);
  }
} // <--- نهاية كلاس الـ State الأساسي
// شاشة تفاصيل الأقسام مع سهم الرجوع
class CategoryDetailScreen extends StatelessWidget {
  final String title;
  final Color themeColor;
  final Widget content;

  const CategoryDetailScreen({
    super.key, 
    required this.title, 
    required this.themeColor, 
    required this.content
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080E1D),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), 
        backgroundColor: themeColor, 
        centerTitle: true,
        elevation: 10,
      ),
      body: content,
    );
  }
}

class TrianglePainter extends CustomPainter {
  final Color color;
  TrianglePainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()..color = color..style = PaintingStyle.fill;
    Path path = Path();
    path.moveTo(0, 0); path.lineTo(size.width, size.height / 2); path.lineTo(0, size.height); path.close();
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
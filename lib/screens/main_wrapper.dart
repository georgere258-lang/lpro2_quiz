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
  bool isArabic = true; 

  late ScrollController _newsScrollController;
  Timer? _newsTimer;

  // --- باليتة الألوان المحدثة (Deep Orange & Gold) ---
  static const Color brandOrange = Color(0xFFE64A19); 
  static const Color goldColor = Color(0xFFFFD700);   
  static const Color electricBlue = Color(0xFF00D2FF); 
  static const Color navyDark = Color(0xFF080E1D); 

  @override
  void initState() {
    super.initState();
    _newsScrollController = ScrollController();
    _updateRank(); 
    WidgetsBinding.instance.addPostFrameCallback((_) { _startNewsScrolling(); });
  }

  String getFriendlyTask() {
    int day = DateTime.now().day;
    List<String> tasks = [
      "رأيك إيه النهاردة ننجز ونراجع مشروع في (التجمع) ومشروع في (العاصمة)؟ 🚀",
      "بقولك إيه.. يالا النهاردة خد بصه على خريطة (العاصمة) وشوف الجديد هناك. 🗺️",
      "ما تيجي ندردش شوية في أساسيات (الشيخ زايد) ونشوف سابقة أعمال المطورين؟ ✨",
      "إيه رأيك لو النهاردة ركزنا على مشروع واحد بس في (أكتوبر) ونعرف كل تفاصيله؟ 🔥"
    ];
    return tasks[day % tasks.length];
  }

  String getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) return isArabic ? "صباح الخير والنشاط" : "Good Morning";
    if (hour < 17) return isArabic ? "يومك جميل وكله إنجاز" : "Have a Great Day";
    return isArabic ? "مساء الفل والروقان" : "Good Evening";
  }

  void _navigateToCategory(String title, Color themeColor, Widget content) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => 
      CategoryDetailScreen(title: title, themeColor: themeColor, content: content, isArabic: isArabic)));
  }

  void _updateRank() {
    setState(() {
      if (userCoins > 1000) userRank = isArabic ? "حوت التجمع 🐳" : "RE Whale 🐳";
      else if (userCoins > 500) userRank = isArabic ? "وحش العقارات 🦁" : "RE Beast 🦁";
      else userRank = isArabic ? "برو جونيور 🐣" : "Pro Junior 🐣";
    });
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1E293B), navyDark])
          ),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                floating: true, backgroundColor: Colors.transparent, elevation: 0, centerTitle: true,
                title: Directionality(textDirection: TextDirection.ltr, child: _buildLogoWithPlayButton(brandOrange)),
                actions: [
                  IconButton(icon: const Icon(Icons.language, color: Colors.white), onPressed: () => setState(() => isArabic = !isArabic))
                ],
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
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildGatewayCard(
                              mainTitle: isArabic ? "فريش" : "FRESH",
                              subTitle: isArabic ? "ده مكانك.. اتعلم واتطور" : "Your place to grow",
                              welcomeNote: isArabic ? "تعالى اتفضل" : "Welcome In",
                              ribbonText: isArabic ? "اتعلم اتطور" : "LEARN",
                              image: "https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?w=600", 
                              onTap: () => _navigateToCategory(isArabic ? "يا فريش.. ده مكانك 🐣" : "Fresh Zone 🐣", brandOrange, _buildFreshContent()),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: _buildGatewayCard(
                              mainTitle: isArabic ? "محترف" : "PRO",
                              subTitle: isArabic ? "مكانك يا كبير" : "Pro playground",
                              welcomeNote: isArabic ? "ملعب الحريفة.. أهلاً بيك" : "Master's Arena",
                              ribbonText: isArabic ? "كمل طريقك" : "PATH",
                              image: "https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=400",
                              onTap: () => _navigateToCategory(isArabic ? "محترف.. مكانك يا كبير 🦁" : "Pro Arena 🦁", brandOrange, _buildKabeerContent()),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),
                    _buildWideActionCard(context, isArabic ? "الدوري العقاري" : "RE League", "https://images.unsplash.com/photo-1511467687858-23d96c32e4ae?w=600"),
                    _buildWideActionCard(context, isArabic ? "نشط ذهنك" : "Quiz Zone", "https://images.unsplash.com/photo-1557426272-fc759fdf7a8d?w=600"),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildGatewayCard({required String mainTitle, required String subTitle, required String welcomeNote, required String ribbonText, required String image, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            height: 230,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              image: DecorationImage(image: NetworkImage(image), fit: BoxFit.cover, colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.65), BlendMode.darken)),
              border: Border.all(color: Colors.white, width: 2.5), 
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(mainTitle, style: const TextStyle(color: brandOrange, fontWeight: FontWeight.w900, fontSize: 28, letterSpacing: 1.5)),
                  const SizedBox(height: 10),
                  Text(subTitle, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 5),
                  Text(welcomeNote, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13, fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0, right: isArabic ? 0 : null, left: isArabic ? null : 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topRight: Radius.circular(isArabic ? 28 : 0), topLeft: Radius.circular(isArabic ? 0 : 28), bottomLeft: Radius.circular(isArabic ? 15 : 0), bottomRight: Radius.circular(isArabic ? 0 : 15))),
              child: Text(ribbonText, style: const TextStyle(color: brandOrange, fontSize: 10, fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(25, 20, 25, 0),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(25), color: const Color(0xFF1E293B), border: Border.all(color: Colors.white10)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(getGreeting(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          Text(userName, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
        ]),
        Container(
          height: 50, width: 50,
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: const Icon(Icons.stars_rounded, color: brandOrange, size: 35),
        )
      ]),
    );
  }

  Widget _buildWideActionCard(context, title, img) {
    return GestureDetector(
      onTap: () { 
        if (title == "الدوري العقاري" || title == "RE League") Navigator.push(context, MaterialPageRoute(builder: (context) => const RealEstateLeague()));
        if (title == "نشط ذهنك" || title == "Quiz Zone") Navigator.push(context, MaterialPageRoute(builder: (context) => const QuizScreen()));
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 8), height: 100,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(25), image: DecorationImage(image: NetworkImage(img), fit: BoxFit.cover, colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.4), BlendMode.darken))),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(25), gradient: LinearGradient(colors: [Colors.black.withOpacity(0.7), Colors.transparent])),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
            Container(
              height: 45, width: 45,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.play_arrow_rounded, color: brandOrange, size: 30),
            )
          ]),
        ),
      ),
    );
  }

  Widget _buildSuggestionZone() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(22), border: Border.all(color: Colors.white10)),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: electricBlue.withOpacity(0.15), shape: BoxShape.circle), child: const Icon(Icons.psychology_alt, color: electricBlue, size: 28)),
        const SizedBox(width: 18),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(isArabic ? "بقولك إيه.. 🔥" : "Hey.. 🔥", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17)),
          const SizedBox(height: 6),
          Text(isArabic ? getFriendlyTask() : "Check today's task.", style: const TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w600)),
        ])),
      ]),
    );
  }

  Widget _buildNewsTicker(Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      height: 45,
      decoration: BoxDecoration(color: color.withOpacity(0.1), border: Border(top: BorderSide(color: color.withOpacity(0.3)), bottom: BorderSide(color: color.withOpacity(0.3)))),
      child: Row(children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 15), color: color, alignment: Alignment.center, child: Text(isArabic ? "حصل إيه؟ ⚡" : "Update ⚡", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
        Expanded(child: ListView.builder(controller: _newsScrollController, scrollDirection: Axis.horizontal, itemBuilder: (context, index) => Container(padding: const EdgeInsets.symmetric(horizontal: 20), alignment: Alignment.center, child: Text(isArabic ? "🔥 عاجل: انطلاق مشروع جديد في القاهرة" : "🔥 Breaking news...", style: const TextStyle(color: Colors.white, fontSize: 12))))),
      ]),
    );
  }

  Widget _buildMotivationQuote() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 15),
      child: Row(children: [
        const Icon(Icons.auto_awesome, color: goldColor, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(isArabic ? "النهاردة يوم جديد.. استعدي لإنجاز كبير! ✨" : "Get ready for greatness! ✨", style: const TextStyle(color: goldColor, fontSize: 16, fontWeight: FontWeight.w900))),
      ]),
    );
  }

  Widget _buildLogoWithPlayButton(Color triangleColor) {
    return Row(mainAxisSize: MainAxisSize.min, children: [Stack(alignment: Alignment.center, children: [const Text("L", style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)), Positioned(left: 11, bottom: 20, child: CustomPaint(size: const Size(9, 9), painter: TrianglePainter(color: triangleColor)))]), const Text("Pro", style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900))]);
  }
  Widget _buildFreshContent() { return const Center(child: Text("Loading...", style: TextStyle(color: Colors.white))); }
  Widget _buildKabeerContent() { return const Center(child: Text("Loading...", style: TextStyle(color: Colors.white))); }
}

class CategoryDetailScreen extends StatelessWidget {
  final String title; final Color themeColor; final Widget content; final bool isArabic;
  const CategoryDetailScreen({super.key, required this.title, required this.themeColor, required this.content, required this.isArabic});
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFF080E1D),
        appBar: AppBar(
          leading: IconButton(icon: Icon(isArabic ? Icons.arrow_forward_ios : Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.pop(context)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), 
          backgroundColor: themeColor, centerTitle: true,
        ),
        body: content,
      ),
    );
  }
}

class TrianglePainter extends CustomPainter {
  final Color color; TrianglePainter({required this.color});
  @override void paint(Canvas canvas, Size size) {
    Paint paint = Paint()..color = color..style = PaintingStyle.fill;
    Path path = Path(); path.moveTo(0, 0); path.lineTo(size.width, size.height / 2); path.lineTo(0, size.height); path.close();
    canvas.drawPath(path, paint);
  }
  @override bool shouldRepaint(CustomPainter oldDelegate) => false;
}
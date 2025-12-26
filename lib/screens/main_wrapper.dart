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
  // --- بيانات المستخدم ونظام النقاط ---
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

  // --- دوال التحية والجمل التشجيعية المستعادة ---
  String getSuggestionHeader() {
    int day = DateTime.now().day;
    List<String> headers = ["هنعمل إيه النهاردة؟ 🤔", "إيه رأيك لو..", "لو فيك دماغ، يلا بينا.. 🚀", "ما تيجي كدة ندوس شوية و.."];
    return headers[day % headers.length];
  }

  String getSuggestionBody() {
    var hour = DateTime.now().hour;
    int day = DateTime.now().day;
    List<String> morning = ["نراجع مشروع واحد في (التجمع) أو (الشيخ زايد)؟", "نبص على ماستر بلان لمشروع في (العاصمة) أو (6 أكتوبر)؟"];
    List<String> evening = ["تقرأ خبر واحد عن (العاصمة) أو (زايد) قبل ما تنام؟"];
    return (hour < 17) ? morning[day % morning.length] : evening[day % evening.length];
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("مبروك! حصلت على $amount نقطة 🏆"), duration: const Duration(seconds: 1), backgroundColor: brandOrange)
    );
  }

  void _startNewsScrolling() {
    _newsTimer = Timer.periodic(const Duration(milliseconds: 25), (timer) {
      if (_newsScrollController.hasClients) {
        double maxScroll = _newsScrollController.position.maxScrollExtent;
        double currentScroll = _newsScrollController.offset;
        if (currentScroll >= maxScroll) _newsScrollController.jumpTo(0);
        else _newsScrollController.animateTo(currentScroll + 2.5, duration: const Duration(milliseconds: 25), curve: Curves.linear);
      }
    });
  }

  @override
  void dispose() { _newsTimer?.cancel(); _newsScrollController.dispose(); super.dispose(); }

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFullStatusBanner(brandOrange), // البانر الاحترافي الشامل
                  _buildNewsTicker(brandOrange), 

                  _buildSectionTitle("تعالى يا فريش 🐣", electricBlue),
                  CarouselSlider(
                    options: CarouselOptions(height: 180.0, autoPlay: true, enlargeCenterPage: true, viewportFraction: 0.8),
                    items: [
                      _buildFlashCard(context, "يعني إيه تحميل؟", "هي النسبة بين المساحة الصافية للشقة والمساحة الإجمالية (بما فيها الخدمات)"),
                      _buildImageCard(context, "المطورين وسابقة الأعمال", "https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=600"),
                      _buildImageCard(context, "أساسيات الـ MASTER PLAN", "https://images.unsplash.com/photo-1503387762-592dea58db2e?w=600"),
                    ],
                  ),

                  _buildSectionTitle("تعالى يا كبير 🦁", brandOrange),
                  CarouselSlider(
                    options: CarouselOptions(height: 180.0, autoPlay: true, enlargeCenterPage: true, viewportFraction: 0.8, autoPlayInterval: const Duration(seconds: 4)),
                    items: [
                      _buildNewsCategoryCard(context, "آخر الأخبار الحصرية", "https://images.unsplash.com/photo-1504711432869-efd597cdd04d?w=600", brandOrange, isNewsCard: true),
                      _buildMasterPlanChallengeCard(context), 
                      _buildImageCard(context, "على أرض الواقع 🏗️", "https://images.unsplash.com/photo-1541888946425-d81bb19240f5?w=600"),
                    ],
                  ),

                  _buildSectionTitle("خليك جاهز", electricBlue),
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
  // --- البانر الاحترافي المستعاد (يجمع النقاط، اللقب، والتحية الذكية) ---
  Widget _buildFullStatusBanner(Color color) {
    var hour = DateTime.now().hour;
    String greeting = (hour < 12) ? "صباح الخير" : "طاب يومك بكل خير";

    return Container(
      margin: const EdgeInsets.all(25), padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), color: const Color(0xFF1E293B), border: Border.all(color: color.withOpacity(0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("$greeting، $userRank", style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13)),
            Text(userName, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900))
          ]),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.24), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white10)),
            child: Row(children: [
              const Icon(Icons.stars_rounded, color: Colors.amber, size: 20),
              const SizedBox(width: 5),
              Text("$userCoins", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ]),
          )
        ]),
        const SizedBox(height: 20),
        const Text("النهاردة يوم جميل.. استعد لإنجاز كبير! ✨", style: TextStyle(color: Colors.amberAccent, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(18), width: double.infinity, 
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(getSuggestionHeader(), style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 10),
            Text(getSuggestionBody(), style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5)),
          ]),
        ),
      ]),
    );
  }

  // --- كارت الـ Flash Card التفاعلي ---
  Widget _buildFlashCard(BuildContext context, String title, String explanation) {
    return GestureDetector(
      onTap: () {
        _showFlashCardDialog(context, title, explanation);
        _addCoins(5); 
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: const LinearGradient(begin: Alignment.topLeft, colors: [electricBlue, Color(0xFF0077FF)]),
        ),
        child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.style_rounded, color: Colors.white, size: 40),
          const SizedBox(height: 10),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
          const Text("اضغط لفك الشفرة 🧠", style: TextStyle(color: Colors.white70, fontSize: 11)),
        ])),
      ),
    );
  }

  void _showFlashCardDialog(BuildContext context, String title, String explanation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: Text(title, textAlign: TextAlign.right, style: const TextStyle(color: electricBlue, fontWeight: FontWeight.bold)),
        content: Text(explanation, textAlign: TextAlign.right, style: const TextStyle(color: Colors.white70, height: 1.5)),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("فهمتها! ✅", style: TextStyle(color: Colors.amber)))]
      ),
    );
  }

  // --- كارت تحدي الماستر بلان ---
  Widget _buildMasterPlanChallengeCard(BuildContext context) {
    return GestureDetector(
      onTap: () => _showQuickChallenge(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          image: const DecorationImage(image: NetworkImage("https://images.unsplash.com/photo-1582268611958-ebfd161ef9cf?w=600"), fit: BoxFit.cover),
          border: Border.all(color: brandOrange.withOpacity(0.5), width: 2),
        ),
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(23), gradient: LinearGradient(begin: Alignment.bottomCenter, colors: [Colors.black.withOpacity(0.9), Colors.transparent])),
          child: const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.psychology, color: Colors.amber, size: 30),
            Text("تحدي الحريفة: ده إيه؟", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            Text("اربح 20 نقطة 🎯", style: TextStyle(color: Colors.amber, fontSize: 12)),
          ])),
        ),
      ),
    );
  }

  void _showQuickChallenge(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: navyDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Text("تحدي سريع ⚡", textAlign: TextAlign.right, style: TextStyle(color: Colors.white)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.network("https://images.unsplash.com/photo-1582268611958-ebfd161ef9cf?w=600")),
          const SizedBox(height: 20),
          const Text("الماستر بلان دي تتبع أي مشروع؟", textAlign: TextAlign.right, style: TextStyle(color: Colors.white70)),
        ]),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: electricBlue), onPressed: () => Navigator.pop(context), child: const Text("Mountain View")),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: brandOrange), onPressed: () { Navigator.pop(context); _addCoins(20); }, child: const Text("Sodic Estates")),
        ],
      ),
    );
  }

  // --- الأدوات المساعدة المتبقية ---
  Widget _buildNewsCategoryCard(BuildContext context, String title, String imgUrl, Color accent, {bool isNewsCard = false}) {
    return GestureDetector(
      onTap: () => _openFullNewsPage(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(25), image: DecorationImage(image: NetworkImage(imgUrl), fit: BoxFit.cover, colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.4), BlendMode.darken)), border: Border.all(color: accent.withOpacity(0.5), width: 2)),
        child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(25), gradient: LinearGradient(begin: Alignment.bottomCenter, colors: [Colors.black.withOpacity(0.8), Colors.transparent])), child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(isNewsCard ? Icons.bolt : Icons.layers, color: accent, size: 30), Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))]))),
      ),
    );
  }

  void _openFullNewsPage(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => Scaffold(
      backgroundColor: navyDark, appBar: AppBar(title: const Text("كل الأخبار"), backgroundColor: Colors.transparent, elevation: 0, centerTitle: true),
      body: StreamBuilder<QuerySnapshot>(stream: FirebaseFirestore.instance.collection('news').snapshots(), builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var docs = snapshot.data!.docs;
        return ListView.builder(padding: const EdgeInsets.all(20), itemCount: docs.length, itemBuilder: (context, index) {
          var data = docs[index].data() as Map<String, dynamic>;
          return _buildDetailedNewsCard(context, data, brandOrange);
        });
      }),
    )));
  }

  Widget _buildDetailedNewsCard(BuildContext context, Map<String, dynamic> news, Color accent) {
    List<dynamic> points = news['points'] is List ? news['points'] : [];
    String newsDate = "الآن";
    if (news['date'] != null && news['date'] is Timestamp) {
      DateTime dt = (news['date'] as Timestamp).toDate();
      newsDate = "${dt.day}/${dt.month}/${dt.year}";
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 20), padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(25), border: Border.all(color: accent.withOpacity(0.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: accent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Row(children: [Icon(Icons.calendar_today_rounded, color: accent, size: 12), const SizedBox(width: 5), Text(newsDate, style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.bold))])),
          const Icon(Icons.bolt, color: Colors.amber, size: 16),
        ]),
        const SizedBox(height: 15),
        Text(news['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold, height: 1.3)),
        if (points.isNotEmpty) ...[const SizedBox(height: 15), const Divider(color: Colors.white10), ...points.map((p) => Padding(padding: const EdgeInsets.only(top: 10), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.check_circle_outline, color: accent, size: 16), const SizedBox(width: 10), Expanded(child: Text(p.toString(), style: const TextStyle(color: Colors.white70, fontSize: 13)))]))).toList()],
      ]),
    );
  }

  Widget _buildWideActionCard(BuildContext context, String title, String img, Color accent) {
    return GestureDetector(
      onTap: () { 
        if (title == "الدوري العقاري") Navigator.push(context, MaterialPageRoute(builder: (context) => const RealEstateLeague()));
        if (title == "نشط ذهنك") Navigator.push(context, MaterialPageRoute(builder: (context) => const QuizScreen()));
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 12), height: 110,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(28), image: DecorationImage(image: NetworkImage(img), fit: BoxFit.cover, colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.darken)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))]),
        child: Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(borderRadius: BorderRadius.circular(28), gradient: LinearGradient(colors: [Colors.black.withOpacity(0.85), Colors.transparent])), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22)), Icon(Icons.play_circle_fill_rounded, color: accent, size: 45)])),
      ),
    );
  }

  Widget _buildImageCard(BuildContext context, String title, String imageUrl) {
    return Container(margin: const EdgeInsets.symmetric(horizontal: 5), decoration: BoxDecoration(borderRadius: BorderRadius.circular(25), image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)), child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(25), gradient: LinearGradient(begin: Alignment.bottomCenter, colors: [Colors.black.withOpacity(0.9), Colors.transparent])), child: Center(child: Padding(padding: const EdgeInsets.all(15), child: Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))))));
  }

  Widget _buildLogoWithPlayButton(Color triangleColor) {
    return Row(mainAxisSize: MainAxisSize.min, children: [Stack(alignment: Alignment.center, children: [const Text("L", style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)), Positioned(left: 11, bottom: 20, child: CustomPaint(size: const Size(9, 9), painter: TrianglePainter(color: triangleColor)))]), const Text("Pro", style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900))]);
  }

  Widget _buildNewsTicker(Color orange) {
    return Container(margin: const EdgeInsets.symmetric(vertical: 10), height: 45, decoration: BoxDecoration(color: orange.withOpacity(0.05), border: Border(top: BorderSide(color: orange.withOpacity(0.2)), bottom: BorderSide(color: orange.withOpacity(0.2)))), child: Row(children: [Container(padding: const EdgeInsets.symmetric(horizontal: 15), color: orange, alignment: Alignment.center, child: const Text("حصل إيه؟ ⚡", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))), Expanded(child: StreamBuilder<QuerySnapshot>(stream: FirebaseFirestore.instance.collection('news').snapshots(), builder: (context, snapshot) { if (!snapshot.hasData) return const SizedBox(); var items = snapshot.data!.docs; return ListView.builder(controller: _newsScrollController, scrollDirection: Axis.horizontal, itemCount: items.length * 100, itemBuilder: (context, index) { var data = items[index % items.length].data() as Map<String, dynamic>; return Container(padding: const EdgeInsets.symmetric(horizontal: 20), alignment: Alignment.center, child: Text(data['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 13))); }); }))]));
  }

  Widget _buildSectionTitle(String title, Color accent) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 25), child: Row(children: [Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)), const SizedBox(width: 12), Container(height: 4, width: 30, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(10)))]));
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
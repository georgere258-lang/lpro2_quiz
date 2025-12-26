import 'dart:async';
import 'package:flutter/material.dart';
import 'package:carousel_slider_plus/carousel_slider_plus.dart'; 
import 'real_estate_league.dart';
import 'quiz_screen.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});
  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  String userName = "مريم"; 
  late ScrollController _newsScrollController;
  Timer? _newsTimer;

  // الألوان الحيوية الجديدة
  static const Color brandOrange = Color(0xFFFF4D00); 
  static const Color electricBlue = Color(0xFF00D2FF); 
  static const Color navyDark = Color(0xFF080E1D); 

  final List<Map<String, dynamic>> newsList = [
    {
      "title": "إعمار تطلق مشروعها الجديد 'سولير' في رأس الحكمة",
      "points": ["الموقع: الكيلو 180 رأس الحكمة", "وحدات تبدأ من غرفتين وصالة", "نظام سداد يصل لـ 8 سنوات"],
      "link": "whatsapp"
    },
    {
      "title": "بالم هيلز تفتح باب الحجز في 'بادية' أكتوبر",
      "points": ["أول مدينة مستدامة في مصر", "قريبة من مطار أكتوبر", "خصم خاص للدفع الكاش"],
      "link": "whatsapp"
    },
    {
      "title": "توقعات بارتفاع أسعار العقارات في التجمع بنسبة 20%",
      "points": ["بسبب زيادة الطلب على المربع الذهبي", "فرصة ذهبية للاستثمار حالياً", "تواصل معنا للمزيد"],
      "link": "whatsapp"
    },
  ];

  @override
  void initState() {
    super.initState();
    _newsScrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) { _startNewsScrolling(); });
  }

  void _startNewsScrolling() {
    _newsTimer = Timer.periodic(const Duration(milliseconds: 25), (timer) {
      if (_newsScrollController.hasClients) {
        double maxScroll = _newsScrollController.position.maxScrollExtent;
        double currentScroll = _newsScrollController.offset;
        if (currentScroll >= maxScroll) {
          _newsScrollController.jumpTo(0);
        } else {
          _newsScrollController.animateTo(currentScroll + 2.5, duration: const Duration(milliseconds: 25), curve: Curves.linear);
        }
      }
    });
  }

  @override
  void dispose() { _newsTimer?.cancel(); _newsScrollController.dispose(); super.dispose(); }

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
                  _buildProfessionalBanner(brandOrange),
                  _buildNewsTicker(brandOrange),
                  _buildSectionTitle("السوق العقاري", electricBlue),
                  CarouselSlider(
                    options: CarouselOptions(height: 180.0, autoPlay: true, enlargeCenterPage: true, viewportFraction: 0.8),
                    items: [
                      {"title": "المطورين العقاريين", "img": "https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=600"},
                      {"title": "MASTER PLAN", "img": "https://images.unsplash.com/photo-1503387762-592dea58db2e?w=600"},
                    ].map((item) => _buildImageCard(context, item['title']!, item['img']!)).toList(),
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
  void _showNewsDetails(BuildContext context, Map<String, dynamic> news, Color orange) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(border: Border(top: BorderSide(color: orange.withOpacity(0.5), width: 2)), borderRadius: const BorderRadius.vertical(top: Radius.circular(30))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(news['title'], style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ... (news['points'] as List).map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(Icons.bolt, color: orange, size: 20), 
                    const SizedBox(width: 10), 
                    Expanded(child: Text(p, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4)))
                  ]),
              )).toList(),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: orange, minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                onPressed: () => Navigator.pop(context),
                child: const Text("مناقشة الخبر على واتساب", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 15),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNewsTicker(Color orange) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10), height: 45,
      decoration: BoxDecoration(color: orange.withOpacity(0.05), border: Border(top: BorderSide(color: orange.withOpacity(0.2)), bottom: BorderSide(color: orange.withOpacity(0.2)))),
      child: Row(children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 15), color: orange, alignment: Alignment.center,
          child: const Text("حصل إيه؟ ⚡", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
        Expanded(child: ListView.builder(controller: _newsScrollController, scrollDirection: Axis.horizontal, itemCount: newsList.length * 100,
          itemBuilder: (context, index) {
            final newsItem = newsList[index % newsList.length];
            return GestureDetector(
              onTap: () => _showNewsDetails(context, newsItem, orange),
              child: Container(padding: const EdgeInsets.symmetric(horizontal: 20), alignment: Alignment.center,
                child: Row(children: [Text(newsItem['title'], style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)), const SizedBox(width: 15), Text("•", style: TextStyle(color: orange, fontSize: 20))])),
            );
          },
        )),
      ]),
    );
  }

  Widget _buildProfessionalBanner(Color color) {
    return Container(
      margin: const EdgeInsets.all(25), padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), color: const Color(0xFF1E293B), border: Border.all(color: color.withOpacity(0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("طاب يومك بكل خير", style: TextStyle(color: Colors.white60, fontSize: 14)), Text(userName, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900))]),
          CircleAvatar(backgroundColor: color.withOpacity(0.2), radius: 25, child: Icon(Icons.auto_awesome, color: color, size: 28)),
        ]),
        const SizedBox(height: 20),
        const Text("النهاردة يوم جميل.. استعد لإنجاز كبير! ✨", style: TextStyle(color: Colors.amberAccent, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Container(padding: const EdgeInsets.all(18), width: double.infinity, decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(getSuggestionHeader(), style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 10),
            Text(getSuggestionBody(), style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildLogoWithPlayButton(Color triangleColor) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Stack(alignment: Alignment.center, children: [
        const Text("L", style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
        Positioned(left: 11, bottom: 20, child: CustomPaint(size: const Size(9, 9), painter: TrianglePainter(color: triangleColor))),
      ]),
      const Text("Pro", style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
    ]);
  }

  Widget _buildSectionTitle(String title, Color accent) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 25),
      child: Row(children: [Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)), const SizedBox(width: 12), Container(height: 4, width: 30, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(10)))]));
  }

  Widget _buildWideActionCard(BuildContext context, String title, String img, Color accent) {
    return GestureDetector(
      onTap: () { 
        if (title == "الدوري العقاري") Navigator.push(context, MaterialPageRoute(builder: (context) => const RealEstateLeague()));
        if (title == "نشط ذهنك") Navigator.push(context, MaterialPageRoute(builder: (context) => const QuizScreen()));
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 12), height: 110,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28), 
          image: DecorationImage(image: NetworkImage(img), fit: BoxFit.cover, colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.darken)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Container(
          padding: const EdgeInsets.all(20), decoration: BoxDecoration(borderRadius: BorderRadius.circular(28), gradient: LinearGradient(colors: [Colors.black.withOpacity(0.85), Colors.transparent])),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22)), Icon(Icons.play_circle_fill_rounded, color: accent, size: 45)]),
        ),
      ),
    );
  }

  Widget _buildImageCard(BuildContext context, String title, String imageUrl) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(25), image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))]),
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(25), gradient: LinearGradient(begin: Alignment.bottomCenter, colors: [Colors.black.withOpacity(0.9), Colors.transparent])),
        child: Center(child: Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
      ),
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

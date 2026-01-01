import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

// استيراد الشاشات المطلوبة
import 'quiz_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final Color deepTeal = const Color(0xFF1B4D57);
  final Color safetyOrange = const Color(0xFFE67E22);
  final User? user = FirebaseAuth.instance.currentUser;

  late AnimationController _newsController;
  late Animation<Offset> _newsAnimation;

  final List<String> friendlyPrompts = [
    "لو فيك دماغ، بص بصة على خريطة 'بيت الوطن' وقارنها بمدينتي.. المعلومة دي سلاحك الجاي! 🏗️",
    "إيه رأيك تراجع مشروعين النهاردة؟ بجد هيفرقوا جداً في طريقتك وأنت بتشرح للعميل. ✨",
    "لو فضيت شوية، ألقي نظرة على تطورات العاصمة.. فيها فرص لو عرفتها هتسبق الكل! 🚀",
    "بيني وبينك.. مراجعة 'الماستر بلان' النهاردة هتخليك وحش في الميتنج الجاي! 💪",
    "لو جالك مزاج، شوف الفرق بين أسعار التجمع وزايد النهاردة.. خليك دايماً سابق بخطوة. 🗺️",
  ];

  late String currentPrompt;

  @override
  void initState() {
    super.initState();
    _newsController =
        AnimationController(duration: const Duration(seconds: 15), vsync: this)
          ..repeat();
    _newsAnimation =
        Tween<Offset>(begin: const Offset(1.5, 0), end: const Offset(-1.5, 0))
            .animate(_newsController);
    currentPrompt = friendlyPrompts[Random().nextInt(friendlyPrompts.length)];
  }

  @override
  void dispose() {
    _newsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F8),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          String name = (snapshot.data?.data() as Map?)?['name'] ?? "بطل Pro";

          return Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              children: [
                _buildUltraSlimTicker(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 25),
                        _buildHeader(name),
                        const SizedBox(height: 25),
                        _buildQuickFact(),
                        const SizedBox(height: 15),
                        _buildFriendlyEncouragement(),
                        const SizedBox(height: 35),
                        Text(
                          "من يملك المعلومة.. يملك القوة",
                          style: GoogleFonts.cairo(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              color: deepTeal,
                              letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 15),
                        _buildPremiumGrid(),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUltraSlimTicker() {
    return Container(
      height: 28,
      width: double.infinity,
      color: safetyOrange,
      child: SlideTransition(
        position: _newsAnimation,
        child: Center(
          child: Text(
            "⚡ آخر تحديثات السوق: ارتفاع الطلب على التجمع الخامس.. معلومة تهمك!",
            style: GoogleFonts.cairo(
                color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String name) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("أهلاً بك يا $name ✨",
            style: GoogleFonts.cairo(
                fontSize: 24, fontWeight: FontWeight.w900, color: deepTeal)),
        Text("خطوة جديدة اليوم لتعزيز مكانتك كخبير في السوق..",
            style: GoogleFonts.cairo(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildQuickFact() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.withOpacity(0.15))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Text("معلومة في السريع",
                  style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: safetyOrange)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
              "المستشار العقاري الناجح لا يبيع وحدات، بل يبيع 'مستقبلاً آمناً' بناءً على أرقام دقيقة.",
              style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: Colors.black87,
                  height: 1.5,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildFriendlyEncouragement() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [deepTeal, const Color(0xFF2C5F6A)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
                color: deepTeal.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8))
          ]),
      child: Row(
        children: [
          const Icon(Icons.forum_outlined, color: Colors.amber, size: 28),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("بيني وبينك.. ✨",
                    style: GoogleFonts.cairo(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(currentPrompt,
                    style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 15,
      crossAxisSpacing: 15,
      childAspectRatio: 0.82, // تعديل بسيط ليعطي مساحة أكبر للنص بالأسفل
      children: [
        _buildImageCard(
            "دوري النجوم", "Fresh ✨", const Color(0xFF3498DB), "stars.png", () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (c) =>
                      const QuizScreen(categoryTitle: "دوري النجوم")));
        }),
        _buildImageCard(
            "دوري المحترفين", "Pro 🔥", const Color(0xFFE67E22), "pro.png", () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (c) =>
                      const QuizScreen(categoryTitle: "دوري المحترفين")));
        }),
        _buildImageCard(
            "المعلومة بتفرق", "Data 💡", const Color(0xFF1ABC9C), "info.png",
            () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (c) =>
                      const QuizScreen(categoryTitle: "المعلومة بتفرق")));
        }),
        _buildImageCard(
            "الماستر بلان", "Maps 🗺️", const Color(0xFFE74C3C), "map.png", () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (c) =>
                      const QuizScreen(categoryTitle: "الماستر بلان")));
        }),
      ],
    );
  }

  Widget _buildImageCard(String title, String badge, Color color,
      String imageName, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          image: DecorationImage(
              image: AssetImage("assets/card_images/$imageName"),
              fit: BoxFit.cover),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4))
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.85)
                ] // زيادة التظليل قليلاً
                ),
          ),
          padding: const EdgeInsets.only(
              right: 15,
              left: 15,
              bottom: 20,
              top: 15), // زيادة الـ bottom لرفع النص مسافة صغيرة
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(8)),
                child: Text(badge,
                    style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900)),
              ),
              const SizedBox(
                  height: 12), // زيادة المسافة بين البادج والعنوان كما طلبت
              Text(title,
                  style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      height: 1.1)),
            ],
          ),
        ),
      ),
    );
  }
}

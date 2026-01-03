import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'dart:ui';

import 'quiz_screen.dart';
import 'master_plan_screen.dart';
import 'admin_panel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final Color deepTeal = const Color(0xFF1B4D57);
  final Color lightTeal = const Color(0xFF4FA8A8);
  final Color safetyOrange = const Color(0xFFE67E22);
  final User? user = FirebaseAuth.instance.currentUser;

  late AnimationController _newsController;
  late Animation<Offset> _newsAnimation;

  @override
  void initState() {
    super.initState();

    // 1. إعداد متحكم الأنميشن
    _newsController = AnimationController(
      duration: const Duration(seconds: 35), // مدة مناسبة للنص الطويل
      vsync: this,
    )..repeat();

    // 2. إصلاح الخطأ البرمجي: ربط Tween مباشرة بـ CurvedAnimation
    _newsAnimation = Tween<Offset>(
      begin: const Offset(1.5, 0),
      end: const Offset(-2.5, 0),
    ).animate(CurvedAnimation(
      parent: _newsController,
      curve: Curves.linear,
    ));
  }

  @override
  void dispose() {
    _newsController.dispose();
    super.dispose();
  }

  String getDailyFact() {
    int day = DateTime.now().weekday;
    switch (day) {
      case DateTime.sunday:
        return "العقار هو الملاذ الآمن تاريخياً ضد التضخم. خليك شغوف وراجع اليوم مشروعين في التجمع بالتفصيل.. القادم أجمل!";
      case DateTime.monday:
        return "المستشار الناجح يبيع مستقبلاً آمناً بناءً على أرقام دقيقة. حاول اليوم تحليل أسعار المتر في منطقة النرجس.. أنت مبدع!";
      case DateTime.tuesday:
        return "العلاقة مع العميل تبدأ بعد البيع وليس قبله. تواصل اليوم مع عميل سابق للاطمئنان على استثماره.. التطور يبدأ بخطوة!";
      case DateTime.wednesday:
        return "الموقع هو قاعدة الذهب في الاستثمار. ارسم اليوم خريطة ذهنية لأهم 5 مناطق واعدة في العاصمة الإدارية.. أنت بطل!";
      default:
        return "المعلومة هي العملة الأغلى في سوق العقارات. استمر في التعلم، واليوم ابحث عن إحصائيات الطلب في زايد الجديدة.. نجاحك مضمون!";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F8),
      floatingActionButton: user?.email == "admin@lpro.com"
          ? FloatingActionButton(
              backgroundColor: deepTeal,
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (c) => const AdminPanel())),
              child:
                  const Icon(Icons.admin_panel_settings, color: Colors.white),
            )
          : null,
      body: Directionality(
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
                    const SizedBox(height: 20),
                    _buildUserGreetingStream(),
                    const SizedBox(height: 25),
                    _buildGlassQuickFact(),
                    const SizedBox(height: 25),
                    Center(
                      child: Text("من يملك المعلومة.. يملك القوة",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: deepTeal)),
                    ),
                    const SizedBox(height: 15),
                    _buildLProGrid(),
                    const SizedBox(height: 20),
                    _buildFriendlyEncouragement(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- شريط الأخبار المطور (توزيع الجمل الثابتة بين الأخبار) ---
  Widget _buildUltraSlimTicker() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('news').snapshots(),
      builder: (context, snapshot) {
        List<String> dbNews = [];
        if (snapshot.hasData) {
          dbNews = snapshot.data!.docs
              .map((doc) => doc['content'].toString())
              .toList();
        }

        List<String> fixedPhrases = [
          "تعلم مستمر.. تطور كبير.. نجاح اكيد 💪",
          "أبطال برو.. القمة هي مكاننا الطبيعي ✨",
          "استثمر في نفسك.. المعلومة هي القوة 🚀"
        ];

        List<String> combinedList = [];
        int phraseIndex = 0;

        // دمج الأخبار مع الجمل الثابتة كفواصل (كل خبرين جملة)
        for (int i = 0; i < dbNews.length; i++) {
          combinedList.add("⚡ ${dbNews[i]}");
          if ((i + 1) % 2 == 0) {
            combinedList
                .add("🌟 ${fixedPhrases[phraseIndex % fixedPhrases.length]}");
            phraseIndex++;
          }
        }

        String finalTickerText = combinedList.isNotEmpty
            ? combinedList.join(" | ")
            : fixedPhrases.join(" | ");

        return Container(
          height: 30,
          width: double.infinity,
          color: safetyOrange,
          child: ClipRect(
            // لضمان عدم خروج النص عن حدود الحاوية
            child: SlideTransition(
              position: _newsAnimation,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  finalTickerText,
                  style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                  overflow: TextOverflow.visible,
                  softWrap: false,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserGreetingStream() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        String name = "بطل برو";
        if (snapshot.hasData && snapshot.data!.exists) {
          name = snapshot.data!['name'] ?? "بطل برو";
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("أهلاً بك، $name ✨",
                style: GoogleFonts.cairo(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: deepTeal)),
            Row(
              children: [
                _mottoText("تعلم مستمر"),
                _arrowIcon(),
                _mottoText("تطور كبير"),
                _arrowIcon(),
                _mottoText("نجاح اكيد"),
                const SizedBox(width: 4),
                const Text("💪", style: TextStyle(fontSize: 14)),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildLProGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 15,
      crossAxisSpacing: 15,
      childAspectRatio: 1.1,
      children: [
        _buildPremiumAnimatedCard(
            "دوري النجوم",
            "Fresh ✨",
            const Color(0xFF3498DB),
            CustomPaint(
                size: const Size(55, 60),
                painter: PremiumTrophyPainter(safetyOrange)),
            "دوري النجوم",
            true,
            isQuiz: true),
        _buildPremiumAnimatedCard(
            "دوري المحترفين",
            "Pro 🔥",
            safetyOrange,
            CustomPaint(
                size: const Size(55, 70),
                painter: PremiumMedalPainter(safetyOrange)),
            "دوري المحترفين",
            true,
            isQuiz: true),
        _buildPremiumAnimatedCard(
            "المعلومة بتفرق",
            "",
            Colors.transparent,
            CustomPaint(
                size: const Size(70, 70),
                painter: PaperAndPenPainter(lightTeal, safetyOrange)),
            "المعلومة بتفرق",
            false,
            isQuiz: false),
        _buildPremiumAnimatedCard(
            "اعرف عميلك",
            "",
            Colors.transparent,
            CustomPaint(
                size: const Size(55, 55),
                painter: DeepHollowQuestionPainter(lightTeal, safetyOrange)),
            "اعرف عميلك",
            false,
            isQuiz: false,
            isMasterPlan: true),
      ],
    );
  }

  Widget _buildPremiumAnimatedCard(String title, String badge, Color badgeColor,
      Widget icon, String category, bool showBadge,
      {required bool isQuiz, bool isMasterPlan = false}) {
    return _AnimatedPremiumCard(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (c) => isMasterPlan
                  ? const MasterPlanScreen()
                  : QuizScreen(categoryTitle: category, isTopicMode: !isQuiz))),
      child: Stack(
        children: [
          if (showBadge)
            Positioned(
                top: 8,
                right: -25,
                child: Transform.rotate(
                    angle: 0.5,
                    child: Container(
                        width: 120,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(color: badgeColor),
                        child: Center(
                            child: Text(badge,
                                style: GoogleFonts.cairo(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900)))))),
          Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                icon,
                const SizedBox(height: 12),
                Text(title,
                    style: GoogleFonts.cairo(
                        color: deepTeal,
                        fontSize: 13,
                        fontWeight: FontWeight.w900))
              ])),
        ],
      ),
    );
  }

  Widget _mottoText(String text) => Text(text,
      style: GoogleFonts.cairo(
          fontSize: 12, color: safetyOrange, fontWeight: FontWeight.w800));
  Widget _arrowIcon() => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Transform.flip(
          flipX: true,
          child: Icon(Icons.play_arrow_rounded, color: lightTeal, size: 18)));

  Widget _buildGlassQuickFact() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(15),
              border:
                  Border.all(color: safetyOrange.withOpacity(0.2), width: 1.5)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.lightbulb_outline, color: deepTeal, size: 20),
              const SizedBox(width: 8),
              Text("معلومة في السريع",
                  style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: deepTeal))
            ]),
            const SizedBox(height: 8),
            Text(getDailyFact(),
                style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    height: 1.5)),
          ]),
        ),
      ),
    );
  }

  Widget _buildFriendlyEncouragement() => Container(
      padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 15),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _engWord("Success"),
        _orangeArrow(),
        _engWord("Growth"),
        _orangeArrow(),
        _engWord("Learn")
      ]));
  Widget _engWord(String text) => Text(text,
      style: GoogleFonts.cairo(
          color: lightTeal, fontSize: 16, fontWeight: FontWeight.w900));
  Widget _orangeArrow() => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Icon(Icons.play_arrow_rounded, color: safetyOrange, size: 22));
}

class _AnimatedPremiumCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _AnimatedPremiumCard({required this.child, required this.onTap});
  @override
  State<_AnimatedPremiumCard> createState() => _AnimatedPremiumCardState();
}

class _AnimatedPremiumCardState extends State<_AnimatedPremiumCard> {
  double _scale = 1.0;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 1.02),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 150),
          child: Container(
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 6))
                  ]),
              child: widget.child)),
    );
  }
}

// الرسامين CustomPainters
class PremiumTrophyPainter extends CustomPainter {
  final Color orange;
  PremiumTrophyPainter(this.orange);
  @override
  void paint(Canvas canvas, Size size) {
    double w = size.width;
    double h = size.height;
    final paint = Paint()
      ..color = const Color(0xFF388E8E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    final orangePaint = Paint()
      ..color = orange.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    Path cup = Path()
      ..moveTo(w * 0.3, h * 0.18)
      ..lineTo(w * 0.7, h * 0.18)
      ..quadraticBezierTo(w * 0.7, h * 0.45, w * 0.5, h * 0.55)
      ..quadraticBezierTo(w * 0.3, h * 0.45, w * 0.3, h * 0.18);
    canvas.drawPath(cup, paint);
    canvas.drawLine(
        Offset(w * 0.45, h * 0.22), Offset(w * 0.52, h * 0.4), orangePaint);
    canvas.drawLine(
        Offset(w * 0.52, h * 0.22), Offset(w * 0.58, h * 0.35), orangePaint);
    canvas.drawArc(Rect.fromLTWH(w * 0.18, h * 0.2, w * 0.15, h * 0.15), 1.5,
        3.14, false, paint);
    canvas.drawArc(Rect.fromLTWH(w * 0.67, h * 0.2, w * 0.15, h * 0.15), -1.5,
        3.14, false, paint);
    canvas.drawLine(
        Offset(w * 0.5, h * 0.55), Offset(w * 0.5, h * 0.65), paint);
    canvas.drawRect(
        Rect.fromCenter(
            center: Offset(w * 0.5, h * 0.7),
            width: w * 0.35,
            height: h * 0.08),
        paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PremiumMedalPainter extends CustomPainter {
  final Color orange;
  PremiumMedalPainter(this.orange);
  @override
  void paint(Canvas canvas, Size size) {
    double w = size.width;
    double h = size.height;
    final paint = Paint()
      ..color = const Color(0xFF388E8E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    final orangePaint = Paint()
      ..color = orange.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    Rect rect = Rect.fromLTWH(w * 0.4, 0, w * 0.2, h * 0.4);
    canvas.drawRect(rect, paint);
    canvas.drawLine(
        Offset(w * 0.42, h * 0.1), Offset(w * 0.5, h * 0.3), orangePaint);
    canvas.drawLine(
        Offset(w * 0.5, h * 0.1), Offset(w * 0.58, h * 0.3), orangePaint);
    canvas.drawCircle(Offset(w * 0.5, h * 0.65), w * 0.25, paint);
    canvas.drawCircle(Offset(w * 0.5, h * 0.65), w * 0.15, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DeepHollowQuestionPainter extends CustomPainter {
  final Color themeColor;
  final Color dotColor;
  DeepHollowQuestionPainter(this.themeColor, this.dotColor);
  @override
  void paint(Canvas canvas, Size size) {
    double w = size.width;
    double h = size.height;
    final paint = Paint()
      ..color = themeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    Path pathOuter = Path()
      ..moveTo(w * 0.3, h * 0.35)
      ..quadraticBezierTo(w * 0.35, h * 0.1, w * 0.65, h * 0.2)
      ..quadraticBezierTo(w * 0.75, h * 0.45, w * 0.55, h * 0.5)
      ..lineTo(w * 0.55, h * 0.6);
    Path pathInner = Path()
      ..moveTo(w * 0.4, h * 0.35)
      ..quadraticBezierTo(w * 0.45, h * 0.18, w * 0.6, h * 0.25)
      ..quadraticBezierTo(w * 0.65, h * 0.4, w * 0.45, h * 0.5)
      ..lineTo(w * 0.45, h * 0.6);
    canvas.drawPath(pathOuter, paint);
    canvas.drawPath(pathInner, paint);
    canvas.drawCircle(
        Offset(w * 0.5, h * 0.75), 4.5, Paint()..color = dotColor);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PaperAndPenPainter extends CustomPainter {
  final Color themeColor;
  final Color orangeLine;
  PaperAndPenPainter(this.themeColor, this.orangeLine);
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final paint = Paint()
      ..color = themeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    final linePaint = Paint()
      ..color = orangeLine.withOpacity(0.4)
      ..strokeWidth = 1.2;
    Rect paperRect = Rect.fromCenter(
        center: Offset(w * 0.38, h * 0.5), width: w * 0.4, height: h * 0.6);
    canvas.drawRRect(
        RRect.fromRectAndRadius(paperRect, const Radius.circular(4)), paint);
    for (int i = 1; i <= 3; i++) {
      double y = paperRect.top + (paperRect.height * 0.25 * i);
      canvas.drawLine(Offset(paperRect.left + 5, y),
          Offset(paperRect.right - 5, y), linePaint);
    }
    double penX = w * 0.75;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(penX, h * 0.25, w * 0.08, h * 0.35),
            const Radius.circular(2)),
        paint);
    Path nib = Path()
      ..moveTo(penX, h * 0.6)
      ..lineTo(penX + w * 0.04, h * 0.68)
      ..lineTo(penX + w * 0.08, h * 0.6)
      ..close();
    canvas.drawPath(nib, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

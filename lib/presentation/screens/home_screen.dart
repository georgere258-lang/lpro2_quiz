import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';
import '../../core/constants/app_colors.dart';
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
  final Color deepTeal = AppColors.primaryDeepTeal;
  final Color lightTeal = const Color(0xFF4FA8A8);
  final Color safetyOrange = AppColors.secondaryOrange;
  final Color turquoiseCyan = const Color(0xFF00CED1);
  final User? user = FirebaseAuth.instance.currentUser;

  late AnimationController _newsController;
  late Animation<Offset> _newsAnimation;

  @override
  void initState() {
    super.initState();
    _newsController =
        AnimationController(duration: const Duration(seconds: 35), vsync: this)
          ..repeat();
    _newsAnimation = Tween<Offset>(
      begin: const Offset(1.8, 0),
      end: const Offset(-2.8, 0),
    ).animate(CurvedAnimation(parent: _newsController, curve: Curves.linear));
  }

  @override
  void dispose() {
    _newsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            _buildEdgeToEdgeTicker(),
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
                    const SizedBox(height: 35),
                    Center(
                        child: Text("من يملك المعلومة.. يملك القوة",
                            style: GoogleFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: deepTeal))),
                    const SizedBox(height: 15),
                    _buildLProGrid(),
                    const SizedBox(height: 50),
                    _buildModernEncouragement(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEdgeToEdgeTicker() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('news').snapshots(),
      builder: (context, snapshot) {
        String arMotto = "⚡ تعلم مستمر.. تطور كبير.. نجاح اكيد 💪";
        String enMotto = "⚡ LEARN.. GROWTH.. SUCCESS 🚀";
        List<String> combinedList = [];
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          var newsItems =
              snapshot.data!.docs.map((doc) => "⚡ ${doc['content']}").toList();
          if (newsItems.length == 1) {
            combinedList = [arMotto, newsItems[0], enMotto];
          } else {
            for (int i = 0; i < newsItems.length; i++) {
              combinedList.add(newsItems[i]);
              if (i == 1) combinedList.add(arMotto);
              if (i == 3) combinedList.add(enMotto);
            }
          }
        } else {
          combinedList = [arMotto, enMotto];
        }
        return Container(
          height: 32,
          width: double.infinity,
          color: safetyOrange,
          alignment: Alignment.center,
          child: ClipRect(
            child: SlideTransition(
              position: _newsAnimation,
              child: Text(combinedList.join("      "),
                  style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold),
                  softWrap: false),
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
        String name = "عضو L Pro";
        if (snapshot.hasData && snapshot.data!.exists)
          name = snapshot.data!['name'] ?? "عضو L Pro";
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
                _miniMotto("تعلم مستمر"),
                _customHandDrawnArrow(), // سهم مرسوم يدوياً لليسار
                _miniMotto("تطور كبير"),
                _customHandDrawnArrow(), // سهم مرسوم يدوياً لليسار
                _miniMotto("نجاح اكيد"),
                const Text(" 💪", style: TextStyle(fontSize: 14)),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _miniMotto(String text) => Text(text,
      style: GoogleFonts.cairo(
          fontSize: 12, color: safetyOrange, fontWeight: FontWeight.w800));

  // --- السهم الفيروزي المصمت المرسوم برمجياً لضمان الشكل المطلق ---
  Widget _customHandDrawnArrow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: CustomPaint(
        size: const Size(10, 10),
        painter: SolidTrianglePainter(turquoiseCyan),
      ),
    );
  }

  Widget _buildLProGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 20,
      crossAxisSpacing: 20,
      childAspectRatio: 1.0,
      children: [
        _buildPremiumCard(
            "دوري النجوم",
            "FRESH ✨",
            const Color(0xFF3498DB),
            CustomPaint(
                size: const Size(50, 50),
                painter: PremiumTrophyPainter(safetyOrange)),
            "دوري النجوم",
            true,
            isQuiz: true),
        _buildPremiumCard(
            "دوري المحترفين",
            "PRO 🔥",
            safetyOrange,
            CustomPaint(
                size: const Size(50, 50),
                painter: PremiumMedalPainter(safetyOrange)),
            "دوري المحترفين",
            true,
            isQuiz: true),
        _buildPremiumCard(
            "المعلومة بتفرق",
            "",
            Colors.transparent,
            CustomPaint(
                size: const Size(55, 55),
                painter: PaperAndPenPainter(lightTeal, safetyOrange)),
            "المعلومة بتفرق",
            false,
            isQuiz: false),
        _buildPremiumCard(
            "اعرف عميلك",
            "",
            Colors.transparent,
            CustomPaint(
                size: const Size(50, 50),
                painter: DeepHollowQuestionPainter(lightTeal, safetyOrange)),
            "اعرف عميلك",
            false,
            isQuiz: false,
            isMasterPlan: true),
      ],
    );
  }

  Widget _buildPremiumCard(String title, String badge, Color badgeColor,
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
        clipBehavior: Clip.none,
        children: [
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
          if (showBadge)
            Positioned(
              top: 14,
              right: -17,
              child: Transform.rotate(
                angle: 0.55,
                child: Container(
                  width: 100,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(color: badgeColor, boxShadow: [
                    BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: const Offset(0, 2))
                  ]),
                  child: Center(
                      child: Text(badge,
                          style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5))),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModernEncouragement() =>
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _engWord("Learn"),
        _customHandDrawnArrowEn(),
        _engWord("Growth"),
        _customHandDrawnArrowEn(),
        _engWord("Success")
      ]);
  Widget _engWord(String text) => Text(text,
      style: GoogleFonts.cairo(
          color: lightTeal, fontSize: 15, fontWeight: FontWeight.w900));

  Widget _customHandDrawnArrowEn() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: CustomPaint(
          size: const Size(12, 12),
          painter: SolidTrianglePainter(turquoiseCyan, isLeft: false)),
    );
  }

  Widget _buildGlassQuickFact() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(15),
              border:
                  Border.all(color: safetyOrange.withOpacity(0.1), width: 1.5)),
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
            const SizedBox(height: 10),
            Text(getDailyFact(),
                style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    height: 1.6)),
          ]),
        ),
      ),
    );
  }

  String getDailyFact() {
    int day = DateTime.now().weekday;
    switch (day) {
      case DateTime.sunday:
        return "العقار هو الملاذ الآمن تاريخياً ضد التضخم. خليك شغوف وراجع اليوم مشروعين بالتفصيل.. القادم أجمل!";
      case DateTime.monday:
        return "المستشار الناجح يبيع مستقبلاً آمناً بناءً على أرقام دقيقة. حلل اليوم أسعار المتر في منطقتك.. أنت مبدع!";
      case DateTime.tuesday:
        return "العلاقة مع العميل تبدأ بعد البيع وليس قبله. تواصل اليوم مع عميل سابق.. التطور يبدأ بخطوة!";
      default:
        return "المعلومة هي العملة الأغلى في سوق العقارات. استمر في التعلم، نجاحك مضمون!";
    }
  }
}

// --- كلاس رسم السهم (المثلث) بدقة ---
class SolidTrianglePainter extends CustomPainter {
  final Color color;
  final bool isLeft;
  SolidTrianglePainter(this.color, {this.isLeft = true});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path();
    if (isLeft) {
      path.moveTo(size.width, 0);
      path.lineTo(0, size.height / 2);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, 0);
      path.lineTo(size.width, size.height / 2);
      path.lineTo(0, size.height);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
      onTapDown: (_) => setState(() => _scale = 0.96),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 100),
          child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 6))
                  ]),
              child: widget.child)),
    );
  }
}

// الرسامين Painters - تبقى بدون تغيير
class PremiumTrophyPainter extends CustomPainter {
  final Color orange;
  PremiumTrophyPainter(this.orange);
  @override
  void paint(Canvas canvas, Size size) {
    double w = size.width, h = size.height;
    final paint = Paint()
      ..color = const Color(0xFF388E8E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    Path cup = Path()
      ..moveTo(w * 0.3, h * 0.2)
      ..lineTo(w * 0.7, h * 0.2)
      ..quadraticBezierTo(w * 0.7, h * 0.45, w * 0.5, h * 0.55)
      ..quadraticBezierTo(w * 0.3, h * 0.45, w * 0.3, h * 0.2);
    canvas.drawPath(cup, paint);
    canvas.drawLine(
        Offset(w * 0.5, h * 0.55), Offset(w * 0.5, h * 0.75), paint);
    canvas.drawRect(
        Rect.fromCenter(
            center: Offset(w * 0.5, h * 0.8), width: w * 0.4, height: h * 0.1),
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
    double w = size.width, h = size.height;
    final paint = Paint()
      ..color = const Color(0xFF388E8E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRect(Rect.fromLTWH(w * 0.4, 0, w * 0.2, h * 0.45), paint);
    canvas.drawCircle(Offset(w * 0.5, h * 0.7), w * 0.28, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DeepHollowQuestionPainter extends CustomPainter {
  final Color themeColor, dotColor;
  DeepHollowQuestionPainter(this.themeColor, this.dotColor);
  @override
  void paint(Canvas canvas, Size size) {
    double w = size.width, h = size.height;
    final paint = Paint()
      ..color = themeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    Path qPath = Path()
      ..moveTo(w * 0.3, h * 0.4)
      ..quadraticBezierTo(w * 0.35, h * 0.1, w * 0.65, h * 0.2)
      ..quadraticBezierTo(w * 0.75, h * 0.45, w * 0.55, h * 0.5)
      ..lineTo(w * 0.55, h * 0.65);
    canvas.drawPath(qPath, paint);
    canvas.drawCircle(
        Offset(w * 0.55, h * 0.8), 4.5, Paint()..color = dotColor);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PaperAndPenPainter extends CustomPainter {
  final Color themeColor, orangeLine;
  PaperAndPenPainter(this.themeColor, this.orangeLine);
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width, h = size.height;
    final paint = Paint()
      ..color = themeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    Rect paper = Rect.fromCenter(
        center: Offset(w * 0.4, h * 0.5), width: w * 0.45, height: h * 0.65);
    canvas.drawRRect(
        RRect.fromRectAndRadius(paper, const Radius.circular(4)), paint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.78, h * 0.25, w * 0.1, h * 0.4),
            const Radius.circular(2)),
        paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

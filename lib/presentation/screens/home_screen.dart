import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';

import '../../core/constants/app_colors.dart';
import 'quiz_screen.dart';
import 'master_plan_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final Color deepTeal = AppColors.primaryDeepTeal;
  final Color safetyOrange = AppColors.secondaryOrange;
  final Color lightTeal = const Color(0xFF4FA8A8);
  final Color turquoiseCyan = const Color(0xFF00CED1);
  final User? user = FirebaseAuth.instance.currentUser;

  late AnimationController _newsController;
  late Animation<Offset> _newsAnimation;

  final List<String> dailyTips = [
    "العقارات هي الملاذ الآمن تاريخياً ضد التضخم. راجع اليوم مشروعين بالتفصيل.. القادم أجمل! 🏠",
    "تحديد احتياج العميل بدقة يوفر 70% من مجهود الإقناع. اسمع أكثر مما تتكلم اليوم.. أنت مستشار محترف! 🤝",
    "الموقع هو العامل الأول in تقييم سعر إعادة البيع. ادرس اليوم خارطة الطرق الجديدة.. ذكاؤك هو رأس مالك! 📍",
    "الثقة هي العملة الحقيقية في سوق العقارات. اتصل بعميل سابق للاطمئنان عليه فقط.. الأمانة تبني إمبراطوريات! 💎",
    "الاستثمار في العقار التجاري يتطلب حساب العائد الإيجاري (ROI) بدقة. حلل اليوم أرقام منطقة حيوية.. أنت مبدع! 📊",
    "العميل لا يشتري جدراناً، بل يشتري مستقبلاً. ركز اليوم على قصة المكان وليس فقط المواصفات.. أبدع في وصفك! ✨",
    "العقار يمرض ولا يموت. ذكر عملاءك اليوم بقيمة الاستثمار طويل الأمد.. الصبر مفتاح الأرباح! 🔑",
    "المتابعة (Follow-up) هي سر إغلاق الصفقة. راجع اليوم قائمة عملائك المهتمين.. النجاح يطرق باب المثابرين! 🚀",
    "أسعار الفائدة تؤثر مباشرة على القوة الشرائية. تابع اليوم تحديثات البنك المركزي.. كن خبيراً يثق به الناس! 📈",
    "المساحات الصغيرة (Studios) هي الأكثر طلباً للإيجار حالياً. ابحث اليوم عن وحدات مميزة بهذا النمط.. اصطاد الفرص! 🏗️",
    "المعرفة بالقوانين العقارية تحميك وتحمي عميلك. اقرأ اليوم مادة واحدة من قانون التمويل.. حمايتك للعميل فخر! ⚖️",
    "أول 7 ثوانٍ في المكالمة تحدد انطباع العميل عنك. تدرب اليوم على نبرة صوت واثقة.. أنت واجهة النجاح! 📞",
    "التنوع في المحفظة العقارية يقلل المخاطر. اقترح اليوم على مستثمريك مناطق جديدة واعدة.. رؤيتك تصنع الفارق! 🌍",
    "العقارات تحت الإنشاء (Off-plan) توفر أعلى ربحية عند الاستلام. ادرس جداول الاستلام لعام 2026.. خطط للمستقبل! 🏗️",
    "الصدق في عيوب الوحدة قبل ميزاتها يبني ولاءً أبدياً. كن شفافاً اليوم في كل معلومة.. نزاهتك هي علامتك التجارية! 🤝",
    "السوق العقاري موسمي بطبعه. استعد اليوم لموسم الإجازات بخطة تسويق ذكية.. كن دائماً خطوة للأمام! 📅",
    "التشطيب الراقي يرفع قيمة العقار بنسبة تصل لـ 20%. قارن اليوم بين أسعار نصف التشطيب والكامل.. عينك خبيرة! 🎨",
    "لغة الجسد في المعاينات تعطي رسائل أقوى من الكلام. حافظ اليوم على تواصل بصري واثق.. الحضور هو نصف البيعة! 👔",
    "الأحياء القريبة من الجامعات والمستشفيات هي الأعلى استدامة إيجارية. ابحث عن هذه النقاط اليوم.. تفكيرك استراتيجي! 🏫",
    "السعر العادل هو الذي يرضي البائع ويجذب المشتري. قم اليوم بعمل مقارنة أسعار (CMA) دقيقة.. أنت ضابط الإيقاع! ⚖️",
    "الرقمنة (PropTech) هي مستقبل المهنة. جرب اليوم تطبيقاً جديداً للتنظيم أو التصوير.. واكب التطور! 📱",
    "العميل المتردد يحتاج لـ خبير وليس لـ بائع. قدم اليوم تحليلاً اقتصادياً بدل الضغط للبيع.. أنت مستشار حقيقي! 🧠",
    "البيوت الذكية (Smart Homes) تزيد من سرعة البيع. ابرز هذه الميزات في عرضك اليوم.. التكنولوجيا هي لغة العصر! 🏠",
    "الاستثمار في نفسك هو أفضل استثمار عقاري. خصص اليوم 15 دقيقة لتعلم مهارة تفاوض جديدة.. نموك لا يتوقف! 📚",
    "الكلمات الإيجابية تفتح الأبواب المغلقة. ابدأ مكالماتك اليوم بابتسامة تظهر في صوتك.. طاقتك سر نجاحك! 😊",
    "المنافسة الشريفة ترفع مستوى السوق. تعلم اليوم من زميل متميز وشاركه نجاحك.. العظمة في التعاون! 🤝",
    "العائد على السعادة لا يقل عن العائد على المال. ابحث لعميلك عن بيت يحبه فعلاً.. أنت صانع أحلام! 🏡",
    "الأزمات تخلق الفرص للمستثمر الذكي. طمئن عملائك اليوم بتحليل واقعي للسوق.. كن منارة في العاصفة! ⛈️",
    "التفاصيل الصغيرة في العقد هي ما تمنع المشاكل الكبيرة. راجع بنود التعاقد بدقة اليوم.. دقة ملاحظتك تنقذ صفقات! 📝",
    "النجاح هو مجموع محاولات صغيرة تتكرر كل يوم. احتفل اليوم بإنجازاتك مهما كانت بسيطة.. أنت Pro حقيقي! 🏆",
  ];

  @override
  void initState() {
    super.initState();
    _newsController =
        AnimationController(duration: const Duration(seconds: 55), vsync: this)
          ..repeat();
    _newsAnimation =
        Tween<Offset>(begin: const Offset(2.5, 0), end: const Offset(-4.5, 0))
            .animate(
                CurvedAnimation(parent: _newsController, curve: Curves.linear));
  }

  @override
  void dispose() {
    _newsController.dispose();
    super.dispose();
  }

  String get _fallbackFact {
    int dayOfYear =
        DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    return dailyTips[dayOfYear % dailyTips.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            _buildCrystalClearTicker(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    _buildUserGreetingStream(),
                    const SizedBox(height: 15),
                    _buildDynamicInfoCard(),
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 18),
                      child: Center(
                        child: Text(
                          "من يملك المعلومة.. يملك القوة",
                          style: GoogleFonts.cairo(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w900,
                            color: deepTeal.withOpacity(0.85),
                          ),
                        ),
                      ),
                    ),
                    _buildLProGrid(),
                    const SizedBox(height: 25),
                    _buildModernEncouragement(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicInfoCard() {
    DateTime now = DateTime.now();
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('daily_tips')
          .where('isActive', isEqualTo: true)
          .where('startDate', isLessThanOrEqualTo: now)
          .orderBy('startDate', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        String factToShow = _fallbackFact;
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          var data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
          factToShow = data['content'] ?? _fallbackFact;
        }
        return InfoCardWidget(content: factToShow);
      },
    );
  }

  Widget _buildCrystalClearTicker() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('news').snapshots(),
      builder: (context, snapshot) {
        String arMotto = "⚡ تعلم مستمر.. تطور كبير.. نجاح اكيد 💪";
        String enMotto = "⚡ LEARN.. GROWTH.. SUCCESS 🚀";
        List<String> combinedList = [];
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          var newsItems =
              snapshot.data!.docs.map((doc) => "⚡ ${doc['content']}").toList();
          combinedList = [arMotto, ...newsItems, enMotto];
        } else {
          combinedList = [arMotto, enMotto];
        }
        return Container(
          height: 38,
          width: double.infinity,
          color: safetyOrange,
          alignment: Alignment.center,
          child: SlideTransition(
            position: _newsAnimation,
            child: IntrinsicWidth(
              child: Text(combinedList.join("      "),
                  style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold),
                  softWrap: false,
                  overflow: TextOverflow.visible),
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
        if (snapshot.hasData && snapshot.data!.exists) {
          name = snapshot.data!['name'] ?? "عضو L Pro";
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("أهلاً بك، $name ✨",
                style: GoogleFonts.cairo(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: deepTeal)),
            Row(children: [
              _miniMotto("تعلم مستمر"),
              _customHandDrawnArrow(),
              _miniMotto("تطور كبير"),
              _customHandDrawnArrow(),
              _miniMotto("نجاح اكيد"),
              const Text(" 💪", style: TextStyle(fontSize: 14))
            ]),
          ],
        );
      },
    );
  }

  Widget _miniMotto(String text) => Text(text,
      style: GoogleFonts.cairo(
          fontSize: 11.5, color: safetyOrange, fontWeight: FontWeight.w800));

  Widget _customHandDrawnArrow() => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: CustomPaint(
          size: const Size(11, 9),
          painter: SolidTrianglePainter(turquoiseCyan)));

  Widget _buildLProGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.15,
      children: [
        _buildPremiumCard(
            "دوري النجوم",
            "FRESH ✨",
            const Color(0xFF3498DB),
            CustomPaint(
                size: const Size(42, 42),
                painter: PremiumTrophyPainter(safetyOrange)),
            "دوري النجوم",
            true,
            isQuiz: true),
        _buildPremiumCard(
            "دوري المحترفين",
            "PRO 🔥",
            safetyOrange,
            CustomPaint(
                size: const Size(42, 42),
                painter: PremiumMedalPainter(safetyOrange)),
            "دوري المحترفين",
            true,
            isQuiz: true),
        _buildPremiumCard(
            "المعلومة بتفرق",
            "",
            Colors.transparent,
            CustomPaint(
                size: const Size(46, 46),
                painter: PaperAndPenPainter(lightTeal, safetyOrange)),
            "المعلومة بتفرق",
            false,
            isQuiz: false),
        _buildPremiumCard(
            "اعرف عميلك",
            "",
            Colors.transparent,
            CustomPaint(
                size: const Size(42, 42),
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
                const SizedBox(height: 8),
                Text(title,
                    style: GoogleFonts.cairo(
                        color: deepTeal,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900))
              ])),
          if (showBadge)
            Positioned(
              top: 10,
              right: -14,
              child: Transform.rotate(
                angle: 0.55,
                child: Container(
                  width: 90,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                      color: badgeColor,
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2))
                      ]),
                  child: Center(
                    child: Text(badge,
                        style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- تم تعديل ترتيب العناصر هنا لتظهر Learn في اليسار و Success في اليمين ---
  Widget _buildModernEncouragement() =>
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _engWord("Success"),
        _customCyanArrowEn(),
        _engWord("Growth"),
        _customCyanArrowEn(),
        _engWord("Learn"),
      ]);

  Widget _engWord(String text) => Text(text,
      style: GoogleFonts.cairo(
          color: lightTeal, fontSize: 15, fontWeight: FontWeight.w900));

  Widget _customCyanArrowEn() => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: CustomPaint(
          size: const Size(11, 11),
          painter: SolidTrianglePainter(turquoiseCyan, isLeft: false)));
}

class InfoCardWidget extends StatelessWidget {
  final String content;
  const InfoCardWidget({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 25,
              offset: const Offset(0, 10)),
        ],
        border: Border.all(
            color: AppColors.primaryDeepTeal.withOpacity(0.1), width: 1.2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryDeepTeal, Color(0xFF006D77)],
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.tips_and_updates_rounded,
                      color: AppColors.secondaryOrange, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    "معلومة L Pro",
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14.5,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Text(
                content,
                textAlign: TextAlign.right,
                style: GoogleFonts.cairo(
                  fontSize: 15,
                  height: 1.7,
                  color: const Color(0xFF2D3142),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
                child: widget.child)));
  }
}

class PremiumTrophyPainter extends CustomPainter {
  final Color orange;
  PremiumTrophyPainter(this.orange);
  @override
  void paint(Canvas canvas, Size size) {
    double w = size.width, h = size.height;
    final paint = Paint()
      ..color = const Color(0xFF388E8E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.3;
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
      ..strokeWidth = 2.3;
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
      ..strokeWidth = 2.1;
    Path qPath = Path()
      ..moveTo(w * 0.3, h * 0.4)
      ..quadraticBezierTo(w * 0.35, h * 0.1, w * 0.65, h * 0.2)
      ..quadraticBezierTo(w * 0.75, h * 0.45, w * 0.55, h * 0.5)
      ..lineTo(w * 0.55, h * 0.65);
    canvas.drawPath(qPath, paint);
    canvas.drawCircle(
        Offset(w * 0.55, h * 0.8), 4.2, Paint()..color = dotColor);
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
      ..strokeWidth = 2.1;
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

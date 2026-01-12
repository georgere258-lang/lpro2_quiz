import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';

import '../../core/utils/sound_manager.dart';

import '../home/widgets/home_pro_card_container.dart';
import '../../features/news_ticker/presentation/news_ticker_widget.dart';

import 'quiz_screen.dart';
import 'master_plan_screen.dart';
import 'fact_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final User? user = FirebaseAuth.instance.currentUser;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 1. الخلفية الثابتة
          Container(color: const Color(0xFFFDFBF7)),

          // 2. الهالة الضوئية الديناميكية
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              return Positioned(
                top: -80 + (40 * _glowController.value),
                left: -80 + (80 * _glowController.value),
                child: Container(
                  width: 350,
                  height: 350,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFFF8C00).withOpacity(0.08),
                        const Color(0xFFFF8C00).withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // 3. المحتوى الرئيسي
          Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              children: [
                // شريط الأخبار الزجاجي العلوي
                SafeArea(
                  bottom: false,
                  child: ClipRRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        color: Colors.white.withOpacity(0.1),
                        child: _buildNewsTicker(),
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 15),
                        const _UserHeader(),
                        const SizedBox(height: 14),
                        HomeProCardContainer(),
                        const SizedBox(height: 25),
                        const _PowerSentence(),
                        const SizedBox(height: 20),
                        const _HomeGrid(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),

                // التذييل الثابت
                const Padding(
                  padding: EdgeInsets.only(bottom: 25, top: 10),
                  child: _EnglishMotto(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsTicker() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        String name = "Pro";
        if (snapshot.hasData && snapshot.data!.exists) {
          name =
              (snapshot.data!.data() as Map<String, dynamic>)['name'] ?? "Pro";
        }
        return NewsTickerWidget(userName: name);
      },
    );
  }
}

class _HomeGrid extends StatelessWidget {
  const _HomeGrid();
  @override
  Widget build(BuildContext context) {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 18,
        crossAxisSpacing: 18,
        childAspectRatio: 1.15,
      ),
      children: const [
        _GridCard(
          title: "دوري النجوم",
          icon: Icons.auto_awesome_rounded,
          badgeText: "FRESH",
          badgeIcon: "✨",
          badgeColor: Color(0xFF3498DB),
          target: QuizScreen(categoryTitle: "دوري النجوم"),
        ),
        _GridCard(
          title: "دوري المحترفين",
          icon: Icons.workspace_premium_rounded,
          badgeText: "PRO",
          badgeIcon: "🔥",
          badgeColor: Color(0xFFFF8C00),
          target: QuizScreen(categoryTitle: "دوري المحترفين"),
        ),
        _GridCard(
          title: "المعلومة بتفرق",
          icon: Icons.lightbulb_outline,
          target: FactScreen(),
        ),
        _GridCard(
          title: "اعرف عميلك",
          icon: Icons.groups_outlined,
          target: MasterPlanScreen(),
        ),
      ],
    );
  }
}

class _GridCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final String? badgeText;
  final String? badgeIcon;
  final Color? badgeColor;
  final Widget target;

  const _GridCard({
    required this.title,
    required this.icon,
    this.badgeText,
    this.badgeIcon,
    this.badgeColor,
    required this.target,
  });

  @override
  State<_GridCard> createState() => _GridCardState();
}

class _GridCardState extends State<_GridCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        SoundManager.playTap();
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => widget.target));
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.identity()..scale(_isPressed ? 0.96 : 1.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_isPressed ? 0.08 : 0.05),
              blurRadius: _isPressed ? 8 : 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF4FA8A8), Color(0xFF003D3D)],
                      ).createShader(bounds),
                      child: Icon(widget.icon, size: 38, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.title,
                      style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF003D3D)),
                    ),
                  ],
                ),
              ),
              if (widget.badgeText != null)
                Positioned(
                  top: 10,
                  right: -14,
                  child: Transform.rotate(
                    angle: 0.55,
                    child: Container(
                      width: 90,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.badgeColor,
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2))
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.badgeIcon != null) ...[
                            Text(widget.badgeIcon!,
                                style: const TextStyle(fontSize: 10)),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            widget.badgeText!,
                            style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/* =========================================================
   مكونات ثابتة (Header, Badge, Footer)
========================================================= */

class _UserHeader extends StatelessWidget {
  const _UserHeader();
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        String name = "عضو Pro";
        int points = 0;
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          name = data['name'] ?? name;
          points = data['points'] ?? 0;
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("أهلاً بك، $name ✨",
                    style: GoogleFonts.cairo(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF003D3D))),
                _PointsBadge(points: points),
              ],
            ),
            const SizedBox(height: 4),
            const Row(children: [
              _MiniMotto("تعلم مستمر"),
              _ArrowArabic(),
              _MiniMotto("تطور كبير"),
              _ArrowArabic(),
              _MiniMotto("نجاح أكيد 💪")
            ]),
          ],
        );
      },
    );
  }
}

class _PointsBadge extends StatelessWidget {
  final int points;
  const _PointsBadge({required this.points});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFFFF8C00).withOpacity(0.3), width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("$points",
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF003D3D),
                  fontSize: 12)),
          const SizedBox(width: 4),
          Text("نقطة",
              style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFF8C00),
                  fontSize: 10)),
        ],
      ),
    );
  }
}

class _PowerSentence extends StatelessWidget {
  const _PowerSentence();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF003D3D)),
          children: const [
            TextSpan(text: "من يملك المعلومة"),
            TextSpan(text: " • ", style: TextStyle(color: Color(0xFFFF8C00))),
            TextSpan(text: "يملك القوة"),
          ],
        ),
      ),
    );
  }
}

class _EnglishMotto extends StatelessWidget {
  const _EnglishMotto();
  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _EnglishWord("Success"),
        _ArrowEnglish(),
        _EnglishWord("Growth"),
        _ArrowEnglish(),
        _EnglishWord("Learn")
      ],
    );
  }
}

class _MiniMotto extends StatelessWidget {
  final String text;
  const _MiniMotto(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: GoogleFonts.cairo(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: const Color(0xFFFF8C00)));
  }
}

class _EnglishWord extends StatelessWidget {
  final String text;
  const _EnglishWord(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF4FA8A8)));
  }
}

class _ArrowArabic extends StatelessWidget {
  const _ArrowArabic();
  @override
  Widget build(BuildContext context) {
    return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 5),
        child: CustomPaint(
            size: Size(11, 9),
            painter: _SolidTrianglePainter(Color(0xFF4FA8A8), isLeft: true)));
  }
}

class _ArrowEnglish extends StatelessWidget {
  const _ArrowEnglish();
  @override
  Widget build(BuildContext context) {
    return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 5),
        child: CustomPaint(
            size: Size(11, 9),
            painter: _SolidTrianglePainter(Color(0xFF4FA8A8), isLeft: false)));
  }
}

class _SolidTrianglePainter extends CustomPainter {
  final Color color;
  final bool isLeft;
  const _SolidTrianglePainter(this.color, {required this.isLeft});
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
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

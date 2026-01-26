// 🔒 HOME SCREEN: ELITE DYNAMIC EDITION
// PATH: lib/presentation/screens/home_screen.dart
// STATUS: ULTRA-PREMIUM (Size Optimized & Spacing Balanced)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/utils/sound_manager.dart';
import '../../core/constants/app_colors.dart';
import '../home/widgets/home_pro_card_container.dart';

import 'quiz_screen.dart';
import 'fact_screen.dart';
import 'know_client_screen.dart';
import 'market_radar_screen.dart';
import 'money_economy_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final User? user = FirebaseAuth.instance.currentUser;
  late final AnimationController _bgController;
  late final AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat(reverse: true);

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final double bottomScrollSpacer = bottomInset + 80;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFBFBFB),
        gradient: RadialGradient(
          center: Alignment(0.7, -0.5),
          radius: 1.5,
          colors: [Color(0xFFF0F4F5), Color(0xFFFBFBFB)],
        ),
      ),
      child: Stack(
        children: [
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _bgController,
              builder: (_, __) {
                final v = _bgController.value;
                return Stack(
                  children: [
                    Positioned(
                      top: -150 + (40 * v),
                      right: -100 + (30 * v),
                      child: _blob(
                          size: 400,
                          color: const Color(0xFFFF8C00).withValues(alpha: 0.06)),
                    ),
                    Positioned(
                      bottom: -100 + (40 * v),
                      left: -50 + (20 * v),
                      child: _blob(
                          size: 450,
                          color: AppColors.primaryDeepTeal.withValues(alpha: 0.07)),
                    ),
                  ],
                );
              },
            ),
          ),
          Directionality(
            textDirection: TextDirection.rtl,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 1. كارت الترحيب
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: RepaintBoundary(child: _WelcomeCard(user: user)),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // 2. كارت معلومة برو
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: RepaintBoundary(child: HomeProCardContainer()),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // 3. شبكة الكروت الأربعة (Grid) - تم تكبير الـ mainAxisExtent
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      // ✅ تم التكبير من 110 إلى 135 ليعطي حجماً أكبر وأفخم
                      mainAxisExtent: 135,
                    ),
                    delegate: SliverChildListDelegate([
                      _SectionCard(
                        title: "دوري النجوم",
                        icon: Icons.auto_awesome_rounded,
                        accent: const Color(0xFF3498DB),
                        isHighFocus: true,
                        floatAnimation: _floatController,
                        onTap: () => _go(context,
                            const QuizScreen(categoryTitle: "دوري النجوم")),
                      ),
                      _SectionCard(
                        title: "دوري المحترفين",
                        icon: Icons.workspace_premium_rounded,
                        accent: const Color(0xFFFF8C00),
                        isHighFocus: true,
                        floatAnimation: _floatController,
                        onTap: () => _go(context,
                            const QuizScreen(categoryTitle: "دوري المحترفين")),
                      ),
                      _SectionCard(
                        title: "المعلومة بتفرق",
                        icon: Icons.lightbulb_outline,
                        accent: AppColors.secondaryOrange,
                        onTap: () => _go(context, const FactScreen()),
                      ),
                      _SectionCard(
                        title: "اعرف عميلك",
                        icon: Icons.groups_outlined,
                        accent: AppColors.primaryDeepTeal,
                        onTap: () => _go(context, const KnowClientScreen()),
                      ),
                    ]),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // 4. الكروت العريضة
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _SecondarySectionCard(
                        title: "رادار السوق",
                        icon: Icons.radar_rounded,
                        accent: const Color(0xFF2ECC71),
                        onTap: () => _go(context, const MarketRadarScreen()),
                      ),
                      const SizedBox(height: 12),
                      _SecondarySectionCard(
                        title: "اقتصاد عقاري",
                        icon: Icons.attach_money_rounded,
                        accent: const Color(0xFF9B59B6),
                        onTap: () => _go(context, const MoneyEconomyScreen()),
                      ),
                    ]),
                  ),
                ),

                SliverToBoxAdapter(child: SizedBox(height: bottomScrollSpacer)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _blob({required double size, required Color color}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0.0)]),
      ),
    );
  }

  static void _go(BuildContext context, Widget target) {
    SoundManager.playTap();
    Navigator.push(context, MaterialPageRoute(builder: (_) => target));
  }

  // ignore: unused_element
  Widget _buildAnimatedBackground() =>
      const SizedBox.shrink(); // Placeholder for unified logic
}

class _WelcomeCard extends StatelessWidget {
  final User? user;
  const _WelcomeCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        String name = "عضو Pro";
        int points = 0;
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          name = (data['name'] ?? name).toString();
          final p = data['points'];
          if (p is int) points = p;
        }
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppColors.eliteShadowL1,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: "أهلاً بك، ",
                    style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600),
                    children: [
                      TextSpan(
                          text: name,
                          style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF1B4D57))),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              InkWell(
                onTap: () {
                  SoundManager.playTap();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const StatsScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: _PointsBadge(points: points),
              ),
            ],
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.secondaryOrange,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: AppColors.secondaryOrange.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("$points ",
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
          Text("نقطة",
              style: GoogleFonts.cairo(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
  final bool isHighFocus;
  final AnimationController? floatAnimation;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.accent,
    required this.onTap,
    this.isHighFocus = false,
    this.floatAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: Colors.white,
          boxShadow:
              isHighFocus ? AppColors.eliteShadowL2 : AppColors.eliteShadowL1,
        ),
        child: Stack(
          children: [
            Positioned(
              bottom: -12,
              left: -12,
              child: Icon(icon, size: 85, color: accent.withValues(alpha: 0.06)),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AnimatedBuilder(
                    animation: floatAnimation ?? kAlwaysCompleteAnimation,
                    builder: (context, child) {
                      final floatValue = floatAnimation?.value ?? 0.0;
                      return Transform.translate(
                        offset: Offset(0, isHighFocus ? -4 * floatValue : 0),
                        child: Container(
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            color: isHighFocus
                                ? accent.withValues(alpha: 0.05 + (0.05 * floatValue))
                                : Colors.white,
                            shape: BoxShape.circle,
                            border: isHighFocus
                                ? Border.all(
                                    color: accent
                                        .withValues(alpha: 0.15 + (0.1 * floatValue)),
                                    width: 1.5)
                                : null,
                            boxShadow: [
                              BoxShadow(
                                  color: accent.withValues(alpha: isHighFocus
                                      ? 0.3 + (0.2 * floatValue)
                                      : 0.3),
                                  blurRadius:
                                      isHighFocus ? 12 + (8 * floatValue) : 8,
                                  spreadRadius:
                                      isHighFocus ? 1 * floatValue : 0,
                                  offset: const Offset(0, 4))
                            ],
                          ),
                          child: Icon(icon, color: accent, size: 24),
                        ),
                      );
                    },
                  ),
                  Text(
                    title,
                    style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight:
                            isHighFocus ? FontWeight.w900 : FontWeight.w800,
                        color: const Color(0xFF1B4D57)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecondarySectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  const _SecondarySectionCard(
      {required this.title,
      required this.icon,
      required this.accent,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border(
              right: BorderSide(color: accent.withValues(alpha: 0.4), width: 4.5)),
          boxShadow: AppColors.eliteShadowL1,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: accent, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.cairo(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1B4D57)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

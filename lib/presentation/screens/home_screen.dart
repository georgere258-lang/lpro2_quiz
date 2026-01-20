// 🔒 HOME SCREEN FROZEN (Golden Screenshot approved) — Do not change without explicit approval.
// PATH: lib/presentation/screens/home_screen.dart
// STATUS: PREMIUM GLOBAL HOME (new layout + new card design)
//         ✅ FINAL: NO header inside Home (Single real header is in MainWrapper AppBar)
//         ✅ Keeps your improvements: micro-animations + performance + spacing + shadows
//         ✅ No extra logo added
//         ✅ No const issues

import 'dart:ui';

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

// ✅ New sections (make sure these files exist with same names/paths)
import 'freelance_kit_screen.dart';
import 'close_screen.dart';
import 'market_radar_screen.dart';
import 'money_economy_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final User? user = FirebaseAuth.instance.currentUser;

  late final AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      body: Stack(
        children: [
          // ===== Premium background (animated blobs) =====
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _bgController,
              builder: (_, __) {
                final v = _bgController.value;
                return Stack(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFFFDFBF7),
                            Color(0xFFF6EFE2),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: -120 + (50 * v),
                      right: -140 + (90 * v),
                      child: _blob(
                        size: 360,
                        color: const Color(0xFFFF8C00).withValues(alpha: 0.10),
                      ),
                    ),
                    Positioned(
                      bottom: -140 + (60 * v),
                      left: -160 + (110 * v),
                      child: _blob(
                        size: 420,
                        color: AppColors.primaryDeepTeal.withValues(alpha: 0.10),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // ===== Main content =====
          Directionality(
            textDirection: TextDirection.rtl,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ✅ REMOVED: Home header (BrandHeader / pinned header)
                // Header is now ONLY in MainWrapper AppBar.

                // ===== كارت الترحيب =====
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                    child: RepaintBoundary(child: _WelcomeCard(user: user)),
                  ),
                ),

                // ===== كارت معلومة Pro =====
                const SliverToBoxAdapter(child: SizedBox(height: 10)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: RepaintBoundary(child: HomeProCardContainer()),
                  ),
                ),

                // ===== Grid Cards =====
                const SliverToBoxAdapter(child: SizedBox(height: 4)),

                // Row 1: دوري المحترفين + دوري النجوم
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: _SectionCard(
                            title: "دوري النجوم",
                            icon: Icons.auto_awesome_rounded,
                            accent: const Color(0xFF3498DB),
                            onTap: () => _go(
                              context,
                              const QuizScreen(categoryTitle: "دوري النجوم"),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SectionCard(
                            title: "دوري المحترفين",
                            icon: Icons.workspace_premium_rounded,
                            accent: const Color(0xFFFF8C00),
                            onTap: () => _go(
                              context,
                              const QuizScreen(categoryTitle: "دوري المحترفين"),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Row 2: اعرف عميلك + المعلومة بتفرق
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: _SectionCard(
                            title: "المعلومة بتفرق",
                            icon: Icons.lightbulb_outline,
                            accent: AppColors.secondaryOrange,
                            onTap: () => _go(context, const FactScreen()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SectionCard(
                            title: "اعرف عميلك",
                            icon: Icons.groups_outlined,
                            accent: AppColors.primaryDeepTeal,
                            onTap: () => _go(context, const KnowClientScreen()),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Row 3: CLOSE + Freelance Kit
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: _SectionCard(
                            title: "Freelance Kit",
                            icon: Icons.handyman_outlined,
                            accent: AppColors.secondaryOrange,
                            onTap: () => _go(context, const FreelanceKitScreen()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SectionCard(
                            title: "CLOSE",
                            icon: Icons.lock_open_rounded,
                            accent: AppColors.primaryDeepTeal,
                            onTap: () => _go(context, const CloseScreen()),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Row 4: لغة المال + Radar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _SectionCard(
                            title: "Radar",
                            icon: Icons.radar_rounded,
                            accent: const Color(0xFF2ECC71),
                            onTap: () => _go(context, const MarketRadarScreen()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SectionCard(
                            title: "لغة المال",
                            icon: Icons.attach_money_rounded,
                            accent: const Color(0xFF9B59B6),
                            onTap: () => _go(context, const MoneyEconomyScreen()),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 26)),
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
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0.0)],
        ),
      ),
    );
  }

  static void _go(BuildContext context, Widget target) {
    SoundManager.playTap();
    Navigator.push(context, MaterialPageRoute(builder: (_) => target));
  }
}

// ========================
// كارت الترحيب (الاسم + النقاط)
// ========================
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

        return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "أهلاً بك، $name",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.cairo(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF003D3D),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _PointsBadge(points: points),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ========================
// مربع النقاط (badge صغير - سطر واحد)
// ========================
class _PointsBadge extends StatelessWidget {
  final int points;
  const _PointsBadge({required this.points});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          colors: [
            AppColors.secondaryOrange.withValues(alpha: 0.95),
            AppColors.secondaryOrange.withValues(alpha: 0.80),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondaryOrange.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "$points",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w800,
              fontSize: 11,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            "نقطة",
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.w700,
              fontSize: 9,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}


// ========================
// Micro-animations helper (press scale + subtle opacity)
// ========================
class _PressableScale extends StatefulWidget {
  final VoidCallback onTap;
  final BorderRadius borderRadius;
  final Widget child;

  const _PressableScale({
    required this.onTap,
    required this.borderRadius,
    required this.child,
  });

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  bool _pressed = false;

  void _set(bool v) {
    if (_pressed == v) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final scale = _pressed ? 0.985 : 1.0;
    final opacity = _pressed ? 0.96 : 1.0;

    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        opacity: opacity,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: widget.borderRadius,
            onTap: widget.onTap,
            onTapDown: (_) => _set(true),
            onTapCancel: () => _set(false),
            onTapUp: (_) => _set(false),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

// ========================
// كروت الأقسام (Grid Cards)
// ========================
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accent;
  final VoidCallback? onTap;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const br = BorderRadius.all(Radius.circular(18));

    final cardContent = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: br,
        color: Colors.white.withValues(alpha: 0.95),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // أيقونة في دائرة
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.12),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(height: 8),
          // العنوان
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.cairo(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF003D3D),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return Opacity(
        opacity: 0.6,
        child: cardContent,
      );
    }

    return _PressableScale(
      onTap: onTap!,
      borderRadius: br,
      child: cardContent,
    );
  }
}


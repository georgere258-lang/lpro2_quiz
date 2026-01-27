// PATH: lib/presentation/screens/stats_screen.dart
// STATUS: PREMIUM STATS SCREEN (Real Data from user_stats)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../widgets/lpro_bottom_nav_bar.dart';
import 'main_wrapper.dart';

class StatsScreen extends StatefulWidget {
  final String? initialTab; // 'stars' | 'pros' | 'freeplay' | null (default: stars)
  
  const StatsScreen({super.key, this.initialTab});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Color deepTeal = AppColors.primaryDeepTeal;
  final Color safetyOrange = AppColors.secondaryOrange;

  @override
  void initState() {
    super.initState();
    ensureStatsDocExists();
    int initialIndex = 0;
    if (widget.initialTab == 'pros') {
      initialIndex = 1;
    } else if (widget.initialTab == 'freeplay') {
      initialIndex = 2;
    }
    _tabController = TabController(length: 3, vsync: this, initialIndex: initialIndex);
  }

  Future<void> ensureStatsDocExists() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final ref = FirebaseFirestore.instance.collection('user_stats').doc(user.uid);
      final snapshot = await ref.get();
      if (!snapshot.exists) {
        await ref.set(
          {
            'updatedAt': FieldValue.serverTimestamp(),
            'stars': {
              'roundsPlayed': 0,
              'totalQuestions': 0,
              'correctAnswers': 0,
              'wrongAnswers': 0,
              'currentStreak': 0,
              'bestStreak': 0,
              'totalPoints': 0,
            },
            'pros': {
              'roundsPlayed': 0,
              'totalQuestions': 0,
              'correctAnswers': 0,
              'wrongAnswers': 0,
              'currentStreak': 0,
              'bestStreak': 0,
              'totalPoints': 0,
            },
            'freeplay': {
              'roundsPlayed': 0,
              'totalQuestions': 0,
              'correctAnswers': 0,
              'wrongAnswers': 0,
              'currentStreak': 0,
              'bestStreak': 0,
            },
          },
          SetOptions(merge: true),
        );
      }
    } catch (e) {
      debugPrint('StatsScreen ensureStatsDocExists: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: deepTeal,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "إحصائياتي",
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.w900,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: safetyOrange,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
          labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 14),
          unselectedLabelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(text: "نجوم ✨"),
            Tab(text: "محترفين 🏆"),
            Tab(text: "Free Play 🎮"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStatsTab(
            league: "نجوم",
            icon: Icons.stars_rounded,
            color: Colors.amber,
            leagueKey: 'stars',
            motivationalText: "استمر في التميز والوصول للأعلى! 🌟",
          ),
          _buildStatsTab(
            league: "محترفين",
            icon: Icons.workspace_premium,
            color: deepTeal,
            leagueKey: 'pros',
            motivationalText: "أنت المحترف الحقيقي! 💪",
          ),
          _buildStatsTab(
            league: "Free Play",
            icon: Icons.sports_esports,
            color: const Color(0xFF9B59B6),
            leagueKey: 'freeplay',
            motivationalText: "التدريب المستمر هو طريق النجاح! 🎯",
            isFreePlay: true,
          ),
        ],
      ),
      bottomNavigationBar: LProBottomNavBar(
        activeIndex: 0,
        onTap: (i) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => MainWrapper(initialIndex: i)),
            (_) => false,
          );
        },
      ),
    );
  }

  Widget _buildStatsTab({
    required String league,
    required IconData icon,
    required Color color,
    required String leagueKey,
    required String motivationalText,
    bool isFreePlay = false,
  }) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Directionality(
      textDirection: TextDirection.rtl,
      child: StreamBuilder<DocumentSnapshot>(
        stream: user != null
            ? FirebaseFirestore.instance
                .collection('user_stats')
                .doc(user.uid)
                .snapshots()
            : null,
        builder: (context, snapshot) {
          // Extract league data or use defaults
          Map<String, dynamic> leagueData = {};
          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
            leagueData = (data[leagueKey] as Map<String, dynamic>?) ?? {};
          }

          final totalQuestions = (leagueData['totalQuestions'] as int?) ?? 0;
          final correctAnswers = (leagueData['correctAnswers'] as int?) ?? 0;
          final denom = totalQuestions > 0 ? totalQuestions : 1;
          final accuracy = (correctAnswers / denom * 100).round();

          return ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
          const SizedBox(height: 12),
          // ✅ Premium Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppColors.eliteShadowL2,
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.2),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 34, color: color),
                ),
                const SizedBox(height: 12),
                Text(
                  league,
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: deepTeal,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  motivationalText,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 12),
                // ✅ Progress/Accuracy Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "الدقة",
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey[700],
                            ),
                          ),
                          Text(
                            "$accuracy%",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: accuracy / 100,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // ✅ Stats Grid with Animated Numbers
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.25,
            children: [
              if (!isFreePlay)
                _buildAnimatedStatCard(
                  label: "إجمالي النقاط",
                  value: (leagueData['totalPoints'] as int?) ?? 0,
                  icon: Icons.emoji_events,
                  color: color,
                )
              else
                _buildAnimatedStatCard(
                  label: "إجمالي الأسئلة",
                  value: totalQuestions,
                  icon: Icons.help_outline,
                  color: color,
                ),
              _buildAnimatedStatCard(
                label: "الجولات",
                value: (leagueData['roundsPlayed'] as int?) ?? 0,
                icon: Icons.repeat,
                color: color,
              ),
              _buildAnimatedStatCard(
                label: "إجابات صحيحة",
                value: correctAnswers,
                icon: Icons.check_circle,
                color: color,
              ),
              _buildAnimatedStatCard(
                label: "أفضل سلسلة",
                value: (leagueData['bestStreak'] as int?) ?? 0,
                icon: Icons.local_fire_department,
                color: color,
              ),
            ],
          ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAnimatedStatCard({
    required String label,
    required int value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppColors.eliteShadowL1,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 6),
          // ✅ Animated Number
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: value),
            duration: const Duration(milliseconds: 700),
            builder: (context, animatedValue, child) {
              return Text(
                "$animatedValue",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: deepTeal,
                ),
              );
            },
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}

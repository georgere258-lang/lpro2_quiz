import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_colors.dart';
import '../../features/leaderboards/models/leaderboard_entry.dart';
import '../../features/leaderboards/repositories/leaderboards_repository.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final LeaderboardsRepository _repo = LeaderboardsRepository();

  // League keys matching Firestore: general | stars | pros
  final List<String> _leagues = ['general', 'stars', 'pros'];

  // Points field for each league (to read from user doc)
  final Map<String, String> _leaguePointsField = {
    'general': 'points',
    'stars': 'starsPoints',
    'pros': 'proPoints',
  };

  final List<IconData> avatars = [
    Icons.workspace_premium,
    Icons.person_pin,
    Icons.face_retouching_natural,
    Icons.sentiment_very_satisfied,
    Icons.stars_rounded,
    Icons.account_circle,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Debug: Log Firebase project identity
    if (kDebugMode) {
      _logFirebaseIdentity();
    }
  }

  void _logFirebaseIdentity() {
    try {
      final app = Firebase.app();
      final uid = FirebaseAuth.instance.currentUser?.uid;
      debugPrint('═══════════════════════════════════════════════');
      debugPrint('LEADERBOARD_DEBUG projectId=${app.options.projectId}');
      debugPrint('LEADERBOARD_DEBUG appId=${app.options.appId}');
      debugPrint('LEADERBOARD_DEBUG currentUser.uid=$uid');
      debugPrint('═══════════════════════════════════════════════');
    } catch (e) {
      debugPrint('LEADERBOARD_DEBUG Firebase.app() error: $e');
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
        backgroundColor: AppColors.primaryDeepTeal,
        elevation: 0,
        toolbarHeight: 20,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.center,
          indicatorColor: AppColors.secondaryOrange,
          indicatorWeight: 4,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.5),
          labelStyle:
              GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: "الترتيب العام 🏆"),
            Tab(text: "دوري النجوم ✨"),
            Tab(text: "دوري المحترفين 🔥"),
          ],
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: TabBarView(
          controller: _tabController,
          children: _leagues
              .map((league) => _buildLeaderboardList(league))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildLeaderboardList(String league) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<List<LeaderboardEntry>>(
      stream: _repo.streamTop10(league),
      builder: (context, snapshot) {
        // Error state with debug logging
        if (snapshot.hasError) {
          final error = snapshot.error;
          if (kDebugMode) {
            debugPrint('LEADERBOARD_STREAM_ERROR league=$league');
            if (error is FirebaseException) {
              debugPrint('  code=${error.code}');
              debugPrint('  message=${error.message}');
              debugPrint('  plugin=${error.plugin}');
            }
            debugPrint('  error=$error');
          }
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 12),
                  Text("حدث خطأ في تحميل البيانات",
                      style: GoogleFonts.cairo(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.red[700])),
                  if (kDebugMode) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        error is FirebaseException
                            ? 'FirebaseError: ${error.code} - ${error.message}'
                            : 'Error: $error',
                        style: GoogleFonts.robotoMono(
                            fontSize: 10, color: Colors.red[900]),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child:
                  CircularProgressIndicator(color: AppColors.secondaryOrange));
        }

        final entries = snapshot.data ?? [];

        // Empty state with admin hint
        if (entries.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.leaderboard_outlined,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text("لم يتم تحديث الترتيب بعد",
                      style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Text("يتم تحديث الترتيب من لوحة التحكم",
                      style: GoogleFonts.cairo(
                          fontSize: 13, color: Colors.grey[500])),
                ],
              ),
            ),
          );
        }

        final topThree = entries.take(3).toList();
        final others =
            entries.length > 3 ? entries.skip(3).toList() : <LeaderboardEntry>[];

        // Get rank 10 points (or last entry if less than 10)
        final rank10Points = entries.isNotEmpty ? entries.last.points : 0;

        // Check if current user is in top 10
        LeaderboardEntry? currentUserEntry;
        if (currentUid != null) {
          final idx = entries.indexWhere((e) => e.uid == currentUid);
          if (idx >= 0) {
            currentUserEntry = entries[idx];
          }
        }

        return Column(
          children: [
            _buildPodiumHeader(topThree),
            // Show motivational "My Status" card ONLY if logged in
            if (currentUid != null)
              _buildMyStatusCard(
                currentUserEntry,
                league,
                currentUid,
                rank10Points,
              ),
            // If not logged in, show hint
            if (currentUid == null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "سجل دخولك لمعرفة ترتيبك",
                  style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ),
            Expanded(
              child: ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                itemCount: others.length,
                itemBuilder: (context, index) =>
                    _buildUserTile(others[index]),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Motivational "My Status" card with gap computation
  /// Hardened: fails gracefully if /users/{uid} read fails
  Widget _buildMyStatusCard(
    LeaderboardEntry? entry,
    String league,
    String uid,
    int rank10Points,
  ) {
    final pointsField = _leaguePointsField[league] ?? 'points';

    return FutureBuilder<DocumentSnapshot>(
      // Read current user's points from /users/{uid} (self-read allowed)
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, userSnap) {
        // Loading state
        if (userSnap.connectionState == ConnectionState.waiting) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.secondaryOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.secondaryOrange,
                ),
              ),
            ),
          );
        }

        // Error state: show graceful message but don't crash
        if (userSnap.hasError) {
          final error = userSnap.error;
          if (kDebugMode) {
            debugPrint('LEADERBOARD_USER_FETCH_ERROR uid=$uid');
            if (error is FirebaseException) {
              debugPrint('  code=${error.code}');
              debugPrint('  message=${error.message}');
              debugPrint('  plugin=${error.plugin}');
            }
            debugPrint('  error=$error');
          }
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.warning_amber, color: Colors.orange[700], size: 18),
                const SizedBox(width: 8),
                Text(
                  "تعذر تحميل بياناتك",
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.orange[800],
                  ),
                ),
              ],
            ),
          );
        }

        // Get user's points for this league
        final userData = userSnap.data?.data() as Map<String, dynamic>? ?? {};
        final myPoints = (userData[pointsField] as int?) ?? 0;

        // Determine rank status
        final bool isInTop10 = entry != null;
        final String rankText = isInTop10
            ? "ترتيبك: #${entry.rank}"
            : "ترتيبك: خارج أفضل 10";

        // Compute gap to enter top 10
        final int gap = isInTop10 ? 0 : (rank10Points - myPoints + 1).clamp(0, 999999);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.secondaryOrange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppColors.secondaryOrange.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              // Rank row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isInTop10 ? Icons.emoji_events : Icons.trending_up,
                    color: AppColors.secondaryOrange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    rankText,
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.primaryDeepTeal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Points info row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _statChip("نقاطك", myPoints),
                  _statChip("أقل ترتيب", rank10Points),
                ],
              ),
              // Gap motivation (only if not in top 10)
              if (!isInTop10 && gap > 0) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDeepTeal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "ناقصك $gap نقطة لتدخل أفضل 10 💪",
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: AppColors.primaryDeepTeal,
                    ),
                  ),
                ),
              ],
              // Already in top 10 celebration
              if (isInTop10) ...[
                const SizedBox(height: 8),
                Text(
                  "أنت من الأفضل! استمر 🔥",
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _statChip(String label, int value) {
    return Column(
      children: [
        Text(
          "$value",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            color: AppColors.primaryDeepTeal,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildPodiumHeader(List<LeaderboardEntry> topThree) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 20, 10, 30),
      decoration: const BoxDecoration(
          color: AppColors.primaryDeepTeal,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(45))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (topThree.length >= 2) _buildPodiumItem(topThree[1], 2, 75),
          if (topThree.isNotEmpty) _buildPodiumItem(topThree[0], 1, 100),
          if (topThree.length >= 3) _buildPodiumItem(topThree[2], 3, 70),
        ],
      ),
    );
  }

  Widget _buildPodiumItem(LeaderboardEntry entry, int rank, double size) {
    Color medalColor = rank == 1
        ? const Color(0xFFFFD700)
        : (rank == 2 ? const Color(0xFFE0E0E0) : const Color(0xFFCD7F32));

    return Column(
      children: [
        Stack(
          alignment: Alignment.topCenter,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: medalColor, width: rank == 1 ? 4 : 2)),
              child: CircleAvatar(
                  radius: size / 2,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  child: Icon(
                      avatars[entry.avatarIndex < avatars.length
                          ? entry.avatarIndex
                          : 0],
                      color: (entry.avatarIndex == 0 || rank == 1)
                          ? AppColors.secondaryOrange
                          : Colors.white,
                      size: size * 0.55)),
            ),
            Positioned(
                top: 0,
                child: CircleAvatar(
                    radius: 14,
                    backgroundColor: medalColor,
                    child: Text("$rank",
                        style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)))),
          ],
        ),
        const SizedBox(height: 10),
        Text(entry.name.split(' ')[0],
            maxLines: 1,
            style: GoogleFonts.cairo(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13)),
        Text("${entry.points} ن",
            style: GoogleFonts.poppins(
                color: medalColor, fontWeight: FontWeight.w900, fontSize: 15)),
      ],
    );
  }

  Widget _buildUserTile(LeaderboardEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
          border:
              Border.all(color: AppColors.primaryDeepTeal.withValues(alpha: 0.05))),
      child: Row(
        children: [
          SizedBox(
              width: 35,
              child: Text("#${entry.rank}",
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w900,
                      color: Colors.grey[400],
                      fontSize: 15))),
          CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primaryDeepTeal.withValues(alpha: 0.05),
              child: Icon(
                  avatars[
                      entry.avatarIndex < avatars.length ? entry.avatarIndex : 0],
                  color: entry.avatarIndex == 0
                      ? AppColors.secondaryOrange
                      : AppColors.primaryDeepTeal,
                  size: 22)),
          const SizedBox(width: 15),
          Expanded(
              child: Text(entry.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.primaryDeepTeal))),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: AppColors.primaryDeepTeal.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12)),
              child: Text("${entry.points} ن",
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryDeepTeal,
                      fontSize: 13))),
        ],
      ),
    );
  }
}

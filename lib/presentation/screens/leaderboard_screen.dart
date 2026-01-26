import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
        if (snapshot.hasError) {
          return Center(
              child: Text("حدث خطأ في تحميل البيانات",
                  style: GoogleFonts.cairo()));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child:
                  CircularProgressIndicator(color: AppColors.secondaryOrange));
        }

        final entries = snapshot.data ?? [];

        if (entries.isEmpty) {
          return Center(
              child:
                  Text("لا يوجد متسابقون حالياً", style: GoogleFonts.cairo()));
        }

        final topThree = entries.take(3).toList();
        final others =
            entries.length > 3 ? entries.skip(3).toList() : <LeaderboardEntry>[];

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
            // Show current user rank
            if (currentUid != null)
              _buildCurrentUserRank(currentUserEntry, league, currentUid),
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

  Widget _buildCurrentUserRank(LeaderboardEntry? entry, String league, String uid) {
    return FutureBuilder<LeaderboardEntry?>(
      // If not in top 10 from stream, try fetching directly
      future: entry == null ? _repo.getUserEntry(league, uid) : Future.value(entry),
      builder: (context, snap) {
        final userEntry = snap.data ?? entry;
        final rankText = userEntry != null
            ? "ترتيبك: #${userEntry.rank}"
            : "ترتيبك: خارج أفضل 10";

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.secondaryOrange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.secondaryOrange.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.emoji_events, color: AppColors.secondaryOrange, size: 20),
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
        );
      },
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

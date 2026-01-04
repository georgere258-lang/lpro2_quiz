import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// استيراد الثوابت المركزية
import '../../core/constants/app_colors.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _rankingFields = ['points', 'starsPoints', 'proPoints'];
  final Color turquoiseCyan = const Color(0xFF00CED1);

  // قائمة الأيقونات المطابقة لما في البروفايل لعرضها في لوحة الصدارة
  final List<IconData> avatars = [
    Icons.person_pin,
    Icons.face_retouching_natural,
    Icons.sentiment_very_satisfied,
    Icons.workspace_premium,
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
        toolbarHeight: 5,
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
            Tab(text: "الترتيب العام"),
            Tab(text: "دوري النجوم"),
            Tab(text: "دوري المحترفين"),
          ],
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: TabBarView(
          controller: _tabController,
          children: _rankingFields
              .map((field) => _buildLeaderboardList(field))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildLeaderboardList(String orderByField) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .orderBy(orderByField, descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text("لا يوجد متنافسون حالياً",
                style: GoogleFonts.cairo(color: AppColors.primaryDeepTeal)),
          );
        }

        final allUsers = snapshot.data!.docs;
        final topThree = allUsers.take(3).toList();
        final others = allUsers.skip(3).toList();

        return Column(
          children: [
            _buildPodiumHeader(topThree, orderByField),
            Expanded(
              child: ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                itemCount: others.length,
                itemBuilder: (context, index) {
                  var data = others[index].data() as Map<String, dynamic>;
                  return _buildUserTile(index + 4, data, orderByField);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPodiumHeader(
      List<QueryDocumentSnapshot> topThree, String field) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 20, 10, 30),
      decoration: const BoxDecoration(
        color: AppColors.primaryDeepTeal,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(45)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (topThree.length >= 2) _buildPodiumItem(topThree[1], 2, 70, field),
          if (topThree.isNotEmpty) _buildPodiumItem(topThree[0], 1, 95, field),
          if (topThree.length >= 3) _buildPodiumItem(topThree[2], 3, 65, field),
        ],
      ),
    );
  }

  Widget _buildPodiumItem(
      QueryDocumentSnapshot doc, int rank, double size, String field) {
    var data = doc.data() as Map<String, dynamic>;
    Color medalColor = rank == 1
        ? const Color(0xFFFFD700)
        : (rank == 2 ? const Color(0xFFE0E0E0) : const Color(0xFFCD7F32));

    int avatarIdx = data['avatarIndex'] ?? 0;

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
                  avatars[avatarIdx < avatars.length ? avatarIdx : 0],
                  color: Colors.white,
                  size: size * 0.6,
                ),
              ),
            ),
            Positioned(
              top: 0,
              child: CircleAvatar(
                  radius: 13,
                  backgroundColor: medalColor,
                  child: Text("$rank",
                      style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 12))),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(data['name']?.split(' ')[0] ?? "عضو",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.cairo(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12)),
        Text("${data[field] ?? 0} ن",
            style: GoogleFonts.poppins(
                color: medalColor, fontWeight: FontWeight.w900, fontSize: 14)),
      ],
    );
  }

  Widget _buildUserTile(int rank, Map<String, dynamic> data, String field) {
    int avatarIdx = data['avatarIndex'] ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 35,
            child: Text("#$rank",
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w900,
                    color: Colors.grey[400],
                    fontSize: 15)),
          ),
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFF0F4F5),
            child: Icon(
              avatars[avatarIdx < avatars.length ? avatarIdx : 0],
              color: AppColors.primaryDeepTeal,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Text(data['name'] ?? "عضو L Pro",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.primaryDeepTeal))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: const Color(0xFFF0F4F5),
                borderRadius: BorderRadius.circular(10)),
            child: Text("${data[field] ?? 0} ن",
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryDeepTeal,
                    fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

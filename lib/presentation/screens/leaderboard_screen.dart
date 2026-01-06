import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/user_model.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // سنعتمد على حقل 'points' كحقل ترتيب موحد لضمان ظهور الـ 50 مستخدم في كل التبويبات
  final List<String> _rankingFields = ['points', 'starsPoints', 'proPoints'];

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
          unselectedLabelColor: Colors.white.withOpacity(0.5),
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
          children: _rankingFields
              .map((field) => _buildLeaderboardList(field))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildLeaderboardList(String currentField) {
    return StreamBuilder<QuerySnapshot>(
      // السحر هنا: الترتيب دايماً حسب points عشان القائمة تظهر كاملة بالـ 50 شخص
      stream: FirebaseFirestore.instance
          .collection('users')
          .orderBy('points', descending: true)
          .limit(50)
          .snapshots(),
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

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
              child:
                  Text("لا يوجد متسابقون حالياً", style: GoogleFonts.cairo()));
        }

        final allUsers = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return UserModel.fromMap(data, doc.id);
        }).toList();

        // إعادة ترتيب القائمة داخل الموبايل (Logic) بناءً على التبويب المفتوح
        // عشان اللي عنده نقاط أكتر في دوري النجوم يطلع فوق حتى لو نقاطه الكلية أقل
        allUsers.sort((a, b) {
          int valA = _getPointsValue(a, currentField);
          int valB = _getPointsValue(b, currentField);
          return valB.compareTo(valA);
        });

        final topThree = allUsers.take(3).toList();
        final others =
            allUsers.length > 3 ? allUsers.skip(3).toList() : <UserModel>[];

        return Column(
          children: [
            _buildPodiumHeader(topThree, currentField),
            Expanded(
              child: ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                itemCount: others.length,
                itemBuilder: (context, index) =>
                    _buildUserTile(index + 4, others[index], currentField),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPodiumHeader(List<UserModel> topThree, String field) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 20, 10, 30),
      decoration: const BoxDecoration(
          color: AppColors.primaryDeepTeal,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(45))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (topThree.length >= 2) _buildPodiumItem(topThree[1], 2, 75, field),
          if (topThree.isNotEmpty) _buildPodiumItem(topThree[0], 1, 100, field),
          if (topThree.length >= 3) _buildPodiumItem(topThree[2], 3, 70, field),
        ],
      ),
    );
  }

  Widget _buildPodiumItem(UserModel user, int rank, double size, String field) {
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
                  backgroundColor: Colors.white.withOpacity(0.1),
                  child: Icon(
                      avatars[user.avatarIndex < avatars.length
                          ? user.avatarIndex
                          : 0],
                      color: (user.avatarIndex == 0 || rank == 1)
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
        Text(user.displayName.split(' ')[0],
            maxLines: 1,
            style: GoogleFonts.cairo(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13)),
        Text("${_getPointsValue(user, field)} ن",
            style: GoogleFonts.poppins(
                color: medalColor, fontWeight: FontWeight.w900, fontSize: 15)),
      ],
    );
  }

  Widget _buildUserTile(int rank, UserModel user, String field) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
          border:
              Border.all(color: AppColors.primaryDeepTeal.withOpacity(0.05))),
      child: Row(
        children: [
          SizedBox(
              width: 35,
              child: Text("#$rank",
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w900,
                      color: Colors.grey[400],
                      fontSize: 15))),
          CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primaryDeepTeal.withOpacity(0.05),
              child: Icon(
                  avatars[
                      user.avatarIndex < avatars.length ? user.avatarIndex : 0],
                  color: user.avatarIndex == 0
                      ? AppColors.secondaryOrange
                      : AppColors.primaryDeepTeal,
                  size: 22)),
          const SizedBox(width: 15),
          Expanded(
              child: Text(user.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.primaryDeepTeal))),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: AppColors.primaryDeepTeal.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12)),
              child: Text("${_getPointsValue(user, field)} ن",
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryDeepTeal,
                      fontSize: 13))),
        ],
      ),
    );
  }

  int _getPointsValue(UserModel user, String field) {
    if (field == 'starsPoints') return user.starsPoints;
    if (field == 'proPoints') return user.proPoints;
    return user.points;
  }
}

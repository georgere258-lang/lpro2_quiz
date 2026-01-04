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
  final Color turquoiseCyan = const Color(0xFF00CED1); // اللون الفيروزي المعتمد

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
        toolbarHeight: 2, // مساحة طفيفة جداً للفصل
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.center,
          indicatorColor: AppColors.secondaryOrange,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor:
              Colors.white.withValues(alpha: 0.5), // تحديث: withValues
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
      padding: const EdgeInsets.fromLTRB(15, 20, 15, 30),
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
          if (topThree.length >= 2) _buildPodiumItem(topThree[1], 2, 75, field),
          if (topThree.isNotEmpty) _buildPodiumItem(topThree[0], 1, 100, field),
          if (topThree.length >= 3) _buildPodiumItem(topThree[2], 3, 70, field),
        ],
      ),
    );
  }

  Widget _buildPodiumItem(
      QueryDocumentSnapshot doc, int rank, double size, String field) {
    var data = doc.data() as Map<String, dynamic>;
    Color medalColor = rank == 1
        ? const Color(0xFFFFD700) // ذهبي
        : (rank == 2
            ? const Color(0xFFE0E0E0) // فضي
            : const Color(0xFFCD7F32)); // برونزي

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
                backgroundImage:
                    (data['photoUrl'] != null && data['photoUrl'] != "")
                        ? NetworkImage(data['photoUrl'])
                        : null,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                child: (data['photoUrl'] == null || data['photoUrl'] == "")
                    ? Icon(Icons.person, color: Colors.white, size: size * 0.5)
                    : null,
              ),
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
                          fontSize: 13))),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(data['name']?.split(' ')[0] ?? "عضو",
            style: GoogleFonts.cairo(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomPaint(
                size: const Size(8, 8),
                painter: SolidTrianglePainter(turquoiseCyan)),
            const SizedBox(width: 4),
            Text("${data[field] ?? 0} ن",
                style: GoogleFonts.poppins(
                    color: medalColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 15)),
          ],
        ),
      ],
    );
  }

  Widget _buildUserTile(int rank, Map<String, dynamic> data, String field) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04), // تحديث: withValues
              blurRadius: 15,
              offset: const Offset(0, 4))
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
                    fontSize: 16)),
          ),
          CircleAvatar(
            radius: 22,
            backgroundImage:
                (data['photoUrl'] != null && data['photoUrl'] != "")
                    ? NetworkImage(data['photoUrl'])
                    : null,
            backgroundColor: const Color(0xFFF0F4F5),
            child: (data['photoUrl'] == null || data['photoUrl'] == "")
                ? const Icon(Icons.person,
                    color: AppColors.primaryDeepTeal, size: 22)
                : null,
          ),
          const SizedBox(width: 15),
          Expanded(
              child: Text(data['name'] ?? "عضو L Pro",
                  style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.primaryDeepTeal))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: const Color(0xFFF0F4F5),
                borderRadius: BorderRadius.circular(12)),
            child: Text("${data[field] ?? 0} ن",
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryDeepTeal,
                    fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class SolidTrianglePainter extends CustomPainter {
  final Color color;
  SolidTrianglePainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(size.width, 0);
    path.lineTo(0, size.height / 2);
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

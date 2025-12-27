import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

/**
 * [RealEstateLeague] - الدوري العقاري
 * الشاشة المسؤولة عن عرض المنافسات وترتيب المستخدمين.
 */

class RealEstateLeague extends StatefulWidget {
  const RealEstateLeague({super.key});

  @override
  State<RealEstateLeague> createState() => _RealEstateLeagueState();
}

class _RealEstateLeagueState extends State<RealEstateLeague> with SingleTickerProviderStateMixin {
  
  // =============================================================
  // [1] لوحة الألوان الموحدة وبيانات المنافسة
  // =============================================================
  static const Color brandOrange = Color(0xFFC67C32);
  static const Color navyDeep = Color(0xFF1E2B3E);
  static const Color navyLight = Color(0xFF2C3E50);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color iceGray = Color(0xFFF2F4F7);
  
  // ألوان المعادن للفائزين
  static const Color gold = Color(0xFFFFD700);
  static const Color silver = Color(0xFFC0C0C0);
  static const Color bronze = Color(0xFFCD7F32);

  // قائمة وهمية للمتصدّرين (سيتم ربطها بـ Firebase لاحقاً)
  final List<Map<String, dynamic>> leaderboardData = [
    {"rank": 4, "name": "أحمد الشناوي", "points": "4,820", "trend": "up", "avatar": "AS"},
    {"rank": 5, "name": "سارة محمود", "points": "4,750", "trend": "down", "avatar": "SM"},
    {"rank": 6, "name": "ياسين إبراهيم", "points": "4,600", "trend": "up", "avatar": "YI"},
    {"rank": 7, "name": "ليلى يوسف", "points": "4,420", "trend": "stable", "avatar": "LY"},
    {"rank": 8, "name": "مريم جرجس", "points": "4,300", "trend": "up", "isMe": true, "avatar": "MG"},
    {"rank": 9, "name": "عمر فاروق", "points": "4,150", "trend": "down", "avatar": "OF"},
    {"rank": 10, "name": "نادين علي", "points": "4,000", "trend": "up", "avatar": "NA"},
    {"rank": 11, "name": "خالد سعد", "points": "3,850", "trend": "stable", "avatar": "KS"},
    {"rank": 12, "name": "هند صبري", "points": "3,700", "trend": "up", "avatar": "HS"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navyDeep, // الخلفية كحلي لتعزيز هيبة الدوري
      body: Stack(
        children: [
          _buildMainLeagueContent(),
          _buildMyStickyBottomRank(), // كارت مريم الثابت
        ],
      ),
    );
  }

  // =============================================================
  // [2] بناء المحتوى الرئيسي (Main Content)
  // =============================================================

  Widget _buildMainLeagueContent() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildLeagueAppBar(),
        SliverToBoxAdapter(child: _buildPodiumSection()), // منصة التتويج
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildLeaderboardTile(leaderboardData[index]),
              childCount: leaderboardData.length,
            ),
          ),
        ),
      ],
    );
  }

  // =============================================================
  // [3] وحدات الواجهة (UI Building Units)
  // =============================================================

  Widget _buildLeagueAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      backgroundColor: navyDeep,
      pinned: true,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          "الدوري العقاري 🏆",
          style: GoogleFonts.cairo(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 18),
        ),
      ),
    );
  }

  // منصة الثلاثة الأوائل (Podium)
  Widget _buildPodiumSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildPodiumUser("كريم فؤاد", "2", silver, 135, "🥈"),
          const SizedBox(width: 15),
          _buildPodiumUser("ياسر القاضي", "1", gold, 175, "👑"),
          const SizedBox(width: 15),
          _buildPodiumUser("منى زكي", "3", bronze, 135, "🥉"),
        ],
      ),
    );
  }

  Widget _buildPodiumUser(String name, String rank, Color color, double height, String icon) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 26)),
        const SizedBox(height: 8),
        Container(
          width: height * 0.6,
          height: height * 0.6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 4),
            boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 15)],
          ),
          child: CircleAvatar(
            backgroundColor: navyLight,
            child: Text(name.substring(0, 1), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 12),
        Text(name, style: GoogleFonts.cairo(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
          child: Text(rank, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
        ),
      ],
    );
  }

  // كروت القائمة (Leaderboard Tiles)
  Widget _buildLeaderboardTile(Map<String, dynamic> data) {
    bool isMe = data['isMe'] ?? false;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isMe ? brandOrange.withOpacity(0.15) : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: isMe ? brandOrange : Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Text("${data['rank']}", style: GoogleFonts.poppins(color: Colors.white70, fontWeight: FontWeight.bold)),
          const SizedBox(width: 15),
          CircleAvatar(backgroundColor: navyLight, child: Text(data['avatar'], style: const TextStyle(color: brandOrange, fontSize: 12))),
          const SizedBox(width: 15),
          Expanded(
            child: Text(data['name'], style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("${data['points']} نقطة", style: GoogleFonts.cairo(color: brandOrange, fontWeight: FontWeight.w900, fontSize: 14)),
              _buildTrendIcon(data['trend']),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrendIcon(String trend) {
    if (trend == "up") return const Icon(Icons.trending_up, color: Colors.greenAccent, size: 16);
    if (trend == "down") return const Icon(Icons.trending_down, color: Colors.redAccent, size: 16);
    return const Icon(Icons.remove, color: Colors.grey, size: 16);
  }

  // كارت مريم الثابت في الأسفل (My Sticky Rank)
  Widget _buildMyStickyBottomRank() {
    return Positioned(
      bottom: 30,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: brandOrange,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Row(
          children: [
            const Icon(Icons.military_tech, color: Colors.white, size: 40),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("مركزك الحالي", style: GoogleFonts.cairo(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                Text("المركز الثامن", style: GoogleFonts.cairo(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(color: navyDeep, shape: BoxShape.circle),
              child: const Icon(Icons.keyboard_arrow_up, color: Colors.white),
            )
          ],
        ),
      ),
    );
  }
}
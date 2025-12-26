import 'package:flutter/material.dart';

class RealEstateLeague extends StatelessWidget {
  const RealEstateLeague({super.key});

  @override
  Widget build(BuildContext context) {
    // الألوان المتوهجة المتسقة مع الشاشة الرئيسية
    const Color brandOrange = Color(0xFFFF4D00);
    const Color electricBlue = Color(0xFF00D2FF);
    const Color navyDark = Color(0xFF080E1D);

    // بيانات لوحة الشرف الافتراضية (روح المنافسة)
    final List<Map<String, dynamic>> leaderboard = [
      {"name": "مريم", "points": 2450, "rank": "الأسطورة", "isMe": true},
      {"name": "أحمد محمود", "points": 2100, "rank": "القناص", "isMe": false},
      {"name": "سارة علي", "points": 1850, "rank": "المتألق", "isMe": false},
      {"name": "ياسين محمد", "points": 1400, "rank": "المتألق", "isMe": false},
      {"name": "مستخدم_77", "points": 950, "rank": "المجتهد", "isMe": false},
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.5, -0.6),
            radius: 1.5,
            colors: [Color(0xFF1E293B), navyDark],
          ),
        ),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // AppBar
            SliverAppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text("الدوري العقاري", 
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
              centerTitle: true,
            ),
            
            // كارت الرتبة الشخصي
            SliverToBoxAdapter(
              child: _buildUserRankCard(brandOrange, electricBlue),
            ),

            // عنوان لوحة الشرف
            SliverToBoxAdapter(
              child: _buildSectionHeader("لوحة الشرف 🏆", brandOrange),
            ),

            // قائمة المتصدرين
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildLeaderboardTile(leaderboard[index], index + 1, brandOrange),
                  childCount: leaderboard.length,
                ),
              ),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  // كارت الرتبة (تم تعديل أوزان الخطوط هنا)
  Widget _buildUserRankCard(Color orange, Color blue) {
    return Container(
      margin: const EdgeInsets.all(25),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: orange.withOpacity(0.4), width: 2),
        boxShadow: [
          BoxShadow(color: orange.withOpacity(0.1), blurRadius: 20, spreadRadius: 5)
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: orange, width: 2),
                ),
                child: const CircleAvatar(
                  radius: 35,
                  backgroundColor: Color(0xFF0F172A),
                  child: Text("👑", style: TextStyle(fontSize: 35)),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("رتبتك الحالية", 
                      style: TextStyle(color: Colors.white60, fontSize: 14)),
                    Text("الأسطورة", 
                      style: TextStyle(color: orange, fontSize: 26, fontWeight: FontWeight.w900)),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("تقدم المستوى", style: TextStyle(color: Colors.white, fontSize: 13)),
              Text("75%", style: TextStyle(color: blue, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: LinearProgressIndicator(
              value: 0.75,
              backgroundColor: Colors.white10,
              color: blue,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 15),
          const Text("باقي 550 نقطة للوصول للقب الملكي 🚀", 
            style: TextStyle(color: Colors.white54, fontSize: 12, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color orange) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
      child: Row(
        children: [
          Text(title, 
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(width: 15),
          Expanded(child: Divider(color: orange.withOpacity(0.3), thickness: 1)),
        ],
      ),
    );
  }

  // تم استبدال FontWeight.black بـ FontWeight.w900 هنا لإصلاح الخطأ
  Widget _buildLeaderboardTile(Map<String, dynamic> user, int rankNum, Color orange) {
    bool isMe = user['isMe'];
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: isMe ? orange.withOpacity(0.15) : Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: isMe ? orange.withOpacity(0.5) : Colors.white10,
          width: isMe ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text("#$rankNum", 
              style: TextStyle(
                color: rankNum <= 3 ? Colors.amber : Colors.white38, 
                fontWeight: FontWeight.w900, 
                fontSize: 20
              )),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user['name'], 
                  style: TextStyle(
                    color: Colors.white, 
                    fontWeight: isMe ? FontWeight.w900 : FontWeight.bold, 
                    fontSize: 17
                  )),
                Text(user['rank'], 
                  style: TextStyle(color: isMe ? orange : Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("${user['points']}", 
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
              const Text("نقطة", style: TextStyle(color: Colors.white38, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}
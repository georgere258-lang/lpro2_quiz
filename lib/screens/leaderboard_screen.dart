import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});
  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  static const Color deepTeal = Color(0xFF1B4D57);
  static const Color safetyOrange = Color(0xFFE67E22);
  static const Color iceWhite = Color(0xFFF8F9FA);
  
  // ألوان الميداليات المحسنة (تدرجات معدنية)
  static const Color goldMedal = Color(0xFFFFD700);    // ذهبي ناصع
  static const Color silverMedal = Color(0xFFE0E0E0);  // فضي لامع
  static const Color bronzeMedal = Color(0xFFCD7F32);  // برونزي كلاسيكي

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy('points', descending: true)
            .limit(10)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              color: deepTeal,
              child: const Center(child: CircularProgressIndicator(color: Colors.white)),
            );
          }

          var users = snapshot.data?.docs ?? [];

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [deepTeal, Color(0xFF0D2A30)],
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 50),
                _buildHeader(context),
                const SizedBox(height: 20),
                _buildPodium(users), 
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: 30),
                    decoration: const BoxDecoration(
                      color: iceWhite, 
                      borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, -5))]
                    ),
                    child: _buildRankingsList(users),
                  ),
                )
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          Text("دوري وحوش العقارات", 
                style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          const Icon(Icons.emoji_events_outlined, color: goldMedal, size: 24),
        ],
      ),
    );
  }

  Widget _buildPodium(List<QueryDocumentSnapshot> users) {
    Map<String, dynamic> getUserData(int index) {
      if (users.length > index) {
        return users[index].data() as Map<String, dynamic>;
      }
      return {"name": "قادم..", "points": 0};
    }

    var first = getUserData(0);
    var second = getUserData(1);
    var third = getUserData(2);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // المركز الثاني - فضي
        _pillar(second['name'], second['points'].toString(), 105, silverMedal, "2"),
        const SizedBox(width: 15),
        // المركز الأول - ذهبي
        _pillar(first['name'], first['points'].toString(), 150, goldMedal, "1"), 
        const SizedBox(width: 15),
        // المركز الثالث - برونزي
        _pillar(third['name'], third['points'].toString(), 85, bronzeMedal, "3"),
      ],
    );
  }

  Widget _pillar(String name, String pts, double height, Color color, String rank) => Column(
    children: [
      if (rank == "1") 
        const Icon(Icons.workspace_premium, color: goldMedal, size: 35),
      const SizedBox(height: 5),
      CircleAvatar(
        backgroundColor: Colors.white24, 
        radius: rank == "1" ? 32 : 26, 
        child: Text(name.isNotEmpty ? name[0] : "?", 
               style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))
      ),
      const SizedBox(height: 8),
      SizedBox(
        width: 75,
        child: Text(name.split(' ')[0], 
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.cairo(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
      ),
      const SizedBox(height: 5),
      Container(
        width: 75, height: height, 
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color, color.withOpacity(0.6)],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))
          ]
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("#$rank", 
              style: GoogleFonts.poppins(
                color: rank == "1" ? Colors.black87 : Colors.white, 
                fontWeight: FontWeight.w900, 
                fontSize: 26)
            ),
            Text("$pts ن", 
              style: GoogleFonts.cairo(
                color: rank == "1" ? Colors.black54 : Colors.white70, 
                fontSize: 11, 
                fontWeight: FontWeight.bold)
            ),
          ],
        ),
      ),
    ],
  );

  Widget _buildRankingsList(List<QueryDocumentSnapshot> users) {
    if (users.length <= 3) {
      return Center(child: Text("المنافسة لسه بتبدأ.. شد حيلك!", style: GoogleFonts.cairo(color: deepTeal)));
    }
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      itemCount: users.length - 3,
      itemBuilder: (context, i) {
        var user = users[i + 3];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5, offset: const Offset(0, 2))]
          ),
          child: ListTile(
            leading: Text("${i + 4}", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.grey[400])),
            title: Text(user['name'], style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600, color: deepTeal)),
            trailing: Text("${user['points']} ن", style: GoogleFonts.cairo(color: safetyOrange, fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }
}
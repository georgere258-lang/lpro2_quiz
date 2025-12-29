import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // أضفنا الفايربيز هنا أيضاً

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});
  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  static const Color deepTeal = Color(0xFF1B4D57);
  static const Color safetyOrange = Color(0xFFE67E22);
  static const Color iceWhite = Color(0xFFF8F9FA);
  static const Color silverMedal = Color(0xFFC0C0C0); 
  static const Color bronzeMedal = Color(0xFFCD7F32);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // استخدام StreamBuilder هنا سيجعل الترتيب يتحدث تلقائياً بمجرد فوز أي مستشار عقاري بنقاط
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy('points', descending: true) // الترتيب من الأعلى للأقل
            .limit(10) // أفضل 10 لاعبين
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }

          var users = snapshot.data?.docs ?? [];

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [deepTeal, Color(0xFF003D45)],
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 50),
                _buildHeader(context),
                const SizedBox(height: 20),
                // تمرير بيانات أول 3 لاعبين لمنصة التتويج
                _buildPodium(users), 
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: 30),
                    decoration: const BoxDecoration(
                      color: iceWhite, 
                      borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
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
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Text("دوري وحوش العقارات", 
                style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(width: 40), 
        ],
      ),
    );
  }

  // تحديث منصة التتويج لتقبل البيانات من الفايربيز
  Widget _buildPodium(List<QueryDocumentSnapshot> users) {
    String u1 = users.length > 0 ? users[0]['name'] : "قادم..";
    String u2 = users.length > 1 ? users[1]['name'] : "قادم..";
    String u3 = users.length > 2 ? users[2]['name'] : "قادم..";

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _pillar(u2, 100, silverMedal, "2"),
        const SizedBox(width: 15),
        _pillar(u1, 140, safetyOrange, "1"), 
        const SizedBox(width: 15),
        _pillar(u3, 80, bronzeMedal, "3"),
      ],
    );
  }

  Widget _pillar(String name, double height, Color color, String rank) => Column(
    children: [
      Text(rank, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
      CircleAvatar(
        backgroundColor: Colors.white24, 
        radius: 25, 
        child: Text(name.isNotEmpty ? name[0] : "?", style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold))
      ),
      const SizedBox(height: 10),
      Container(
        width: 70, height: height, 
        decoration: BoxDecoration(
          color: color, 
          borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
        ),
        child: Center(child: rank == "1" ? const Icon(Icons.emoji_events, color: Colors.white) : null),
      ),
      Text(name, style: GoogleFonts.cairo(color: Colors.white, fontSize: 12)),
    ],
  );

  Widget _buildRankingsList(List<QueryDocumentSnapshot> users) => ListView.builder(
    padding: const EdgeInsets.all(25),
    itemCount: users.length > 3 ? users.length - 3 : 0, // عرض باقي اللاعبين بعد التوب 3
    itemBuilder: (context, i) {
      var user = users[i + 3];
      return Card(
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: ListTile(
          leading: CircleAvatar(backgroundColor: Colors.grey[200], child: Text("${i + 4}")),
          title: Text(user['name'], style: GoogleFonts.cairo(fontSize: 14)),
          trailing: Text("${user['points']} ن", style: GoogleFonts.cairo(color: deepTeal, fontWeight: FontWeight.bold)),
        ),
      );
    },
  );
}
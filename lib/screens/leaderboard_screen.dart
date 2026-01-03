import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  final Color deepTeal = const Color(0xFF1B4D57);
  final Color safetyOrange = const Color(0xFFE67E22);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F8),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .orderBy('points', descending: true)
              .limit(20)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Text(
                  "لا يوجد متنافسون حالياً",
                  style: GoogleFonts.cairo(color: deepTeal),
                ),
              );
            }

            final allUsers = snapshot.data!.docs;
            final topThree = allUsers.take(3).toList();
            final others = allUsers.skip(3).toList();

            return Column(
              children: [
                // الهيدر المحدث بالعنوان الجديد
                _buildPodiumHeader(topThree),

                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 10),
                    itemCount: others.length,
                    itemBuilder: (context, index) {
                      var data = others[index].data() as Map<String, dynamic>;
                      return _buildUserTile(index + 4, data);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // بناء منصة التتويج مع العنوان المحدث
  Widget _buildPodiumHeader(List<QueryDocumentSnapshot> topThree) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
      decoration: BoxDecoration(
        color: deepTeal,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
      ),
      child: Column(
        children: [
          Text(
            "ترتيب الدوري العقاري 🏆", // تم تعديل العنوان هنا
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (topThree.length >= 2) _buildPodiumItem(topThree[1], 2, 70),
              if (topThree.length >= 1) _buildPodiumItem(topThree[0], 1, 95),
              if (topThree.length >= 3) _buildPodiumItem(topThree[2], 3, 65),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumItem(QueryDocumentSnapshot doc, int rank, double size) {
    var data = doc.data() as Map<String, dynamic>;
    Color color = rank == 1
        ? const Color(0xFFFFD700) // ذهبي
        : (rank == 2
            ? const Color(0xFFC0C0C0)
            : const Color(0xFFCD7F32)); // فضي وبرونزي

    return Column(
      children: [
        Stack(
          alignment: Alignment.topCenter,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 3),
              ),
              child: CircleAvatar(
                radius: size / 2,
                backgroundImage:
                    (data['photoUrl'] != null && data['photoUrl'] != "")
                        ? NetworkImage(data['photoUrl'])
                        : null,
                child: (data['photoUrl'] == null || data['photoUrl'] == "")
                    ? Icon(Icons.person, color: Colors.white, size: size * 0.6)
                    : null,
                backgroundColor: Colors.white10,
              ),
            ),
            CircleAvatar(
              radius: 12,
              backgroundColor: color,
              child: Text(
                "$rank",
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          data['name']?.split(' ')[0] ?? "خبير",
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        Text(
          "${data['points'] ?? 0} ن",
          style: GoogleFonts.poppins(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildUserTile(int rank, Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)
        ],
      ),
      child: Row(
        children: [
          Text(
            "#$rank",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w900,
              color: Colors.grey[400],
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 15),
          CircleAvatar(
            radius: 20,
            backgroundImage:
                (data['photoUrl'] != null && data['photoUrl'] != "")
                    ? NetworkImage(data['photoUrl'])
                    : null,
            backgroundColor: const Color(0xFFF0F4F5),
            child: (data['photoUrl'] == null || data['photoUrl'] == "")
                ? Icon(Icons.person, color: deepTeal, size: 20)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              data['name'] ?? "خبير عقاري",
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: deepTeal,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              "${data['points'] ?? 0} ن",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: deepTeal,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  final Color deepTeal = const Color(0xFF1B4D57);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        backgroundColor: deepTeal,
        elevation: 0,
        title: Text(
          "أبطال Pro 🏆",
          style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            // هيدر تعريفي بسيط
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              color: deepTeal,
              child: Text(
                "قائمة صفوة العقاريين الأكثر تميزاً",
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(color: Colors.white70, fontSize: 12),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .orderBy('points', descending: true)
                    .limit(20)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    padding: const EdgeInsets.all(15),
                    itemBuilder: (context, index) {
                      var userDoc = snapshot.data!.docs[index];
                      int rank = index + 1;
                      String name = userDoc['name'] ?? "";
                      if (name.isEmpty) {
                        name =
                            "Pro-${userDoc.id.substring(0, 4).toUpperCase()}";
                      }

                      bool isTop3 = rank <= 3;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          // تمييز أول 3 مراكز بحدود ملونة
                          border: isTop3
                              ? Border.all(
                                  color: _getRankColor(rank).withOpacity(0.5),
                                  width: 1.5)
                              : Border.all(color: Colors.transparent),
                          boxShadow: [
                            BoxShadow(
                              color: isTop3
                                  ? _getRankColor(rank).withOpacity(0.1)
                                  : Colors.black.withOpacity(0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            _buildRankBadge(rank),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: GoogleFonts.cairo(
                                      fontWeight: FontWeight.bold,
                                      fontSize: isTop3 ? 16 : 14,
                                      color: isTop3 ? deepTeal : Colors.black87,
                                    ),
                                  ),
                                  if (isTop3)
                                    Text(
                                      rank == 1
                                          ? "خبير الصدارة 🥇"
                                          : "بطل متميز ✨",
                                      style: GoogleFonts.cairo(
                                          fontSize: 10,
                                          color: _getRankColor(rank),
                                          fontWeight: FontWeight.bold),
                                    ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isTop3
                                    ? _getRankColor(rank).withOpacity(0.1)
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "${userDoc['points']} ن",
                                style: GoogleFonts.poppins(
                                  color:
                                      isTop3 ? _getRankColor(rank) : deepTeal,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRankColor(int rank) {
    if (rank == 1) return const Color(0xFFFFD700); // ذهبي
    if (rank == 2) return const Color(0xFFC0C0C0); // فضي
    if (rank == 3) return const Color(0xFFCD7F32); // برونزي
    return Colors.grey;
  }

  Widget _buildRankBadge(int rank) {
    if (rank <= 3) {
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _getRankColor(rank).withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.emoji_events_rounded,
            color: _getRankColor(rank), size: rank == 1 ? 34 : 28),
      );
    }
    return CircleAvatar(
      radius: 16,
      backgroundColor: Colors.grey[50],
      child: Text(
        "$rank",
        style: GoogleFonts.poppins(
            fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600]),
      ),
    );
  }
}

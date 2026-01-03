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
      backgroundColor: const Color(0xFFF4F7F8), // نفس خلفية الهوم الموحدة
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            // هيدر تعريفي بسيط وأنيق
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              decoration: BoxDecoration(
                color: deepTeal,
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Text(
                    "لوحة الصدارة للخبراء 🏆",
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    "صفوة المستشارين العقاريين الأكثر تميزاً",
                    style: GoogleFonts.cairo(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
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

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    padding: const EdgeInsets.all(15),
                    itemBuilder: (context, index) {
                      var userDoc = snapshot.data!.docs[index];
                      var data = userDoc.data() as Map<String, dynamic>;
                      int rank = index + 1;
                      String name = data['name'] ?? "خبير مجهول";
                      String photoUrl = data['photoUrl'] ?? "";
                      bool isTop3 = rank <= 3;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: isTop3
                                  ? _getRankColor(rank).withOpacity(0.15)
                                  : Colors.black.withOpacity(0.04),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            )
                          ],
                          border: isTop3
                              ? Border.all(
                                  color: _getRankColor(rank).withOpacity(0.3),
                                  width: 1.5)
                              : null,
                        ),
                        child: Row(
                          children: [
                            _buildRankBadge(rank),
                            const SizedBox(width: 12),
                            CircleAvatar(
                              radius: 25,
                              backgroundColor: Colors.grey[100],
                              backgroundImage: photoUrl.isNotEmpty
                                  ? NetworkImage(photoUrl)
                                  : null,
                              child: photoUrl.isEmpty
                                  ? Icon(Icons.person, color: deepTeal)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: GoogleFonts.cairo(
                                      fontWeight: FontWeight.w900,
                                      fontSize: isTop3 ? 15 : 14,
                                      color: deepTeal,
                                    ),
                                  ),
                                  if (isTop3)
                                    Text(
                                      rank == 1
                                          ? "متصدر الترتيب 🥇"
                                          : "خبير متميز ✨",
                                      style: GoogleFonts.cairo(
                                          fontSize: 10,
                                          color: safetyOrange,
                                          fontWeight: FontWeight.bold),
                                    ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color:
                                    isTop3 ? deepTeal : const Color(0xFFF0F4F5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "${data['points'] ?? 0} ن",
                                style: GoogleFonts.poppins(
                                  color: isTop3 ? Colors.white : deepTeal,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
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
    if (rank == 2) return const Color(0xFF95A5A6); // فضي مائل للزرقة
    if (rank == 3) return const Color(0xFFD35400); // برونزي عميق
    return Colors.grey;
  }

  Widget _buildRankBadge(int rank) {
    if (rank <= 3) {
      return Icon(Icons.workspace_premium_rounded,
          color: _getRankColor(rank), size: rank == 1 ? 32 : 28);
    }
    return Container(
      width: 30,
      alignment: Alignment.center,
      child: Text(
        "#$rank",
        style: GoogleFonts.poppins(
            fontSize: 14, fontWeight: FontWeight.w800, color: Colors.grey[400]),
      ),
    );
  }
}

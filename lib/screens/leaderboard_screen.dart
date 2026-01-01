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
            // هيدر تعريفي
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
                // الاستماع اللحظي لمجموعة المستخدمين مرتبة حسب النقاط
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
                        child: Text("لا يوجد متنافسون حالياً",
                            style: GoogleFonts.cairo()));
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    padding: const EdgeInsets.all(15),
                    itemBuilder: (context, index) {
                      var userDoc = snapshot.data!.docs[index];
                      var data = userDoc.data() as Map<String, dynamic>;

                      int rank = index + 1;

                      // جلب الاسم لحظياً
                      String name = data['name'] ?? "بطل Pro مجهول";
                      // جلب رابط الصورة لحظياً
                      String photoUrl = data['photoUrl'] ?? "";

                      bool isTop3 = rank <= 3;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
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
                            // ترتيب البطل
                            _buildRankBadge(rank),
                            const SizedBox(width: 12),

                            // الصورة الشخصية للبطل (تحدث لحظياً)
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: photoUrl.isNotEmpty
                                  ? NetworkImage(photoUrl)
                                  : const AssetImage(
                                          'assets/user_placeholder.png')
                                      as ImageProvider,
                            ),
                            const SizedBox(width: 12),

                            // الاسم واللقب
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: GoogleFonts.cairo(
                                      fontWeight: FontWeight.bold,
                                      fontSize: isTop3 ? 15 : 13,
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

                            // النقاط
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: isTop3
                                    ? _getRankColor(rank).withOpacity(0.1)
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                "${data['points'] ?? 0} ن",
                                style: GoogleFonts.poppins(
                                  color:
                                      isTop3 ? _getRankColor(rank) : deepTeal,
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
    if (rank == 2) return const Color(0xFFC0C0C0); // فضي
    if (rank == 3) return const Color(0xFFCD7F32); // برونزي
    return Colors.grey;
  }

  Widget _buildRankBadge(int rank) {
    if (rank <= 3) {
      return Icon(Icons.emoji_events_rounded,
          color: _getRankColor(rank), size: rank == 1 ? 32 : 26);
    }
    return Container(
      width: 26,
      alignment: Alignment.center,
      child: Text(
        "$rank",
        style: GoogleFonts.poppins(
            fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[400]),
      ),
    );
  }
}

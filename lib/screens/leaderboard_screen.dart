import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color deepTeal = Color(0xFF1B4D57);
    const Color safetyOrange = Color(0xFFE67E22);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: Column(
        children: [
          // هيدر لوحة المتصدرين
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: deepTeal,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                const Icon(Icons.emoji_events, color: Colors.amber, size: 50),
                const SizedBox(height: 10),
                Text(
                  "لوحة المتصدرين",
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "أفضل المحترفين العقاريين لهذا الأسبوع",
                  style: GoogleFonts.cairo(color: Colors.white70, fontSize: 13),
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
                  return const Center(
                      child: CircularProgressIndicator(color: safetyOrange));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text("لا يوجد متسابقين حالياً",
                        style: GoogleFonts.cairo()),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var userData = snapshot.data!.docs[index].data()
                        as Map<String, dynamic>;
                    bool isTopThree = index < 3;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                          )
                        ],
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              isTopThree ? Colors.amber : Colors.grey[200],
                          child: Text(
                            "${index + 1}",
                            style: TextStyle(
                              color: isTopThree ? Colors.white : deepTeal,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          userData['name'] ?? "لاعب مجهول",
                          style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold, color: deepTeal),
                        ),
                        subtitle: Text("${userData['points'] ?? 0} نقطة",
                            style: GoogleFonts.cairo(fontSize: 12)),
                        trailing: isTopThree
                            ? const Icon(Icons.stars, color: Colors.amber)
                            : const Icon(Icons.arrow_forward_ios,
                                size: 14, color: Colors.grey),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

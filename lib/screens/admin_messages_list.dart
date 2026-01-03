import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'admin_reply_screen.dart';
import 'package:intl/intl.dart'; // ستحتاجين لإضافة حزمة intl في pubspec.yaml لتنسيق الوقت

class AdminMessagesList extends StatelessWidget {
  const AdminMessagesList({super.key});

  @override
  Widget build(BuildContext context) {
    final Color deepTeal = const Color(0xFF1B4D57);
    final Color safetyOrange = const Color(0xFFE67E22);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F8),
      appBar: AppBar(
        title: Text(
          "صندوق رسائل الأبطال",
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: deepTeal,
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // ترتيب المحادثات حسب الأحدث تعديلاً (آخر رسالة وصلت)
        stream: FirebaseFirestore.instance
            .collection('support_chats')
            .orderBy('lastUpdate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "لا توجد استفسارات حالياً",
                    style: GoogleFonts.cairo(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final String name = data['userName'] ?? "مستشار عقاري";
              final bool isUnread = data['unreadByAdmin'] ?? false;

              // تنسيق الوقت
              String formattedTime = "";
              if (data['lastUpdate'] != null) {
                DateTime dt = (data['lastUpdate'] as Timestamp).hisDateTime();
                formattedTime = DateFormat('hh:mm a').format(dt);
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: isUnread ? 4 : 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: isUnread
                      ? BorderSide(
                          color: safetyOrange.withOpacity(0.5),
                          width: 1,
                        )
                      : BorderSide.none,
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        backgroundColor: deepTeal.withOpacity(0.1),
                        child: Icon(Icons.person, color: deepTeal),
                      ),
                      if (isUnread)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: safetyOrange,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.cairo(
                          fontWeight: isUnread
                              ? FontWeight.w900
                              : FontWeight.bold,
                          color: deepTeal,
                        ),
                      ),
                      Text(
                        formattedTime,
                        style: GoogleFonts.cairo(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    data['lastMessage'] ?? "رسالة جديدة",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontWeight: isUnread
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isUnread ? Colors.black87 : Colors.grey,
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: deepTeal.withOpacity(0.3),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminReplyScreen(
                          userId: docs[index].id,
                          userName: name,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// إضافة Extension بسيطة لتحويل Timestamp
extension on Timestamp {
  DateTime hisDateTime() => this.toDate();
}

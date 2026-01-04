import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// استيراد الثوابت والصفحات حسب الهيكل المعتمد
import 'package:lpro2_quiz/core/constants/app_colors.dart';
import 'package:lpro2_quiz/presentation/screens/admin_reply_screen.dart';

class AdminMessagesList extends StatelessWidget {
  const AdminMessagesList({super.key});

  @override
  Widget build(BuildContext context) {
    // الاعتماد على الألوان المركزية
    const Color deepTeal = AppColors.primaryDeepTeal;
    const Color safetyOrange = AppColors.secondaryOrange;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Text(
          "صندوق الرسائل",
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: deepTeal,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('support_chats')
            .orderBy('lastUpdate', descending: true)
            .limit(50) // تحسين جوهري: جلب أحدث 50 محادثة فقط لسرعة الأداء
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

              // تنسيق الوقت بشكل آمن واحترافي
              String formattedTime = "";
              if (data['lastUpdate'] != null) {
                DateTime dt = (data['lastUpdate'] as Timestamp).toDate();
                formattedTime = DateFormat('hh:mm a').format(dt);
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: isUnread ? 4 : 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: isUnread
                      ? BorderSide(
                          color: safetyOrange.withValues(alpha: 0.5),
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
                        backgroundColor: deepTeal.withValues(alpha: 0.1),
                        child: const Icon(Icons.person, color: deepTeal),
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
                      Expanded(
                        child: Text(
                          name,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(
                            fontWeight:
                                isUnread ? FontWeight.w900 : FontWeight.bold,
                            color: deepTeal,
                            fontSize: 15,
                          ),
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
                      fontWeight:
                          isUnread ? FontWeight.bold : FontWeight.normal,
                      color: isUnread ? Colors.black87 : Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: deepTeal.withValues(alpha: 0.3),
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

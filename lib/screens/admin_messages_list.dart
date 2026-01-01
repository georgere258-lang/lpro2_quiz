import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'admin_reply_screen.dart';

class AdminMessagesList extends StatelessWidget {
  const AdminMessagesList({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F8),
      appBar: AppBar(
        title: Text("صندوق الرسائل",
            style: GoogleFonts.cairo(
                color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1B4D57),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance.collection('support_chats').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
                child:
                    Text("لا توجد رسائل حالياً", style: GoogleFonts.cairo()));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final String name = data['userName'] ?? "مستشار عقاري";

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF1B4D57),
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(name,
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                  subtitle:
                      Text(data['lastMessage'] ?? "رسالة جديدة", maxLines: 1),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    // تصحيح الأقواس هنا بالمللي
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

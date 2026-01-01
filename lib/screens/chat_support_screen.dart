import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatSupportScreen extends StatefulWidget {
  const ChatSupportScreen({super.key});

  @override
  State<ChatSupportScreen> createState() => _ChatSupportScreenState();
}

class _ChatSupportScreenState extends State<ChatSupportScreen> {
  final TextEditingController _msgController = TextEditingController();
  final User? user = FirebaseAuth.instance.currentUser;
  final Color deepTeal = const Color(0xFF1B4D57);

  void _send() async {
    if (_msgController.text.trim().isEmpty) return;
    await FirebaseFirestore.instance.collection('support_tickets').add({
      'userId': user?.uid,
      'userName': user?.displayName ?? "مستخدم برو",
      'message': _msgController.text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
      'isAdmin': false,
    });
    _msgController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
            backgroundColor: deepTeal,
            title: Text("مركز المساعدة",
                style: GoogleFonts.cairo(color: Colors.white)),
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.white)),
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('support_tickets')
                    .where('userId', isEqualTo: user?.uid)
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const Center(child: CircularProgressIndicator());
                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(15),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var data = snapshot.data!.docs[index].data()
                          as Map<String, dynamic>;
                      bool isAdmin = data['isAdmin'] ?? false;
                      return Align(
                        alignment: isAdmin
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: isAdmin
                                  ? Colors.grey[200]
                                  : deepTeal.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(15)),
                          child: Text(data['message'] ?? "",
                              style: GoogleFonts.cairo(fontSize: 14)),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                      child: TextField(
                          controller: _msgController,
                          decoration: InputDecoration(
                              hintText: "كيف يمكننا مساعدتك؟",
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30))))),
                  const SizedBox(width: 10),
                  CircleAvatar(
                      backgroundColor: deepTeal,
                      child: IconButton(
                          onPressed: _send,
                          icon: const Icon(Icons.send, color: Colors.white))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

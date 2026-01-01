import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminReplyScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const AdminReplyScreen(
      {super.key, required this.userId, required this.userName});

  @override
  State<AdminReplyScreen> createState() => _AdminReplyScreenState();
}

class _AdminReplyScreenState extends State<AdminReplyScreen> {
  final TextEditingController _replyController = TextEditingController();
  final Color deepTeal = const Color(0xFF1B4D57);

  void _sendReply() async {
    if (_replyController.text.trim().isEmpty) return;

    String replyText = _replyController.text.trim();
    _replyController.clear();

    await FirebaseFirestore.instance
        .collection('support_chats')
        .doc(widget.userId)
        .collection('messages')
        .add({
      'senderId': 'admin',
      'text': replyText,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance
        .collection('support_chats')
        .doc(widget.userId)
        .update({
      'lastMessage': "رد الإدارة: $replyText",
      'lastUpdate': FieldValue.serverTimestamp(),
      'unreadByAdmin': false,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("الرد على ${widget.userName}",
            style: GoogleFonts.cairo(color: Colors.white)),
        backgroundColor: deepTeal,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('support_chats')
                  .doc(widget.userId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                var docs = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    bool isAdmin = data['senderId'] == 'admin';
                    return Align(
                      alignment: isAdmin
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isAdmin ? deepTeal : Colors.grey[200],
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(data['text'] ?? "",
                            style: TextStyle(
                                color: isAdmin ? Colors.white : Colors.black)),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                Expanded(
                    child: TextField(
                        controller: _replyController,
                        decoration:
                            const InputDecoration(hintText: "اكتب الرد..."))),
                IconButton(
                    icon: const Icon(Icons.send, color: Color(0xFF1B4D57)),
                    onPressed: _sendReply),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

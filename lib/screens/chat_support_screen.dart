import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatSupportScreen extends StatefulWidget {
  const ChatSupportScreen({super.key});
  @override
  State<ChatSupportScreen> createState() => _ChatSupportScreenState();
}

class _ChatSupportScreenState extends State<ChatSupportScreen> {
  final TextEditingController _msg = TextEditingController();
  final User? user = FirebaseAuth.instance.currentUser;

  void _send() async {
    if (_msg.text.isEmpty || user == null) return;
    String txt = _msg.text;
    _msg.clear();
    await FirebaseFirestore.instance
        .collection('support_chats')
        .doc(user!.uid)
        .collection('messages')
        .add({
      'senderId': user!.uid,
      'text': txt,
      'timestamp': FieldValue.serverTimestamp(),
    });
    await FirebaseFirestore.instance
        .collection('support_chats')
        .doc(user!.uid)
        .set({
      'lastMessage': txt,
      'lastUpdate': FieldValue.serverTimestamp(),
      'userName': user!.displayName ?? "بطل Pro",
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("الدعم الفني", style: GoogleFonts.cairo())),
      body: Column(children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('support_chats')
                .doc(user?.uid)
                .collection('messages')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              return ListView.builder(
                reverse: true,
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, i) {
                  var d = snapshot.data!.docs[i].data() as Map<String, dynamic>;
                  return ListTile(title: Text(d['text'] ?? ""));
                },
              );
            },
          ),
        ),
        Row(children: [
          Expanded(child: TextField(controller: _msg)),
          IconButton(icon: const Icon(Icons.send), onPressed: _send),
        ]),
      ]),
    );
  }
}

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
  final Color deepTeal = const Color(0xFF1B4D57);
  final Color safetyOrange = const Color(0xFFE67E22);

  void _send() async {
    if (_msg.text.trim().isEmpty || user == null) return;
    String txt = _msg.text.trim();
    _msg.clear();

    // 1. إضافة الرسالة للمجموعة الفرعية
    await FirebaseFirestore.instance
        .collection('support_chats')
        .doc(user!.uid)
        .collection('messages')
        .add({
      'senderId': user!.uid,
      'text': txt,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // 2. تحديث المستند الرئيسي
    await FirebaseFirestore.instance
        .collection('support_chats')
        .doc(user!.uid)
        .set({
      'lastMessage': txt,
      'lastUpdate': FieldValue.serverTimestamp(),
      'userName': user!.displayName ?? "بطل Pro",
      'userId': user!.uid,
      'unreadByAdmin': true,
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F8),
      appBar: AppBar(
        title: Text(
          "الدعم الفني المباشر",
          style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: deepTeal,
        centerTitle: true,
        elevation: 0,
        // إضافة زر الرجوع
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('support_chats')
                  .doc(user?.uid)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                // رسالة الترحيب الثابتة التي طلبتِها
                Widget welcomeBubble = _buildChatBubble(
                  "أهلاً بك.. كيف يمكننا مساعدتك اليوم؟ إذا كان لديك اقتراح أو سؤال يطور من أدائك لا تتردد في إرساله لنا 💡",
                  false, // تظهر كأنها من الإدارة
                );

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                var docs = snapshot.data?.docs ?? [];

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(15),
                  // زيادة العدد بمقدار 1 لإظهار رسالة الترحيب في النهاية (التي هي البداية زمنياً)
                  itemCount: docs.length + 1,
                  itemBuilder: (context, i) {
                    // إذا وصلنا لآخر عنصر في القائمة (بداية المحادثة) نعرض رسالة الترحيب
                    if (i == docs.length) {
                      return welcomeBubble;
                    }

                    var d = docs[i].data() as Map<String, dynamic>;
                    bool isMe = d['senderId'] == user?.uid;
                    return _buildChatBubble(d['text'] ?? "", isMe);
                  },
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildChatBubble(String text, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? deepTeal : Colors.white,
          borderRadius: BorderRadius.only(
            topRight: const Radius.circular(15),
            topLeft: const Radius.circular(15),
            bottomLeft: isMe ? const Radius.circular(15) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(15),
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Text(
          text,
          style: GoogleFonts.cairo(
            color: isMe ? Colors.white : Colors.black87,
            fontSize: 13,
            fontWeight: isMe ? FontWeight.normal : FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F7F8),
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _msg,
                decoration: const InputDecoration(
                  hintText: "اكتب رسالتك أو اقتراحك هنا...",
                  border: InputBorder.none,
                ),
                style: GoogleFonts.cairo(fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            backgroundColor: deepTeal,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: _send,
            ),
          ),
        ],
      ),
    );
  }
}

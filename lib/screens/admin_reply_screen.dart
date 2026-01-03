import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminReplyScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const AdminReplyScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<AdminReplyScreen> createState() => _AdminReplyScreenState();
}

class _AdminReplyScreenState extends State<AdminReplyScreen> {
  final TextEditingController _replyController = TextEditingController();
  final Color deepTeal = const Color(0xFF1B4D57);

  @override
  void initState() {
    super.initState();
    _markAsRead(); // تحديث حالة الرسائل بمجرد فتح المحادثة
  }

  // دالة لجعل المحادثة "مقروءة" من قبل الأدمن في المستند الرئيسي
  void _markAsRead() async {
    await FirebaseFirestore.instance
        .collection('support_chats')
        .doc(widget.userId)
        .update({'unreadByAdmin': false});
  }

  void _sendReply() async {
    if (_replyController.text.trim().isEmpty) return;

    String replyText = _replyController.text.trim();
    _replyController.clear();

    // 1. إضافة الرد لمجموعة الرسائل الفرعية الخاصة بالمستخدم
    await FirebaseFirestore.instance
        .collection('support_chats')
        .doc(widget.userId)
        .collection('messages')
        .add({
      'senderId': 'admin',
      'text': replyText,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // 2. تحديث المستند الرئيسي بالمعلومات الجديدة للتنبيه والترتيب
    await FirebaseFirestore.instance
        .collection('support_chats')
        .doc(widget.userId)
        .update({
      'lastMessage': "رد الإدارة: $replyText",
      'lastUpdate': FieldValue.serverTimestamp(),
      'unreadByAdmin': false, // تظل مقروءة لأن الأدمن هو من أرسل
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F8),
      appBar: AppBar(
        title: Text(
          "الرد على ${widget.userName}",
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: deepTeal,
        centerTitle: true,
        elevation: 0,
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
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      "لا توجد رسائل سابقة",
                      style: GoogleFonts.cairo(color: Colors.grey),
                    ),
                  );
                }
                var docs = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(15),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    bool isAdmin = data['senderId'] == 'admin';
                    return _buildChatBubble(data['text'] ?? "", isAdmin);
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

  // تصميم فقاعة الدردشة الاحترافية المتوافق مع شاشة المستخدم
  Widget _buildChatBubble(String text, bool isAdmin) {
    return Align(
      alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isAdmin ? deepTeal : Colors.white,
          borderRadius: BorderRadius.only(
            topRight: const Radius.circular(15),
            topLeft: const Radius.circular(15),
            bottomLeft: isAdmin ? const Radius.circular(15) : Radius.zero,
            bottomRight: isAdmin ? Radius.zero : const Radius.circular(15),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          text,
          style: GoogleFonts.cairo(
            color: isAdmin ? Colors.white : Colors.black87,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // منطقة الإدخال الفخمة
  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F7F8),
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _replyController,
                decoration: const InputDecoration(
                  hintText: "اكتب الرد هنا...",
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
              onPressed: _sendReply,
            ),
          ),
        ],
      ),
    );
  }
}

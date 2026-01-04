import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// استيراد الثوابت المركزية
import '../../core/constants/app_colors.dart';

class ChatSupportScreen extends StatefulWidget {
  const ChatSupportScreen({super.key});
  @override
  State<ChatSupportScreen> createState() => _ChatSupportScreenState();
}

class _ChatSupportScreenState extends State<ChatSupportScreen> {
  final TextEditingController _msgController = TextEditingController();
  final User? user = FirebaseAuth.instance.currentUser;
  final Color deepTeal = AppColors.primaryDeepTeal;
  bool _isSending = false;

  @override
  void dispose() {
    _msgController.dispose();
    super.dispose();
  }

  void _send() async {
    if (_msgController.text.trim().isEmpty || user == null || _isSending)
      return;

    setState(() => _isSending = true);
    String txt = _msgController.text.trim();
    _msgController.clear();

    try {
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

      // 2. تحديث المستند الرئيسي لتنبيه المسؤول
      await FirebaseFirestore.instance
          .collection('support_chats')
          .doc(user!.uid)
          .set({
        'lastMessage': txt,
        'lastUpdate': FieldValue.serverTimestamp(),
        'userName': user!.displayName ?? "عضو L Pro",
        'userId': user!.uid,
        'unreadByAdmin': true,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error sending message: $e");
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Text(
          "الدعم الفني المباشر",
          style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
        ),
        backgroundColor: deepTeal,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
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
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                var docs = snapshot.data?.docs ?? [];

                return ListView.builder(
                  reverse: true,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
                  itemCount: docs.length + 1,
                  itemBuilder: (context, i) {
                    if (i == docs.length) {
                      return _buildChatBubble(
                          "أهلاً بك في L Pro.. كيف يمكننا مساعدتك اليوم؟ إذا كان لديك اقتراح أو سؤال لا تتردد في مراسلتنا 💡",
                          false,
                          null);
                    }

                    var d = docs[i].data() as Map<String, dynamic>;
                    bool isMe = d['senderId'] == user?.uid;
                    return _buildChatBubble(
                        d['text'] ?? "", isMe, d['timestamp'] as Timestamp?);
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

  Widget _buildChatBubble(String text, bool isMe, Timestamp? ts) {
    String time = ts != null ? DateFormat('hh:mm a').format(ts.toDate()) : "";

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78),
            decoration: BoxDecoration(
              color: isMe ? deepTeal : Colors.white,
              borderRadius: BorderRadius.only(
                topRight: const Radius.circular(18),
                topLeft: const Radius.circular(18),
                bottomLeft: isMe ? const Radius.circular(18) : Radius.zero,
                bottomRight: isMe ? Radius.zero : const Radius.circular(18),
              ),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 3)),
              ],
            ),
            child: Text(
              text,
              style: GoogleFonts.cairo(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 13,
                height: 1.5,
                fontWeight: isMe ? FontWeight.normal : FontWeight.w600,
              ),
            ),
          ),
          if (time.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Text(time,
                  style: const TextStyle(fontSize: 9, color: Colors.grey)),
            ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 10,
        top: 10,
        left: 15,
        right: 15,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, -5))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: AppColors.scaffoldBackground,
                borderRadius: BorderRadius.circular(28),
              ),
              child: TextField(
                controller: _msgController,
                onSubmitted: (_) => _send(),
                decoration: const InputDecoration(
                  hintText: "اكتب رسالتك هنا...",
                  hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                  border: InputBorder.none,
                ),
                style: GoogleFonts.cairo(fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _send,
            child: CircleAvatar(
              backgroundColor: deepTeal,
              radius: 24,
              child: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send_rounded,
                      color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}

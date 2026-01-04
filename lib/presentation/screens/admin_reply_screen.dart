import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

// استيراد الثوابت المركزية لتوحيد الهوية البصرية
import '../../core/constants/app_colors.dart';

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
  final Color deepTeal = AppColors.primaryDeepTeal;
  bool _isSending = false; // لمنع الإرسال المتعدد

  @override
  void initState() {
    super.initState();
    _markAsRead();
  }

  @override
  void dispose() {
    // خطوة هندسية هامة لمنع تسريب الذاكرة
    _replyController.dispose();
    super.dispose();
  }

  void _markAsRead() async {
    try {
      await FirebaseFirestore.instance
          .collection('support_chats')
          .doc(widget.userId)
          .update({'unreadByAdmin': false});
    } catch (e) {
      debugPrint("Error marking as read: $e");
    }
  }

  void _sendReply() async {
    if (_replyController.text.trim().isEmpty || _isSending) return;

    setState(() => _isSending = true);
    String replyText = _replyController.text.trim();
    _replyController.clear();

    try {
      // 1. إضافة الرد لمجموعة الرسائل الفرعية
      await FirebaseFirestore.instance
          .collection('support_chats')
          .doc(widget.userId)
          .collection('messages')
          .add({
        'senderId': 'admin',
        'text': replyText,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 2. تحديث المستند الرئيسي (Metadata)
      await FirebaseFirestore.instance
          .collection('support_chats')
          .doc(widget.userId)
          .update({
        'lastMessage': "رد الإدارة: $replyText",
        'lastUpdate': FieldValue.serverTimestamp(),
        'unreadByAdmin': false,
      });
    } catch (e) {
      _showErrorSnackBar("فشل إرسال الرد، حاول مجدداً");
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
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
            fontSize: 16,
          ),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
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

  Widget _buildChatBubble(String text, bool isAdmin) {
    return Align(
      alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isAdmin ? deepTeal : Colors.white,
          borderRadius: BorderRadius.only(
            topRight: const Radius.circular(18),
            topLeft: const Radius.circular(18),
            bottomLeft: isAdmin ? const Radius.circular(18) : Radius.zero,
            bottomRight: isAdmin ? Radius.zero : const Radius.circular(18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          text,
          style: GoogleFonts.cairo(
            color: isAdmin ? Colors.white : Colors.black87,
            fontSize: 13,
            height: 1.5,
          ),
        ),
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
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F7F8),
                borderRadius: BorderRadius.circular(28),
              ),
              child: TextField(
                controller: _replyController,
                onSubmitted: (_) => _sendReply(),
                decoration: const InputDecoration(
                  hintText: "اكتب الرد هنا...",
                  hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                  border: InputBorder.none,
                ),
                style: GoogleFonts.cairo(fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendReply,
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

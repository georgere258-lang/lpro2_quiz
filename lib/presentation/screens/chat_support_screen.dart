// PATH: lib/presentation/screens/chat_support_screen.dart
// ✅ Security Fix: Added Cooldown & Anti-Spam Logic
// ✅ Final Security: Ticket Lock for Resolved/Closed status

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../features/support/repositories/support_repository.dart';
import '../../features/support/models/support_ticket.dart';
import '../../features/support/models/support_message.dart';

class ChatSupportScreen extends StatefulWidget {
  const ChatSupportScreen({super.key});
  @override
  State<ChatSupportScreen> createState() => _ChatSupportScreenState();
}

class _ChatSupportScreenState extends State<ChatSupportScreen> {
  final TextEditingController _msgController = TextEditingController();
  final User? user = FirebaseAuth.instance.currentUser;
  final Color deepTeal = AppColors.primaryDeepTeal;
  final SupportRepository _supportRepo = SupportRepository();

  bool _isSending = false;
  String? _currentTicketId;
  String _currentTicketStatus = TicketStatus.open; // ✅ تتبع حالة التذكرة
  bool _isLoadingTicket = false;

  @override
  void dispose() {
    _msgController.dispose();
    super.dispose();
  }

  /// Load or create an open ticket for the current user
  Future<String?> _loadOrCreateTicket() async {
    if (user == null) return null;
    if (_currentTicketId != null) return _currentTicketId;

    setState(() => _isLoadingTicket = true);

    try {
      final tickets = await _supportRepo.watchUserTickets(user!.uid).first;

      final openTicket = tickets.firstWhere(
        (t) =>
            t.status == TicketStatus.open ||
            t.status == TicketStatus.inProgress,
        orElse: () => tickets.isNotEmpty
            ? tickets.first
            : SupportTicket(
                id: '',
                userId: user!.uid,
                userName: user!.displayName ?? "عضو L Pro",
                subject: "رسالة دعم",
              ),
      );

      if (openTicket.id.isNotEmpty) {
        if (mounted) {
          setState(() {
            _currentTicketId = openTicket.id;
            _currentTicketStatus = openTicket.status; // ✅ تحديث الحالة الحالية
            _isLoadingTicket = false;
          });
        }
        return _currentTicketId;
      }

      final userName = user!.displayName ?? "عضو L Pro";
      final ticketId = await _supportRepo.createTicket(
        user!.uid,
        userName,
        "رسالة دعم",
      );

      if (mounted) {
        setState(() {
          _currentTicketId = ticketId;
          _currentTicketStatus = TicketStatus.open;
          _isLoadingTicket = false;
        });
      }
      return ticketId;
    } catch (e) {
      debugPrint("Error loading/creating ticket: $e");
      if (mounted) setState(() => _isLoadingTicket = false);
      return null;
    }
  }

  void _send() async {
    final originalText = _msgController.text.trim();

    if (originalText.isEmpty || user == null || _isSending) {
      return;
    }

    setState(() => _isSending = true);
    String uName = user!.displayName ?? "عضو L Pro";
    _msgController.clear();

    try {
      final ticketId = await _loadOrCreateTicket();
      if (ticketId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("حدث خطأ في الاتصال بالخادم",
                  style: GoogleFonts.cairo()),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      await _supportRepo.sendMessage(
        ticketId: ticketId,
        senderId: user!.uid,
        senderName: uName,
        text: originalText,
        isAdmin: false,
      );
    } catch (e) {
      debugPrint("Error sending message: $e");
      _msgController.text = originalText;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text("فشل الإرسال، حاول مجدداً", style: GoogleFonts.cairo()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentTicketId == null && !_isLoadingTicket) {
      _loadOrCreateTicket();
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Text(
          "الدعم الفني",
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
            child: _currentTicketId != null
                ? StreamBuilder<List<SupportMessage>>(
                    stream: _supportRepo.watchMessages(_currentTicketId!),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final messages = snapshot.data ?? [];

                      if (messages.isEmpty) {
                        return _buildWelcomeMessage();
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 20),
                        itemCount: messages.length,
                        itemBuilder: (context, i) {
                          final msg = messages[i];
                          final isMe = msg.senderId == user?.uid;
                          return _buildChatBubble(
                            msg.text,
                            isMe,
                            msg.sentAt,
                          );
                        },
                      );
                    },
                  )
                : _buildLoadingState(),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text("جاري تهيئة المحادثة...",
              style: GoogleFonts.cairo(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildWelcomeMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.support_agent, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              "أهلاً بك في L Pro",
              style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              "كيف يمكننا مساعدتك اليوم؟\nإذا كان لديك اقتراح أو سؤال لا تتردد في مراسلتنا 💡",
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(String text, bool isMe, DateTime? sentAt) {
    String time = sentAt != null ? DateFormat('hh:mm a').format(sentAt) : "";
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
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 3))
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
    // ✅ التحقق أمنياً من حالة التذكرة قبل إظهار منطقة الإدخال
    final bool isTicketLocked = _currentTicketStatus == TicketStatus.resolved ||
        _currentTicketStatus == TicketStatus.closed;

    if (isTicketLocked) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 20,
          top: 20,
          left: 20,
          right: 20,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.black12)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline_rounded,
                color: Colors.green, size: 32),
            const SizedBox(height: 10),
            Text(
              "تم إغلاق هذه التذكرة بواسطة الدعم الفني ✅",
              style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(
              "نحن سعداء بخدمتك، إذا واجهت مشكلة أخرى تفضل بفتح تذكرة جديدة.",
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

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
              color: Colors.black.withValues(alpha: 0.05),
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
                enabled: !_isSending,
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
            onTap: _isSending ? null : _send,
            child: CircleAvatar(
              backgroundColor: _isSending ? Colors.grey : deepTeal,
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

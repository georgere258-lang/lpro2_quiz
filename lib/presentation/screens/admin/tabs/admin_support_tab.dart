// PATH: lib/presentation/screens/admin/tabs/admin_support_tab.dart
// Support tab for admin panel

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../features/support/models/support_ticket.dart';
import '../../../../features/support/repositories/support_repository.dart';
import '../widgets/admin_shared_widgets.dart';

class AdminSupportTab extends StatelessWidget {
  final SupportRepository supportRepo;
  final void Function(bool) setSaving;
  final void Function(String) snack;

  const AdminSupportTab({
    super.key,
    required this.supportRepo,
    required this.setSaving,
    required this.snack,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<List<SupportTicket>>(
          stream: supportRepo.watchAllTickets(),
          builder: (ctx, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final tickets = snap.data!;
            if (tickets.isEmpty) return Center(child: Text('لا توجد تذاكر', style: GoogleFonts.cairo()));
            return ListView.separated(
              itemCount: tickets.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) => _ticketCard(context, tickets[i]),
            );
          },
        ),
      ),
    );
  }

  Widget _ticketCard(BuildContext context, SupportTicket t) {
    final statusColor = t.status == TicketStatus.open ? Colors.orange : t.status == TicketStatus.resolved ? Colors.green : t.status == TicketStatus.closed ? Colors.grey : Colors.blue;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: statusColor.withValues(alpha: 0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)), child: Text(t.status, style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor))),
              const Spacer(),
              Text('${t.messageCount} رسالة', style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 8),
          Text(t.subject, style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700)),
          Text(t.userName, style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey[600])),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              adminTinyBtn('استلام', () async {
                final uid = FirebaseAuth.instance.currentUser?.uid;
                if (uid == null) { snack('سجل الدخول'); return; }
                setSaving(true);
                try { await supportRepo.assignTicket(t.id, uid); snack('✅'); } catch (_) { snack('فشل'); } finally { setSaving(false); }
              }),
              adminTinyBtn('الحالة', () => _openStatusDialog(context, t)),
              adminTinyBtn('الرسائل', () => _openMessagesSheet(context, t)),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openStatusDialog(BuildContext context, SupportTicket t) async {
    String newStatus = t.status;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text('تغيير الحالة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          content: DropdownButtonFormField<String>(initialValue: newStatus, items: TicketStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => setLocal(() => newStatus = v ?? newStatus), decoration: adminDropDecor()),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('إلغاء', style: GoogleFonts.cairo())),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                setSaving(true);
                try { await supportRepo.updateStatus(t.id, newStatus); snack('✅'); } catch (_) { snack('فشل'); } finally { setSaving(false); }
              },
              child: Text('حفظ', style: GoogleFonts.cairo(color: AppColors.primaryDeepTeal)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openMessagesSheet(BuildContext context, SupportTicket t) async {
    final msgC = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text('رسائل التذكرة: ${t.subject}', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Expanded(
                  child: StreamBuilder(
                    stream: supportRepo.watchMessages(t.id),
                    builder: (ctx, snap) {
                      if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                      final msgs = snap.data!;
                      if (msgs.isEmpty) return Center(child: Text('لا توجد رسائل', style: GoogleFonts.cairo()));
                      return ListView.builder(
                        itemCount: msgs.length,
                        itemBuilder: (ctx, i) {
                          final m = msgs[i];
                          return Align(
                            alignment: m.isAdminMessage ? Alignment.centerLeft : Alignment.centerRight,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: m.isAdminMessage ? AppColors.primaryDeepTeal.withValues(alpha: 0.1) : Colors.grey[200], borderRadius: BorderRadius.circular(12)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(m.senderName, style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.w700)),
                                  Text(m.text, style: GoogleFonts.cairo(fontSize: 12)),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: adminTextField(msgC, 'رد...')),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () async {
                        if (msgC.text.trim().isEmpty) return;
                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null) { snack('سجل الدخول'); return; }
                        try {
                          await supportRepo.sendMessage(ticketId: t.id, senderId: user.uid, senderName: user.displayName ?? 'Admin', text: msgC.text.trim(), isAdmin: true);
                          msgC.clear();
                        } catch (_) { snack('فشل'); }
                      },
                      icon: const Icon(Icons.send, color: AppColors.primaryDeepTeal),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

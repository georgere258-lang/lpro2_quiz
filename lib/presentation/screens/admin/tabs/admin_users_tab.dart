// PATH: lib/presentation/screens/admin/tabs/admin_users_tab.dart
// Users tab for admin panel

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../features/users/models/user_profile.dart';
import '../../../../features/users/repositories/users_admin_repository.dart';
import '../widgets/admin_shared_widgets.dart';

class AdminUsersTab extends StatelessWidget {
  final UsersAdminRepository usersRepo;
  final void Function(bool) setSaving;
  final void Function(String) snack;
  final Future<bool> Function(String, String) confirm;

  const AdminUsersTab({
    super.key,
    required this.usersRepo,
    required this.setSaving,
    required this.snack,
    required this.confirm,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<List<UserProfile>>(
          stream: usersRepo.watchAllUsers(limit: 50),
          builder: (ctx, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final users = snap.data!;
            if (users.isEmpty) return Center(child: Text('لا يوجد مستخدمين', style: GoogleFonts.cairo()));
            return ListView.separated(
              itemCount: users.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) => _userCard(context, users[i]),
            );
          },
        ),
      ),
    );
  }

  Widget _userCard(BuildContext context, UserProfile u) {
    final roleColor = u.role == UserRole.admin ? Colors.purple : u.role == UserRole.moderator ? Colors.blue : Colors.grey;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: u.isBlocked ? Colors.red.withValues(alpha: 0.05) : Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: u.isBlocked ? Colors.red.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.08))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: roleColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)), child: Text(u.role, style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w700, color: roleColor))),
              if (u.isBlocked) ...[const SizedBox(width: 6), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)), child: Text('محظور', style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.red)))],
            ],
          ),
          const SizedBox(height: 8),
          Text(u.name ?? 'بدون اسم', style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700)),
          Text(u.email, style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey[600])),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              adminTinyBtn(u.isBlocked ? 'إلغاء الحظر' : 'حظر', () => u.isBlocked ? _unblockUser(u) : _openBlockDialog(context, u)),
              adminTinyBtn('الدور', () => _openRoleDialog(context, u)),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openBlockDialog(BuildContext context, UserProfile u) async {
    final reasonC = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('حظر المستخدم', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${u.name ?? u.email}', style: GoogleFonts.cairo()),
            const SizedBox(height: 8),
            adminTextField(reasonC, 'سبب الحظر'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('إلغاء', style: GoogleFonts.cairo())),
          TextButton(
            onPressed: () async {
              if (reasonC.text.trim().isEmpty) { snack('اكتب السبب'); return; }
              Navigator.pop(ctx);
              final adminUid = FirebaseAuth.instance.currentUser?.uid;
              if (adminUid == null) { snack('سجل الدخول'); return; }
              setSaving(true);
              try { await usersRepo.blockUser(u.uid, reasonC.text.trim(), adminUid); snack('تم الحظر ✅'); } catch (_) { snack('فشل'); } finally { setSaving(false); }
            },
            child: Text('حظر', style: GoogleFonts.cairo(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _unblockUser(UserProfile u) async {
    if (!await confirm('إلغاء الحظر؟', 'سيتم إلغاء حظر ${u.name ?? u.email}')) return;
    setSaving(true);
    try { await usersRepo.unblockUser(u.uid); snack('تم إلغاء الحظر ✅'); } catch (_) { snack('فشل'); } finally { setSaving(false); }
  }

  Future<void> _openRoleDialog(BuildContext context, UserProfile u) async {
    String newRole = u.role;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text('تغيير الدور', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          content: DropdownButtonFormField<String>(value: newRole, items: UserRole.values.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(), onChanged: (v) => setLocal(() => newRole = v ?? newRole), decoration: adminDropDecor()),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('إلغاء', style: GoogleFonts.cairo())),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                setSaving(true);
                try { await usersRepo.updateRole(u.uid, newRole); snack('✅'); } catch (_) { snack('فشل'); } finally { setSaving(false); }
              },
              child: Text('حفظ', style: GoogleFonts.cairo(color: AppColors.primaryDeepTeal)),
            ),
          ],
        ),
      ),
    );
  }
}

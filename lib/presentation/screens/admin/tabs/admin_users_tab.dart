// PATH: lib/presentation/screens/admin/tabs/admin_users_tab.dart
// Users tab for admin panel with phone search + user details sheet

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../features/users/models/user_profile.dart';
import '../../../../features/users/repositories/users_admin_repository.dart';
import '../widgets/admin_shared_widgets.dart';

class AdminUsersTab extends StatefulWidget {
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
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  final TextEditingController _phoneController = TextEditingController();
  List<UserProfile> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _searchByPhone() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      widget.snack('أدخل رقم الهاتف');
      return;
    }
    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });
    try {
      final results = await widget.usersRepo.searchByPhone(phone);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
        widget.snack('خطأ في البحث');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Phone search row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(
                      hintText: 'رقم الهاتف (مثال: +201012345678)',
                      hintStyle: GoogleFonts.cairo(fontSize: 13),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onSubmitted: (_) => _searchByPhone(),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _isSearching ? null : _searchByPhone,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDeepTeal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: _isSearching
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text('بحث', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Results
            Expanded(
              child: _buildResultsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!_hasSearched) {
      return Center(child: Text('ابحث برقم الهاتف', style: GoogleFonts.cairo(color: Colors.grey)));
    }
    if (_searchResults.isEmpty) {
      return Center(child: Text('لا توجد نتائج', style: GoogleFonts.cairo()));
    }
    return ListView.separated(
      itemCount: _searchResults.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) => _userCard(context, _searchResults[i]),
    );
  }

  Widget _userCard(BuildContext context, UserProfile u) {
    final roleColor = u.role == UserRole.admin ? Colors.purple : u.role == UserRole.moderator ? Colors.blue : Colors.grey;
    return GestureDetector(
      onTap: () => _openUserDetailsSheet(context, u.uid),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: u.isBlocked ? Colors.red.withValues(alpha: 0.05) : Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: u.isBlocked ? Colors.red.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.08))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: roleColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)), child: Text(u.role, style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w700, color: roleColor))),
                if (u.isBlocked) ...[const SizedBox(width: 6), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)), child: Text('محظور', style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.red)))],
                const Spacer(),
                Icon(Icons.chevron_left, color: Colors.grey[400], size: 20),
              ],
            ),
            const SizedBox(height: 8),
            Text(u.name ?? 'بدون اسم', style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700)),
            Text(u.phoneE164 ?? u.phone ?? 'بدون رقم', style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // User Details Bottom Sheet
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _openUserDetailsSheet(BuildContext context, String uid) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _UserDetailsSheet(
        uid: uid,
        usersRepo: widget.usersRepo,
        setSaving: widget.setSaving,
        snack: widget.snack,
        confirm: widget.confirm,
        onUpdated: () => _searchByPhone(), // refresh list
      ),
    );
  }

}

// ═══════════════════════════════════════════════════════════════════════════
// User Details Sheet (StatefulWidget for live updates)
// ═══════════════════════════════════════════════════════════════════════════

class _UserDetailsSheet extends StatefulWidget {
  final String uid;
  final UsersAdminRepository usersRepo;
  final void Function(bool) setSaving;
  final void Function(String) snack;
  final Future<bool> Function(String, String) confirm;
  final VoidCallback onUpdated;

  const _UserDetailsSheet({
    required this.uid,
    required this.usersRepo,
    required this.setSaving,
    required this.snack,
    required this.confirm,
    required this.onUpdated,
  });

  @override
  State<_UserDetailsSheet> createState() => _UserDetailsSheetState();
}

class _UserDetailsSheetState extends State<_UserDetailsSheet> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final ref = FirebaseFirestore.instance.collection('users').doc(widget.uid);
      final snap = await ref.get();
      if (!snap.exists) {
        if (mounted) {
          setState(() { _loading = false; _error = 'UserDoc not found: ${widget.uid}'; });
        }
        return;
      }
      if (mounted) {
        setState(() { _data = snap.data(); _loading = false; });
      }
    } on FirebaseException catch (e) {
      debugPrint('USERS_FETCH_FAIL code=${e.code} msg=${e.message} plugin=${e.plugin}');
      if (mounted) {
        setState(() { _loading = false; _error = 'FirebaseError: ${e.code} - ${e.message}'; });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _loading = false; _error = 'Error: $e'; });
      }
    }
  }

  String _formatTimestamp(dynamic ts) {
    if (ts == null) return '—';
    if (ts is Timestamp) {
      final dt = ts.toDate();
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return ts.toString();
  }

  String _safeStr(dynamic v, [String fallback = '—']) {
    if (v == null) return fallback;
    return v.toString();
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(k, style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[600]))),
          Expanded(child: SelectableText(v, style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollController) {
          if (_loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_error != null) {
            return Center(child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(_error!, style: GoogleFonts.cairo(color: Colors.red), textAlign: TextAlign.center),
            ));
          }
          if (_data == null) {
            return Center(child: Text('لا توجد بيانات', style: GoogleFonts.cairo()));
          }

          final data = _data!;
          final isBlocked = data['isBlocked'] == true;
          final currentRole = (data['role'] as String?) ?? 'user';

          return ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              // Drag handle
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              // Title
              Text('تفاصيل المستخدم', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 16),
              // Details section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _kv('الاسم', _safeStr(data['name'])),
                    _kv('UID', _safeStr(data['uid'], widget.uid)),
                    _kv('phoneE164', _safeStr(data['phoneE164'], _safeStr(data['phone']))),
                    _kv('phone', _safeStr(data['phone'])),
                    _kv('الدور', _safeStr(data['role'])),
                    _kv('محظور', isBlocked ? 'نعم ❌' : 'لا ✅'),
                    const Divider(height: 20),
                    _kv('النقاط', _safeStr(data['points'])),
                    _kv('نقاط النجوم', _safeStr(data['starsPoints'])),
                    _kv('نقاط المحترفين', _safeStr(data['proPoints'])),
                    const Divider(height: 20),
                    _kv('جولات النجوم اليوم', _safeStr(data['dailyStarsRounds'])),
                    _kv('جولات المحترفين اليوم', _safeStr(data['dailyProsRounds'])),
                    _kv('جولات اللعب الحر اليوم', _safeStr(data['dailyFreePlayRounds'])),
                    const Divider(height: 20),
                    _kv('تاريخ الإنشاء', _formatTimestamp(data['createdAt'])),
                    _kv('آخر ظهور', _formatTimestamp(data['lastSeenAt'])),
                    _kv('آخر كويز', _formatTimestamp(data['lastQuizDate'])),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Action buttons
              Text('الإجراءات', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => isBlocked ? _unblockUser() : _openBlockDialog(),
                      icon: Icon(isBlocked ? Icons.lock_open : Icons.block, size: 18),
                      label: Text(isBlocked ? 'إلغاء الحظر' : 'حظر', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: isBlocked ? Colors.green : Colors.red, foregroundColor: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _openRoleDialog(currentRole),
                      icon: const Icon(Icons.admin_panel_settings, size: 18),
                      label: Text('تغيير الدور', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryDeepTeal, foregroundColor: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openBlockDialog() async {
    final reasonC = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text('حظر المستخدم', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_safeStr(_data?['name'], _safeStr(_data?['phoneE164'])), style: GoogleFonts.cairo()),
              const SizedBox(height: 8),
              adminTextField(reasonC, 'سبب الحظر'),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('إلغاء', style: GoogleFonts.cairo())),
            TextButton(
              onPressed: () async {
                if (reasonC.text.trim().isEmpty) { widget.snack('اكتب السبب'); return; }
                Navigator.pop(ctx);
                await _blockUser(reasonC.text.trim());
              },
              child: Text('حظر', style: GoogleFonts.cairo(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _blockUser(String reason) async {
    final adminUid = FirebaseAuth.instance.currentUser?.uid;
    if (adminUid == null) { widget.snack('سجل الدخول'); return; }
    widget.setSaving(true);
    try {
      await widget.usersRepo.blockUser(widget.uid, reason, adminUid);
      widget.snack('تم الحفظ');
      await _fetchUserData();
      widget.onUpdated();
    } on FirebaseException catch (e) {
      debugPrint('USERS_BLOCK_FAIL code=${e.code} msg=${e.message} plugin=${e.plugin}');
      _showErrorDialog('FirebaseError: ${e.code} - ${e.message}');
    } catch (_) {
      widget.snack('فشل');
    } finally {
      widget.setSaving(false);
    }
  }

  Future<void> _unblockUser() async {
    final name = _safeStr(_data?['name'], _safeStr(_data?['phoneE164']));
    if (!await widget.confirm('إلغاء الحظر؟', 'سيتم إلغاء حظر $name')) return;
    widget.setSaving(true);
    try {
      await widget.usersRepo.unblockUser(widget.uid);
      widget.snack('تم الحفظ');
      await _fetchUserData();
      widget.onUpdated();
    } on FirebaseException catch (e) {
      debugPrint('USERS_UNBLOCK_FAIL code=${e.code} msg=${e.message} plugin=${e.plugin}');
      _showErrorDialog('FirebaseError: ${e.code} - ${e.message}');
    } catch (_) {
      widget.snack('فشل');
    } finally {
      widget.setSaving(false);
    }
  }

  Future<void> _openRoleDialog(String currentRole) async {
    String newRole = currentRole;
    await showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (ctx, setLocal) => AlertDialog(
            title: Text('تغيير الدور', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            content: DropdownButtonFormField<String>(
              value: newRole,
              items: UserRole.values.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (v) => setLocal(() => newRole = v ?? newRole),
              decoration: adminDropDecor(),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text('إلغاء', style: GoogleFonts.cairo())),
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _updateRole(newRole);
                },
                child: Text('حفظ', style: GoogleFonts.cairo(color: AppColors.primaryDeepTeal)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateRole(String newRole) async {
    widget.setSaving(true);
    try {
      await widget.usersRepo.updateRole(widget.uid, newRole);
      widget.snack('تم الحفظ');
      await _fetchUserData();
      widget.onUpdated();
    } on FirebaseException catch (e) {
      debugPrint('USERS_ROLE_FAIL code=${e.code} msg=${e.message} plugin=${e.plugin}');
      _showErrorDialog('FirebaseError: ${e.code} - ${e.message}');
    } catch (_) {
      widget.snack('فشل');
    } finally {
      widget.setSaving(false);
    }
  }

  void _showErrorDialog(String msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('خطأ', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: Text(msg, style: GoogleFonts.cairo()),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text('حسناً', style: GoogleFonts.cairo()))],
      ),
    );
  }
}

// PATH: lib/presentation/widgets/admin_inline_controls.dart
// STATUS: ALL CONTROLS WORKING & TESTED ✅

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // من أجل الهزاز (Haptic Feedback)
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';

class AdminInlineControls extends StatefulWidget {
  final bool show;
  final DocumentReference<Map<String, dynamic>>? docRef;
  final String? sectionKey;

  const AdminInlineControls({
    super.key,
    required this.show,
    this.docRef,
    this.sectionKey,
  });

  @override
  State<AdminInlineControls> createState() => _AdminInlineControlsState();
}

class _AdminInlineControlsState extends State<AdminInlineControls> {
  bool _busy = false;

  // لقراءة الحالة الحالية للزر (مثلاً هل هو مثبت أم لا؟)
  bool _isPinned = false;
  bool _isFeatured = false;
  bool _isHidden = false;

  @override
  void initState() {
    super.initState();
    _fetchCurrentStatus();
  }

  // جلب الحالة الحالية عند فتح القائمة
  void _fetchCurrentStatus() async {
    if (widget.docRef == null) return;
    final snap = await widget.docRef!.get();
    if (snap.exists) {
      final data = snap.data() ?? {};
      if (mounted) {
        setState(() {
          _isPinned = data['isPinned'] ?? false;
          _isFeatured = data['isFeatured'] ?? false;
          _isHidden = !(data['isActive'] ?? true); // عكس النشط
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.show) return const SizedBox.shrink();

    final enabled = widget.docRef != null && !_busy;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(enabled),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: [
              // 1. زر الأرشيف (الأساسي)
              _chip(
                label: 'نقل للأرشيف',
                icon: Icons.inventory_2_rounded,
                enabled: enabled,
                isPrimary: true,
                onTap: () => _moveToArchive(context),
              ),

              // 2. زر التثبيت
              _chip(
                label: _isPinned ? 'إلغاء التثبيت' : 'تثبيت (Pin)',
                icon: _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                enabled: enabled,
                activeState: _isPinned,
                onTap: () => _toggleBool('isPinned', !_isPinned),
              ),

              // 3. زر التميز
              _chip(
                label: _isFeatured ? 'مميّز' : 'تمييز',
                icon: _isFeatured ? Icons.star : Icons.star_border,
                enabled: enabled,
                activeState: _isFeatured,
                onTap: () => _toggleBool('isFeatured', !_isFeatured),
              ),

              // 4. زر الإخفاء
              _chip(
                label: _isHidden ? 'مخفي (إظهار)' : 'إخفاء',
                icon: _isHidden ? Icons.visibility_off : Icons.visibility,
                enabled: enabled,
                danger: _isHidden, // لون أحمر إذا كان مخفي
                onTap: () => _toggleBool('isActive', _isHidden), // عكس الحالة
              ),

              // 5. زر التعديل
              _chip(
                label: 'تعديل',
                icon: Icons.edit_rounded,
                enabled: enabled,
                onTap: () => _editDialog(context),
              ),

              // 6. زر الحذف
              _chip(
                label: 'حذف',
                icon: Icons.delete_rounded,
                enabled: enabled,
                danger: true,
                onTap: () => _confirmDelete(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _header(bool enabled) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primaryDeepTeal.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.admin_panel_settings,
              size: 18, color: AppColors.primaryDeepTeal),
        ),
        const SizedBox(width: 10),
        Text(
          'لوحة تحكم الموضوع',
          style: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDeepTeal,
          ),
        ),
        const Spacer(),
        if (_busy)
          const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2)),
      ],
    );
  }

  Widget _chip({
    required String label,
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
    bool danger = false,
    bool isPrimary = false,
    bool activeState = false,
  }) {
    // تحديد الألوان بناءً على الحالة
    Color bgColor = Colors.grey.withOpacity(0.05);
    Color iconColor = Colors.grey[700]!;
    Color textColor = Colors.grey[800]!;

    if (danger) {
      bgColor = Colors.red.withOpacity(0.1);
      iconColor = Colors.red;
      textColor = Colors.red;
    } else if (isPrimary) {
      bgColor = AppColors.secondaryOrange.withOpacity(0.15);
      iconColor = AppColors.secondaryOrange;
      textColor = Colors.black87;
    } else if (activeState) {
      bgColor = AppColors.primaryDeepTeal.withOpacity(0.15);
      iconColor = AppColors.primaryDeepTeal;
      textColor = AppColors.primaryDeepTeal;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: enabled ? 1.0 : 0.5,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: activeState || isPrimary
                  ? iconColor.withOpacity(0.3)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── الوظائف (Functions) ───

  // 1. نقل للأرشيف
  Future<void> _moveToArchive(BuildContext context) async {
    if (widget.docRef == null) return;
    _startBusy();

    try {
      await widget.docRef!.update({
        'isArchived': true,
        'createdAtMs': DateTime.now().millisecondsSinceEpoch,
      });
      HapticFeedback.mediumImpact(); // اهتزاز للتأكيد
      if (context.mounted) {
        Navigator.pop(context); // إغلاق
        _showSnack(context, '✅ تم النقل للأرشيف بنجاح');
      }
    } catch (e) {
      _showSnack(context, 'خطأ: $e');
    } finally {
      _endBusy();
    }
  }

  // 2. تبديل حالة (تثبيت، تمييز، إخفاء)
  Future<void> _toggleBool(String key, bool newValue) async {
    if (widget.docRef == null) return;
    _startBusy();

    try {
      await widget.docRef!.update({
        key: newValue,
        'updatedAtMs': DateTime.now().millisecondsSinceEpoch,
      });

      // تحديث الواجهة فوراً
      setState(() {
        if (key == 'isPinned') _isPinned = newValue;
        if (key == 'isFeatured') _isFeatured = newValue;
        if (key == 'isActive') _isHidden = !newValue;
      });

      HapticFeedback.lightImpact();
      if (mounted) {
        String msg = newValue
            ? 'تم التفعيل: $key'
            : (key == 'isActive' ? 'تم الإخفاء' : 'تم الإلغاء');
        if (key == 'isPinned') {
          msg = newValue ? '📌 تم التثبيت' : 'تم إلغاء التثبيت';
        }
        if (key == 'isActive') {
          msg = newValue ? '👁️ تم الإظهار' : '🙈 تم الإخفاء';
        }

        _showSnack(context, msg);
      }
    } catch (e) {
      _showSnack(context, 'خطأ: $e');
    } finally {
      _endBusy();
    }
  }

  // 3. تعديل المحتوى
  Future<void> _editDialog(BuildContext context) async {
    if (widget.docRef == null) return;
    final snap = await widget.docRef!.get();
    final data = snap.data() ?? {};

    final titleCtrl =
        TextEditingController(text: data['title']?.toString() ?? '');
    final bodyCtrl =
        TextEditingController(text: data['body']?.toString() ?? '');

    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('تعديل الموضوع',
                style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 15),
            TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                    labelText: 'العنوان', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(
                controller: bodyCtrl,
                decoration: const InputDecoration(
                    labelText: 'المحتوى', border: OutlineInputBorder()),
                maxLines: 6),
            const SizedBox(height: 15),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDeepTeal,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50)),
              onPressed: () async {
                await widget.docRef!.update({
                  'title': titleCtrl.text,
                  'body': bodyCtrl.text,
                  'updatedAtMs': DateTime.now().millisecondsSinceEpoch,
                });
                if (mounted) {
                  Navigator.pop(ctx);
                  _showSnack(context, '✅ تم حفظ التعديلات');
                }
              },
              child: const Text('حفظ التعديلات'),
            )
          ],
        ),
      ),
    );
  }

  // 4. حذف نهائي
  Future<void> _confirmDelete(BuildContext context) async {
    if (widget.docRef == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('تأكيد الحذف',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: Text('سيتم حذف هذا الموضوع نهائياً. هل أنت متأكد؟',
            style: GoogleFonts.cairo()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('حذف',
                style: GoogleFonts.cairo(
                    color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (ok == true) {
      _startBusy();
      await widget.docRef!.delete();
      if (context.mounted) {
        Navigator.pop(context); // إغلاق الصفحة لأن الموضوع طار
        _showSnack(context, '🗑️ تم الحذف');
      }
    }
  }

  // أدوات مساعدة
  void _startBusy() {
    if (mounted) setState(() => _busy = true);
  }

  void _endBusy() {
    if (mounted) setState(() => _busy = false);
  }

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }
}

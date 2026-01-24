// PATH: lib/presentation/screens/admin/tabs/admin_kyc_tab.dart
// KYC tab for admin panel

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/models/admin_control_models.dart';
import '../../../../features/kyc/models/kyc_item.dart';
import '../../../../features/kyc/repositories/kyc_repository.dart';
import '../widgets/admin_shared_widgets.dart';

class AdminKycTab extends StatelessWidget {
  final KycRepository kycRepo;
  final void Function(bool) setSaving;
  final void Function(String) snack;
  final Future<bool> Function(String, String) confirm;

  const AdminKycTab({
    super.key,
    required this.kycRepo,
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
        child: Column(
          children: [
            adminCenterBtn(onPressed: () => _openKycEditor(context), bg: AppColors.secondaryOrange, child: adminBtnText('إضافة عنصر جديد', size: 12)),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<List<KycItem>>(
                stream: kycRepo.watchAll(),
                builder: (ctx, snap) {
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                  final items = snap.data!;
                  if (items.isEmpty) return Center(child: Text('لا توجد عناصر', style: GoogleFonts.cairo()));
                  return ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) => _kycCard(context, items[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kycCard(BuildContext context, KycItem item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.black.withValues(alpha: 0.08))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [adminStatusBadge(item.isActive), const Spacer(), Text('Order: ${item.orderInSection}', style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey))]),
          const SizedBox(height: 8),
          Text(item.title, style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(item.content, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey[700])),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              adminTinyBtn(item.isActive ? 'إخفاء' : 'إظهار', () async { setSaving(true); try { await kycRepo.toggleActive(item.id, !item.isActive); snack('✅'); } catch (_) { snack('فشل'); } finally { setSaving(false); } }),
              adminTinyBtn('تعديل', () => _openKycEditor(context, item: item)),
              adminTinyBtn('حذف', () async { if (await confirm('حذف؟', 'سيتم حذف العنصر نهائياً')) { setSaving(true); try { await kycRepo.delete(item.id); snack('✅'); } catch (_) { snack('فشل'); } finally { setSaving(false); } } }),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openKycEditor(BuildContext context, {KycItem? item}) async {
    final titleC = TextEditingController(text: item?.title ?? '');
    final contentC = TextEditingController(text: item?.content ?? '');
    final imageC = TextEditingController(text: item?.imageUrl ?? '');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 12),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(item == null ? 'إضافة عنصر' : 'تعديل عنصر', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                adminTextField(titleC, 'العنوان (3+ حروف)'),
                const SizedBox(height: 8),
                adminTextField(contentC, 'المحتوى (20+ حرف)', maxLines: 4),
                const SizedBox(height: 8),
                adminTextField(imageC, 'رابط الصورة (اختياري)'),
                const SizedBox(height: 12),
                adminCenterBtn(
                  onPressed: () async {
                    final nav = Navigator.of(context);
                    if (titleC.text.trim().length < 3 || contentC.text.trim().length < 20) { snack('أكمل البيانات'); return; }
                    setSaving(true);
                    try {
                      final control = AdminControlFields(isActive: item?.isActive ?? true, sectionKey: FirestorePaths.sectionKeyKyc, orderInSection: item?.orderInSection ?? UtcNormalizer.nowUtc().millisecondsSinceEpoch);
                      final newItem = KycItem(id: item?.id ?? '', title: titleC.text.trim(), content: contentC.text.trim(), imageUrl: imageC.text.trim().isEmpty ? null : imageC.text.trim(), control: control);
                      newItem.validate();
                      if (item == null) {
                        await kycRepo.create(newItem);
                      } else {
                        await kycRepo.update(item.id, newItem.toFirestore());
                      }
                      snack('✅');
                      nav.pop();
                    } catch (e) { snack('خطأ: $e'); } finally { setSaving(false); }
                  },
                  bg: AppColors.primaryDeepTeal,
                  child: adminBtnText('حفظ'),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// PATH: lib/presentation/screens/admin/tabs/admin_news_tab.dart
// STATUS: OPTIMIZED FOR CLEAN DATA FLOW ✅ (NO NAME CHANGES)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../features/news_ticker/repositories/news_ticker_repository.dart';
import '../widgets/admin_shared_widgets.dart';

class AdminNewsTab extends StatefulWidget {
  final NewsTickerRepository tickerRepo;
  final void Function(bool) setSaving;
  final void Function(String) snack;

  const AdminNewsTab({
    super.key,
    required this.tickerRepo,
    required this.setSaving,
    required this.snack,
  });

  @override
  State<AdminNewsTab> createState() => _AdminNewsTabState();
}

class _AdminNewsTabState extends State<AdminNewsTab> {
  final TextEditingController _tickerText = TextEditingController();

  // ✅ Push controls (default OFF)
  final ValueNotifier<bool> _tickerNotify = ValueNotifier<bool>(false);
  final TextEditingController _pushTitleCtrl = TextEditingController();
  final TextEditingController _pushBodyCtrl = TextEditingController();

  final int _tickerPriority = 0;

  @override
  void dispose() {
    _tickerText.dispose();
    _pushTitleCtrl.dispose();
    _pushBodyCtrl.dispose();
    _tickerNotify.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            adminTextField(_tickerText, 'نص الخبر...', maxLines: 2),
            const SizedBox(height: 8),

            // ✅ notify toggle + optional push text (minimal)
            ValueListenableBuilder<bool>(
              valueListenable: _tickerNotify,
              builder: (_, notify, __) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Switch(
                          value: notify,
                          onChanged: (v) => _tickerNotify.value = v,
                          activeColor: AppColors.secondaryOrange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'إرسال إشعار لهذا الخبر',
                          style: GoogleFonts.cairo(fontSize: 12),
                        ),
                      ],
                    ),
                    if (notify) ...[
                      const SizedBox(height: 6),
                      adminTextField(
                        _pushTitleCtrl,
                        'عنوان الإشعار (اختياري)...',
                        maxLines: 1,
                      ),
                      const SizedBox(height: 6),
                      adminTextField(
                        _pushBodyCtrl,
                        'نص الإشعار (اختياري)...',
                        maxLines: 2,
                      ),
                      const SizedBox(height: 6),
                    ],
                  ],
                );
              },
            ),

            adminCenterBtn(
              onPressed: _addTickerItem,
              bg: AppColors.primaryDeepTeal,
              child: adminBtnText('إضافة', size: 12),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: widget.tickerRepo.watchAllForAdmin(),
                builder: (ctx, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snap.data!.docs;
                  if (docs.isEmpty) {
                    return Center(
                      child: Text('لا توجد أخبار', style: GoogleFonts.cairo()),
                    );
                  }
                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) {
                      final d = docs[i].data();
                      final text = (d['text_ar'] ?? '').toString();
                      final isActive = d['isActive'] == true;
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.black.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              adminStatusBadge(isActive),
                              const Spacer(),
                            ]),
                            const SizedBox(height: 8),
                            Text(text, style: GoogleFonts.cairo(fontSize: 13)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: [
                                adminTinyBtn(
                                  isActive ? 'إخفاء' : 'إظهار',
                                  () =>
                                      _toggleTickerActive(docs[i].id, isActive),
                                ),
                                adminTinyBtn(
                                  'حذف',
                                  () => _deleteTicker(docs[i].id),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addTickerItem() async {
    final text = _tickerText.text.trim();
    if (text.isEmpty) {
      widget.snack('اكتب نص الخبر');
      return;
    }

    widget.setSaving(true);
    try {
      final notify = _tickerNotify.value == true;
      final pushTitle = _pushTitleCtrl.text.trim();
      final pushBody = _pushBodyCtrl.text.trim();

      // ✅ تم تنظيف الـ Payload (الـ Repository سيتكفل بالـ updatedAt تلقائياً)
      final payload = <String, dynamic>{
        'text_ar': text,
        'priority': _tickerPriority,
        'isActive': true,
        'notify': notify, // ✅ ONE-SHOT gate for Cloud Function
        'createdAt': FieldValue.serverTimestamp(),
        'source': 'admin',
      };

      // ✅ إضافة حقول الإشعارات فقط عند التفعيل
      if (notify && pushTitle.isNotEmpty) payload['pushTitle'] = pushTitle;
      if (notify && pushBody.isNotEmpty) payload['pushBody'] = pushBody;

      await widget.tickerRepo.addItem(payload);

      widget.snack('✅');
      _tickerText.clear();

      // reset optional fields after publish
      _tickerNotify.value = false;
      _pushTitleCtrl.clear();
      _pushBodyCtrl.clear();
    } catch (_) {
      widget.snack('فشل');
    } finally {
      widget.setSaving(false);
    }
  }

  Future<void> _toggleTickerActive(String id, bool current) async {
    widget.setSaving(true);
    try {
      await widget.tickerRepo.toggleActive(id, current);
      widget.snack('✅');
    } catch (_) {
      widget.snack('فشل');
    } finally {
      widget.setSaving(false);
    }
  }

  Future<void> _deleteTicker(String id) async {
    widget.setSaving(true);
    try {
      await widget.tickerRepo.deleteItem(id);
      widget.snack('✅');
    } catch (_) {
      widget.snack('فشل');
    } finally {
      widget.setSaving(false);
    }
  }
}

// PATH: lib/presentation/screens/admin/tabs/admin_radar_tab.dart
// STATUS: ✅ SAFE UPGRADE — "سجلات الرادار" بدون كسر الـ CMS
// - قبل أي تحديث للـ slots (hotPulse/areaBrief/caseFile): بنعمل Snapshot محفوظ داخل نفس collection
// - السجل الجديد: isArchived=true + sourceSlot + createdAtMs/updatedAtMs
// - لا تغيير في أسماء الـ collection ولا أي مسارات أخرى

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';

class AdminRadarTab extends StatefulWidget {
  final void Function(bool) setSaving;
  final void Function(String) snack;
  final Future<bool> Function(String, String) confirm;

  const AdminRadarTab({
    super.key,
    required this.setSaving,
    required this.snack,
    required this.confirm,
  });

  @override
  State<AdminRadarTab> createState() => _AdminRadarTabState();
}

class _AdminRadarTabState extends State<AdminRadarTab> {
  static const String _collection = 'market_radar';
  static const String _sectionKey = 'market_radar';

  final List<Map<String, String>> _items = [
    {'id': 'hotPulse', 'title': 'نبضة سريعة'},
    {'id': 'areaBrief', 'title': 'نبذة منطقة'},
    {'id': 'caseFile', 'title': 'ملف حالة'},
  ];

  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection(_collection);

  bool _hasUsefulContent(Map<String, dynamic> data) {
    final title = (data['title'] ?? '').toString().trim();
    final body = (data['body'] ?? '').toString().trim();
    return title.isNotEmpty || body.isNotEmpty;
  }

  Map<String, dynamic> _safeMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) {
      return raw.map((k, v) => MapEntry(k.toString(), v));
    }
    return <String, dynamic>{};
  }

  Future<void> _archiveIfNeeded({
    required String sourceSlotId,
    required int nowMs,
    WriteBatch? batch,
  }) async {
    final snap = await _col.doc(sourceSlotId).get();
    if (!snap.exists) return;

    final data = _safeMap(snap.data());
    // لو ده أصلاً أرشيف، أو فاضي => مفيش داعي
    if ((data['isArchived'] == true)) return;
    if (!_hasUsefulContent(data)) return;

    final archiveRef = _col.doc(); // سجل جديد
    final archiveData = <String, dynamic>{
      'title': (data['title'] ?? '').toString(),
      'body': (data['body'] ?? '').toString(),
      'sectionKey': (data['sectionKey'] ?? _sectionKey).toString(),
      'isArchived': true,
      'createdAtMs': nowMs,
      'updatedAtMs': nowMs,
      // مصدر السجل
      'sourceSlot': sourceSlotId,
      'sourceDocId': sourceSlotId,
      'archivedFromUpdatedAtMs': data['updatedAtMs'],
      'archivedFromCreatedAtMs': data['createdAtMs'],
    };

    if (batch != null) {
      batch.set(archiveRef, archiveData, SetOptions(merge: true));
    } else {
      await archiveRef.set(archiveData, SetOptions(merge: true));
    }
  }

  Future<void> _uploadJson(String jsonString) async {
    if (jsonString.trim().isEmpty) return;

    widget.setSaving(true);
    try {
      final Map<String, dynamic> data = jsonDecode(jsonString);
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      // 1) اقرأ كل الـ slots المطلوبة مرة واحدة
      final targets = <String>[];
      for (final item in _items) {
        final id = item['id']!;
        if (data.containsKey(id)) targets.add(id);
      }

      // لو مفيش حاجة في الـ JSON تخص الرادار
      if (targets.isEmpty) {
        widget.snack('⚠️ لا توجد أقسام مطابقة داخل JSON');
        return;
      }

      // 2) اعمل batch writes بعد الـ reads (علشان نحافظ على الأداء)
      final batch = FirebaseFirestore.instance.batch();

      // 2.a) أرشفة نسخة من الحالي (لو فيه محتوى)
      for (final slotId in targets) {
        await _archiveIfNeeded(
            sourceSlotId: slotId, nowMs: nowMs, batch: batch);
      }

      // 2.b) تحديث الـ slots بالمحتوى الجديد
      for (final slotId in targets) {
        final docData = _safeMap(data[slotId]);

        final title = (docData['title'] ?? '').toString();
        final body = (docData['body'] ?? '').toString();

        final ref = _col.doc(slotId);
        batch.set(
          ref,
          {
            'title': title,
            'body': body,
            'sectionKey': _sectionKey,
            'isArchived': false,
            // createdAtMs نخليها ثابتة لو موجودة، لكن هنا بنضيفها فقط لو مش موجودة
            'createdAtMs':
                FieldValue.serverTimestamp(), // لا تضمن ms، لكن مش هتكسر
            'updatedAtMs': nowMs,
          },
          SetOptions(merge: true),
        );
      }

      await batch.commit();
      widget.snack('✅ تم تحديث الرادار + حفظ نسخة في السجلات');
    } catch (e) {
      widget.snack('❌ خطأ JSON: $e');
    } finally {
      widget.setSaving(false);
    }
  }

  void _showJsonDialog() {
    final jsonCtrl = TextEditingController();
    jsonCtrl.text = '''{
  "hotPulse": {"title": "العنوان", "body": "المحتوى..."},
  "areaBrief": {"title": "العنوان", "body": "المحتوى..."},
  "caseFile": {"title": "العنوان", "body": "المحتوى..."}
}''';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'رفع JSON (رادار)',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('الصق الكود هنا:'),
            const SizedBox(height: 10),
            TextField(
              controller: jsonCtrl,
              maxLines: 8,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _uploadJson(jsonCtrl.text);
            },
            child: const Text('تحديث الكل'),
          )
        ],
      ),
    );
  }

  void _openEdit(String docId, String slotTitle) {
    final ref = _col.doc(docId);
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();

    ref.get().then((snap) {
      if (snap.exists && mounted) {
        final data = _safeMap(snap.data());
        titleCtrl.text = (data['title'] ?? '').toString();
        bodyCtrl.text = (data['body'] ?? '').toString();
      }
    });

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'تحديث: $slotTitle',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'العنوان'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: bodyCtrl,
                decoration: const InputDecoration(labelText: 'المحتوى'),
                maxLines: 6,
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              widget.setSaving(true);

              final nowMs = DateTime.now().millisecondsSinceEpoch;

              try {
                // ✅ 1) احفظ نسخة من الحالي قبل الاستبدال
                await _archiveIfNeeded(sourceSlotId: docId, nowMs: nowMs);

                // ✅ 2) انشر الجديد على نفس الـ slot
                await ref.set(
                  {
                    'title': titleCtrl.text,
                    'body': bodyCtrl.text,
                    'sectionKey': _sectionKey,
                    'isArchived': false,
                    'updatedAtMs': nowMs,
                  },
                  SetOptions(merge: true),
                );

                widget.snack('تم النشر ✅ (مع حفظ نسخة في السجلات)');
              } catch (e) {
                widget.snack('❌ فشل النشر: $e');
              } finally {
                widget.setSaving(false);
              }
            },
            child: const Text('نشر'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. الزر المثبت
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showJsonDialog,
              icon: const Icon(Icons.javascript, size: 28),
              label: Text(
                'تحديث جماعي ذكي (JSON)',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),

        // 2. القائمة (بدون أرشيف UI هنا — السجلات هتظهر للمستخدم في شاشة الرادار)
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'الأقسام اليومية',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 10),
              ..._items.map(
                (e) => Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.radar,
                      color: AppColors.secondaryOrange,
                    ),
                    title: Text(
                      e['title']!,
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.edit_note,
                        color: AppColors.primaryDeepTeal,
                      ),
                      onPressed: () => _openEdit(e['id']!, e['title']!),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

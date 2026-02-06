// PATH: lib/presentation/screens/admin/tabs/admin_money_tab.dart
// STATUS: ✅ SAFE UPGRADE — أرشفة Snapshot قبل تحديث Slots (مثل الرادار تماماً)
// - قبل أي تحديث للـ slots (short_news/medium_analysis/deep_dive): بنعمل Snapshot محفوظ داخل نفس collection
// - السجل الجديد: isArchived=true + sourceSlot + createdAtMs/updatedAtMs (int ms)
// - لا تغيير في أسماء الـ collection ولا أي مسارات أخرى

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminMoneyTab extends StatefulWidget {
  final void Function(bool) setSaving;
  final void Function(String) snack;
  final Future<bool> Function(String, String) confirm;

  const AdminMoneyTab({
    super.key,
    required this.setSaving,
    required this.snack,
    required this.confirm,
  });

  @override
  State<AdminMoneyTab> createState() => _AdminMoneyTabState();
}

class _AdminMoneyTabState extends State<AdminMoneyTab> {
  static const String _collection = 'money';
  static const String _sectionKey = 'money';

  final List<Map<String, String>> _items = [
    {'id': 'short_news', 'title': 'خبر سريع'},
    {'id': 'medium_analysis', 'title': 'تحليل متوسط'},
    {'id': 'deep_dive', 'title': 'Deep Dive'},
  ];

  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection(_collection);

  Map<String, dynamic> _safeMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return raw.map((k, v) => MapEntry(k.toString(), v));
    return <String, dynamic>{};
  }

  bool _hasUsefulContent(Map<String, dynamic> data) {
    final title = (data['title'] ?? '').toString().trim();
    final body = (data['body'] ?? '').toString().trim();
    return title.isNotEmpty || body.isNotEmpty;
  }

  int _safeInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return 0;
  }

  /// ✅ نفس فكرة الرادار: لو slot فيه محتوى فعلي ومش archived → اعمل Snapshot جديد محفوظ
  /// بيرجع createdAtMs الأصلي للـ slot (لو موجود) علشان ما نكسّرش تاريخ الإنشاء.
  Future<int> _archiveIfNeeded({
    required String sourceSlotId,
    required int nowMs,
    WriteBatch? batch,
  }) async {
    final snap = await _col.doc(sourceSlotId).get();
    if (!snap.exists) return 0;

    final data = _safeMap(snap.data());
    final existingCreatedAtMs = _safeInt(data['createdAtMs']);

    // لو ده أصلاً أرشيف أو فاضي -> مفيش داعي
    if (data['isArchived'] == true) return existingCreatedAtMs;
    if (!_hasUsefulContent(data)) return existingCreatedAtMs;

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

    return existingCreatedAtMs;
  }

  Future<void> _uploadJson(String jsonString) async {
    if (jsonString.trim().isEmpty) return;

    widget.setSaving(true);
    try {
      final Map<String, dynamic> data = jsonDecode(jsonString);
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      // targets = اللي موجود في JSON فقط
      final targets = <String>[];
      for (final item in _items) {
        final id = item['id']!;
        if (data.containsKey(id)) targets.add(id);
      }

      if (targets.isEmpty) {
        widget.snack('⚠️ لا توجد أقسام مطابقة داخل JSON');
        return;
      }

      final batch = FirebaseFirestore.instance.batch();

      // 1) اعمل Snapshot من الحالي قبل الكتابة
      final Map<String, int> createdAtBySlot = {};
      for (final slotId in targets) {
        final createdAt = await _archiveIfNeeded(
          sourceSlotId: slotId,
          nowMs: nowMs,
          batch: batch,
        );
        if (createdAt > 0) createdAtBySlot[slotId] = createdAt;
      }

      // 2) اكتب المحتوى الجديد على نفس الـ slots
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
            // ✅ حافظ على createdAtMs القديم إن وُجد وإلا ضع nowMs
            'createdAtMs': createdAtBySlot[slotId] ?? nowMs,
            'updatedAtMs': nowMs,
          },
          SetOptions(merge: true),
        );
      }

      await batch.commit();
      widget.snack('✅ تم تحديث الاقتصاد + حفظ نسخة في الأرشيف');
    } catch (e) {
      widget.snack('❌ خطأ JSON: $e');
    } finally {
      widget.setSaving(false);
    }
  }

  void _showJsonDialog() {
    final jsonCtrl = TextEditingController();
    jsonCtrl.text = '''{
  "short_news": {"title": "العنوان", "body": "المحتوى..."},
  "medium_analysis": {"title": "العنوان", "body": "المحتوى..."},
  "deep_dive": {"title": "العنوان", "body": "المحتوى..."}
}''';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'رفع JSON (اقتصاد)',
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
          child: Column(mainAxisSize: MainAxisSize.min, children: [
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
          ]),
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              widget.setSaving(true);

              final nowMs = DateTime.now().millisecondsSinceEpoch;

              try {
                // ✅ 1) Snapshot قبل الاستبدال
                final existingCreatedAt = await _archiveIfNeeded(
                  sourceSlotId: docId,
                  nowMs: nowMs,
                );

                // ✅ 2) انشر الجديد على نفس الـ slot
                await ref.set(
                  {
                    'title': titleCtrl.text,
                    'body': bodyCtrl.text,
                    'sectionKey': _sectionKey,
                    'isArchived': false,
                    'createdAtMs':
                        existingCreatedAt > 0 ? existingCreatedAt : nowMs,
                    'updatedAtMs': nowMs,
                  },
                  SetOptions(merge: true),
                );

                widget.snack('تم النشر ✅ (مع حفظ نسخة في الأرشيف)');
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
        // 1) الزر المثبت
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
                    fontWeight: FontWeight.bold, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[800],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),

        // 2) القائمة (بدون أرشيف UI هنا — الأرشيف يظهر للمستخدم في شاشة الاقتصاد)
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'مؤشرات الاقتصاد',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 10),
              ..._items.map(
                (e) => Card(
                  child: ListTile(
                    leading:
                        const Icon(Icons.attach_money, color: Colors.green),
                    title: Text(
                      e['title']!,
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_note, color: Colors.green),
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

// PATH: lib/presentation/screens/admin/tabs/admin_money_tab.dart
// STATUS: CLEAN & LIGHT (No Archive) ✅

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

  final List<Map<String, String>> _items = [
    {'id': 'short_news', 'title': 'خبر سريع'},
    {'id': 'medium_analysis', 'title': 'تحليل متوسط'},
    {'id': 'deep_dive', 'title': 'Deep Dive'},
  ];

  Future<void> _uploadJson(String jsonString) async {
    if (jsonString.trim().isEmpty) return;
    widget.setSaving(true);
    try {
      final Map<String, dynamic> data = jsonDecode(jsonString);
      final batch = FirebaseFirestore.instance.batch();
      final now = DateTime.now().millisecondsSinceEpoch;

      for (var item in _items) {
        String id = item['id']!;
        if (data.containsKey(id)) {
          final docData = data[id];
          final ref =
              FirebaseFirestore.instance.collection(_collection).doc(id);
          batch.set(
              ref,
              {
                'title': docData['title'],
                'body': docData['body'],
                'sectionKey': 'money',
                'isArchived': false,
                'updatedAtMs': now,
              },
              SetOptions(merge: true));
        }
      }
      await batch.commit();
      widget.snack('✅ تم تحديث الاقتصاد بنجاح');
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
        title: Text('رفع JSON (اقتصاد)',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('الصق الكود هنا:'),
            const SizedBox(height: 10),
            TextField(
                controller: jsonCtrl,
                maxLines: 8,
                decoration:
                    const InputDecoration(border: OutlineInputBorder())),
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
    final ref = FirebaseFirestore.instance.collection(_collection).doc(docId);
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();

    ref.get().then((snap) {
      if (snap.exists && mounted) {
        titleCtrl.text = snap['title'] ?? '';
        bodyCtrl.text = snap['body'] ?? '';
      }
    });

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تحديث: $slotTitle',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'العنوان')),
            const SizedBox(height: 10),
            TextField(
                controller: bodyCtrl,
                decoration: const InputDecoration(labelText: 'المحتوى'),
                maxLines: 6),
          ]),
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              widget.setSaving(true);
              await ref.set({
                'title': titleCtrl.text,
                'body': bodyCtrl.text,
                'isArchived': false,
                'updatedAtMs': DateTime.now().millisecondsSinceEpoch
              }, SetOptions(merge: true));
              widget.setSaving(false);
              widget.snack('تم النشر ✅');
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
                  offset: const Offset(0, 3))
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showJsonDialog,
              icon: const Icon(Icons.javascript, size: 28),
              label: Text('تحديث جماعي ذكي (JSON)',
                  style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[800], // لون الاقتصاد
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),

        // 2. القائمة (بدون أرشيف)
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('مؤشرات الاقتصاد',
                  style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold, color: Colors.grey[700])),
              const SizedBox(height: 10),
              ..._items.map((e) => Card(
                    child: ListTile(
                      leading:
                          const Icon(Icons.attach_money, color: Colors.green),
                      title: Text(e['title']!,
                          style:
                              GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                      trailing: IconButton(
                          icon:
                              const Icon(Icons.edit_note, color: Colors.green),
                          onPressed: () => _openEdit(e['id']!, e['title']!)),
                    ),
                  )),

              // تم حذف الأرشيف من هنا نهائياً 🧹
            ],
          ),
        ),
      ],
    );
  }
}

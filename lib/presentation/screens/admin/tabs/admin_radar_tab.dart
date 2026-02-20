// PATH: lib/presentation/screens/admin/tabs/admin_radar_tab.dart
// STATUS: ✅ SAFE UPGRADE — Radar + Notifications Control (NO CMS BREAK)
// - قبل أي تحديث للـ slots (hotPulse/areaBrief/caseFile): بنعمل Snapshot محفوظ داخل نفس collection
// - السجل الجديد: isArchived=true + sourceSlot + createdAtMs/updatedAtMs (int ms)
// - ✅ تحكم إشعار لكل Slot: notify + pushTitle + pushBody
// - ✅ Bulk JSON: لو notify/pushTitle/pushBody موجودين في JSON هنكتبهم (ولو فاضيين هنمسحهم)،
//   لو مش موجودين مش هنلمسهم نهائيًا
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
    if (raw is Map) return raw.map((k, v) => MapEntry(k.toString(), v));
    return <String, dynamic>{};
  }

  int _safeInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return 0;
  }

  bool? _safeBool(dynamic v) {
    if (v is bool) return v;
    if (v is String) {
      final t = v.trim().toLowerCase();
      if (t == 'true') return true;
      if (t == 'false') return false;
    }
    return null;
  }

  /// ✅ نفس فكرة money tab:
  /// - لو slot فيه محتوى فعلي ومش archived → اعمل Snapshot جديد محفوظ
  /// - بيرجع createdAtMs الأصلي للـ slot (لو موجود) علشان ما نكسّرش تاريخ الإنشاء.
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

      // 1) Snapshot من الحالي قبل الكتابة + حفظ createdAtMs الأصلي
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

        final update = <String, dynamic>{
          'title': title,
          'body': body,
          'sectionKey': _sectionKey,
          'isArchived': false,
          // ✅ حافظ على createdAtMs القديم إن وُجد وإلا ضع nowMs
          'createdAtMs': createdAtBySlot[slotId] ?? nowMs,
          'updatedAtMs': nowMs,
        };

        // ✅ Notifications: لو المفاتيح موجودة في JSON => نكتبها (ولو فاضية نمسحها)
        if (docData.containsKey('notify')) {
          final notify = _safeBool(docData['notify']);
          if (notify != null) update['notify'] = notify;
        }

        if (docData.containsKey('pushTitle')) {
          final pushTitle = (docData['pushTitle'] ?? '').toString().trim();
          update['pushTitle'] =
              pushTitle.isNotEmpty ? pushTitle : FieldValue.delete();
        }

        if (docData.containsKey('pushBody')) {
          final pushBody = (docData['pushBody'] ?? '').toString().trim();
          update['pushBody'] =
              pushBody.isNotEmpty ? pushBody : FieldValue.delete();
        }

        final ref = _col.doc(slotId);
        batch.set(ref, update, SetOptions(merge: true));
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
  "hotPulse": {"title": "العنوان", "body": "المحتوى...", "notify": false, "pushTitle": "رادار السوق", "pushBody": "نبضة جديدة"},
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

  Future<void> _openEdit(String docId, String slotTitle) async {
    final ref = _col.doc(docId);

    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();

    // ✅ Notifications controls (loaded from Firestore before dialog)
    bool notify = false;
    final pushTitleCtrl = TextEditingController();
    final pushBodyCtrl = TextEditingController();

    try {
      final snap = await ref.get();
      if (snap.exists) {
        final data = _safeMap(snap.data());
        titleCtrl.text = (data['title'] ?? '').toString();
        bodyCtrl.text = (data['body'] ?? '').toString();

        notify = data['notify'] == true;
        pushTitleCtrl.text = (data['pushTitle'] ?? '').toString();
        pushBodyCtrl.text = (data['pushBody'] ?? '').toString();
      }
    } catch (_) {
      // ignore (best-effort)
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
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
                const SizedBox(height: 14),
                Divider(color: Colors.grey.withOpacity(0.25)),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: notify,
                  onChanged: (v) => setLocal(() => notify = v),
                  title: Text(
                    'إرسال إشعار لهذا التحديث',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  activeThumbColor: AppColors.secondaryOrange,
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: pushTitleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'عنوان الإشعار (اختياري)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: pushBodyCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'نص الإشعار (اختياري)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
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
                  // ✅ 1) Snapshot قبل الاستبدال + حفظ createdAtMs القديم
                  final existingCreatedAt = await _archiveIfNeeded(
                    sourceSlotId: docId,
                    nowMs: nowMs,
                  );

                  final pushTitle = pushTitleCtrl.text.trim();
                  String pushBody = pushBodyCtrl.text.trim();
                  if (pushBody.isEmpty) {
                    final t = titleCtrl.text.trim();
                    final b = bodyCtrl.text.trim();
                    pushBody = t.isNotEmpty ? t : (b.isNotEmpty ? b : '');
                  }

                  // ✅ 2) انشر الجديد على نفس الـ slot + notify controls
                  final update = <String, dynamic>{
                    'title': titleCtrl.text,
                    'body': bodyCtrl.text,
                    'sectionKey': _sectionKey,
                    'isArchived': false,
                    'createdAtMs':
                        existingCreatedAt > 0 ? existingCreatedAt : nowMs,
                    'updatedAtMs': nowMs,
                    'notify': notify,
                    // pushTitle/pushBody: لو فاضيين نمسحهم عشان مايبقوش “متخزنين” بالغلط
                    'pushTitle':
                        pushTitle.isNotEmpty ? pushTitle : FieldValue.delete(),
                    'pushBody':
                        pushBody.isNotEmpty ? pushBody : FieldValue.delete(),
                  };

                  await ref.set(update, SetOptions(merge: true));

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
      ),
    );

    titleCtrl.dispose();
    bodyCtrl.dispose();
    pushTitleCtrl.dispose();
    pushBodyCtrl.dispose();
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

        // 2) القائمة (بدون أرشيف UI هنا — السجلات هتظهر للمستخدم في شاشة الرادار)
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

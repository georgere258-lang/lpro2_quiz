// PATH: lib/presentation/screens/admin/tabs/admin_content_tab.dart
// Unified Content CMS for pro_insight + know_your_client

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/firestore_paths.dart';
import '../widgets/admin_shared_widgets.dart';

class AdminContentTab extends StatefulWidget {
  final void Function(bool) setSaving;
  final void Function(String) snack;

  const AdminContentTab({
    super.key,
    required this.setSaving,
    required this.snack,
  });

  @override
  State<AdminContentTab> createState() => _AdminContentTabState();
}

class _AdminContentTabState extends State<AdminContentTab> {
  // ═══════════════════════════════════════════════════════════════════════════
  // Content Types & Sections
  // ═══════════════════════════════════════════════════════════════════════════

  static const Map<String, String> _contentTypes = {
    'pro_insight': 'المعلومة بتفرق',
    'know_your_client': 'اعرف عميلك',
  };

  static const Map<String, List<String>> _sectionsByType = {
    'pro_insight': [
      'البداية الصح',
      'لغة العقارات',
      'سيستم السوق',
      'سيستم الشركات',
      'التعاقدات والإجراءات',
      'دراسة المشاريع',
    ],
    'know_your_client': [
      'أساسيات العميل',
      'أنماط الشخصيات',
      'الدوافع والاحتياجات',
      'الاعتراضات والردود',
      'التفاوض',
      'إغلاق الصفقة',
      'متابعة وما بعد البيع',
    ],
  };

  // Tag normalization (only for pro_insight)
  static const Map<String, String> _tagNormalization = {
    'سيستم الشركة': 'سيستم الشركات',
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // State
  // ═══════════════════════════════════════════════════════════════════════════

  String _selectedType = 'pro_insight';
  String _selectedSection = 'البداية الصح';

  // Form controllers
  final _docIdC = TextEditingController();
  final _titleC = TextEditingController();
  final _hookC = TextEditingController();
  final _articleC = TextEditingController();
  final _resetC = TextEditingController();
  final _coreC = TextEditingController();
  final _exampleC = TextEditingController();
  final _lockC = TextEditingController();
  final _bulkJsonC = TextEditingController();

  bool _isActive = true;
  bool _isFeatured = false;
  int _featuredOrder = 0;
  DateTime? _publishAt;
  DateTime? _expireAt;
  DateTime? _featuredUntil;

  bool _showBulkImport = false;

  @override
  void dispose() {
    _docIdC.dispose();
    _titleC.dispose();
    _hookC.dispose();
    _articleC.dispose();
    _resetC.dispose();
    _coreC.dispose();
    _exampleC.dispose();
    _lockC.dispose();
    _bulkJsonC.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Helpers
  // ═══════════════════════════════════════════════════════════════════════════

  String _collectionName(String type) {
    return type == 'pro_insight'
        ? FirestorePaths.proInsight
        : FirestorePaths.knowYourClient;
  }

  List<String> _normalizeTags(List<String> tags, String type) {
    final result = <String>{};
    for (var t in tags) {
      var trimmed = t.trim();
      if (trimmed.isEmpty) continue;
      // Apply normalization only for pro_insight
      if (type == 'pro_insight' && _tagNormalization.containsKey(trimmed)) {
        trimmed = _tagNormalization[trimmed]!;
      }
      result.add(trimmed);
    }
    return result.toList();
  }

  String _fmtDt(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return "$y-$m-$d $hh:$mm";
  }

  Future<DateTime?> _pickDateTime({DateTime? initial}) async {
    final now = DateTime.now();
    final init = initial ?? now;

    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      initialDate: DateTime(init.year, init.month, init.day),
    );
    if (date == null || !mounted) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(init),
    );
    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  void _clearForm() {
    _docIdC.clear();
    _titleC.clear();
    _hookC.clear();
    _articleC.clear();
    _resetC.clear();
    _coreC.clear();
    _exampleC.clear();
    _lockC.clear();
    setState(() {
      _isActive = true;
      _isFeatured = false;
      _featuredOrder = 0;
      _publishAt = null;
      _expireAt = null;
      _featuredUntil = null;
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Save Single Document
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _saveDocument() async {
    final title = _titleC.text.trim();
    final hook = _hookC.text.trim();

    // Validation
    if (title.isEmpty) {
      widget.snack('العنوان مطلوب');
      return;
    }
    if (hook.isEmpty) {
      widget.snack('Hook مطلوب');
      return;
    }

    // Build tags list (must include selected section)
    final tags = _normalizeTags([_selectedSection], _selectedType);
    if (!tags.contains(_selectedSection)) {
      tags.add(_selectedSection);
    }

    // Validate dates
    if (_publishAt != null && _expireAt != null) {
      if (_publishAt!.isAfter(_expireAt!)) {
        widget.snack('publishAt يجب أن يكون قبل expireAt');
        return;
      }
    }
    if (_featuredUntil != null && _featuredUntil!.isBefore(DateTime.now())) {
      widget.snack('featuredUntil يجب أن يكون في المستقبل');
      return;
    }

    widget.setSaving(true);

    try {
      final collection = _collectionName(_selectedType);
      final docId = _docIdC.text.trim();

      // Build data map
      final data = <String, dynamic>{
        'title': title,
        'hook': hook,
        'tags': tags,
        'isActive': _isActive,
        'isFeatured': _isFeatured,
        'featuredOrder': _featuredOrder,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Optional fields
      final article = _articleC.text.trim();
      final reset = _resetC.text.trim();
      final core = _coreC.text.trim();
      final example = _exampleC.text.trim();
      final lock = _lockC.text.trim();

      if (article.isNotEmpty) data['article'] = article;
      if (reset.isNotEmpty) data['reset'] = reset;
      if (core.isNotEmpty) data['core'] = core;
      if (example.isNotEmpty) data['example'] = example;
      if (lock.isNotEmpty) data['lock'] = lock;

      // DateTime fields
      if (_publishAt != null) {
        data['publishAt'] = Timestamp.fromDate(_publishAt!);
      }
      if (_expireAt != null) {
        data['expireAt'] = Timestamp.fromDate(_expireAt!);
      }
      if (_featuredUntil != null) {
        data['featuredUntil'] = Timestamp.fromDate(_featuredUntil!);
      }

      if (docId.isNotEmpty) {
        // Update existing document by docId
        await FirebaseFirestore.instance
            .collection(collection)
            .doc(docId)
            .update(data);
        widget.snack('تم التحديث بنجاح ✅');
      } else {
        // Check if title already exists (warn user)
        final existing = await FirebaseFirestore.instance
            .collection(collection)
            .where('title', isEqualTo: title)
            .limit(1)
            .get();

        if (existing.docs.isNotEmpty) {
          // Title exists - update it (legacy mode, risky)
          final existingDoc = existing.docs.first;
          await existingDoc.reference.update(data);
          widget.snack('تم التحديث (بالعنوان) ⚠️ (docId أفضل)');
        } else {
          // Create new document
          data['createdAt'] = FieldValue.serverTimestamp();
          await FirebaseFirestore.instance.collection(collection).add(data);
          widget.snack('تم الإنشاء بنجاح ✅');
        }
      }

      _clearForm();
    } catch (e) {
      widget.snack('فشل الحفظ: $e');
    } finally {
      widget.setSaving(false);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Publish Now
  // ═══════════════════════════════════════════════════════════════════════════

  void _publishNow() {
    setState(() {
      _publishAt = DateTime.now();
      _isActive = true;
    });
    widget.snack('تم تحديد وقت النشر = الآن');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Bulk Import
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _runBulkImport() async {
    final jsonText = _bulkJsonC.text.trim();
    if (jsonText.isEmpty) {
      widget.snack('الحقل فارغ');
      return;
    }

    List<dynamic> items;
    try {
      items = json.decode(jsonText) as List<dynamic>;
    } catch (e) {
      widget.snack('JSON غير صالح: $e');
      return;
    }

    if (items.isEmpty) {
      widget.snack('القائمة فارغة');
      return;
    }

    widget.setSaving(true);

    int importedCount = 0;
    final failures = <String>[];

    try {
      // Process in batches of 500
      for (int i = 0; i < items.length; i += 500) {
        final batch = FirebaseFirestore.instance.batch();
        final chunk = items.skip(i).take(500).toList();

        for (int j = 0; j < chunk.length; j++) {
          final index = i + j;
          final item = chunk[j];

          if (item is! Map<String, dynamic>) {
            failures.add('[$index] ليس كائن');
            continue;
          }

          // Determine type
          final type = (item['type'] ?? _selectedType).toString();
          if (!_contentTypes.containsKey(type)) {
            failures.add('[$index] نوع غير معروف: $type');
            continue;
          }

          // Validate section
          final section = (item['section'] ?? '').toString().trim();
          final validSections = _sectionsByType[type] ?? [];
          if (section.isEmpty || !validSections.contains(section)) {
            failures.add('[$index] قسم غير صالح: $section');
            continue;
          }

          // Validate title/hook
          final title = (item['title'] ?? '').toString().trim();
          final hook = (item['hook'] ?? '').toString().trim();
          if (title.isEmpty) {
            failures.add('[$index] العنوان مطلوب');
            continue;
          }
          if (hook.isEmpty) {
            failures.add('[$index] Hook مطلوب');
            continue;
          }

          // Build tags
          final rawTags = <String>[section];
          if (item['tags'] is List) {
            for (final t in item['tags']) {
              rawTags.add(t.toString());
            }
          }
          final tags = _normalizeTags(rawTags, type);
          if (!tags.contains(section)) {
            tags.add(section);
          }

          // Build data
          final data = <String, dynamic>{
            'title': title,
            'hook': hook,
            'tags': tags,
            'isActive': item['isActive'] == true,
            'isFeatured': item['isFeatured'] == true,
            'featuredOrder': (item['featuredOrder'] is int)
                ? item['featuredOrder']
                : int.tryParse((item['featuredOrder'] ?? '0').toString()) ?? 0,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          };

          // Optional fields
          final article = (item['article'] ?? '').toString().trim();
          final reset = (item['reset'] ?? '').toString().trim();
          final core = (item['core'] ?? '').toString().trim();
          final example = (item['example'] ?? '').toString().trim();
          final lock = (item['lock'] ?? '').toString().trim();

          if (article.isNotEmpty) data['article'] = article;
          if (reset.isNotEmpty) data['reset'] = reset;
          if (core.isNotEmpty) data['core'] = core;
          if (example.isNotEmpty) data['example'] = example;
          if (lock.isNotEmpty) data['lock'] = lock;

          // DateTime fields
          final publishAtStr = (item['publishAt'] ?? '').toString();
          final expireAtStr = (item['expireAt'] ?? '').toString();
          final featuredUntilStr = (item['featuredUntil'] ?? '').toString();

          if (publishAtStr.isNotEmpty) {
            try {
              data['publishAt'] =
                  Timestamp.fromDate(DateTime.parse(publishAtStr));
            } catch (_) {}
          }
          if (expireAtStr.isNotEmpty) {
            try {
              data['expireAt'] =
                  Timestamp.fromDate(DateTime.parse(expireAtStr));
            } catch (_) {}
          }
          if (featuredUntilStr.isNotEmpty) {
            try {
              data['featuredUntil'] =
                  Timestamp.fromDate(DateTime.parse(featuredUntilStr));
            } catch (_) {}
          }

          // Add to batch
          final collection = _collectionName(type);
          final docRef =
              FirebaseFirestore.instance.collection(collection).doc();
          batch.set(docRef, data);
          importedCount++;
        }

        // Commit batch
        await batch.commit();
      }

      // Show report
      String report = 'تم استيراد: $importedCount';
      if (failures.isNotEmpty) {
        report += '\nفشل: ${failures.length}';
        if (failures.length <= 5) {
          report += '\n${failures.join('\n')}';
        } else {
          report += '\n${failures.take(5).join('\n')}\n...و ${failures.length - 5} أخرى';
        }
      }
      widget.snack(report);

      if (importedCount > 0) {
        _bulkJsonC.clear();
      }
    } catch (e) {
      widget.snack('خطأ في الاستيراد: $e');
    } finally {
      widget.setSaving(false);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Build UI
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─────────────────────────────────────────────────────────────────
            // Header: Content Type & Section
            // ─────────────────────────────────────────────────────────────────
            _sectionHeader('نوع المحتوى والقسم'),
            const SizedBox(height: 10),

            // Content Type Dropdown
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: adminDropDecor().copyWith(labelText: 'نوع المحتوى'),
              items: _contentTypes.entries
                  .map((e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value,
                            style: GoogleFonts.cairo(
                                fontWeight: FontWeight.w800, fontSize: 13)),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _selectedType = v;
                  // Reset section to first of new type
                  final sections = _sectionsByType[v] ?? [];
                  _selectedSection =
                      sections.isNotEmpty ? sections.first : '';
                });
              },
            ),
            const SizedBox(height: 10),

            // Section Dropdown
            DropdownButtonFormField<String>(
              value: (_sectionsByType[_selectedType] ?? [])
                      .contains(_selectedSection)
                  ? _selectedSection
                  : null,
              decoration: adminDropDecor().copyWith(labelText: 'القسم (Tag)'),
              items: (_sectionsByType[_selectedType] ?? [])
                  .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(s,
                            style: GoogleFonts.cairo(
                                fontWeight: FontWeight.w800, fontSize: 13)),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() => _selectedSection = v);
              },
            ),

            const SizedBox(height: 20),

            // ─────────────────────────────────────────────────────────────────
            // Form Fields
            // ─────────────────────────────────────────────────────────────────
            _sectionHeader('بيانات الموضوع'),
            const SizedBox(height: 10),

            // DocId (optional)
            adminTextField(_docIdC, 'docId (للتعديل فقط - اختياري)'),
            const SizedBox(height: 10),

            // Title (required)
            adminTextField(_titleC, 'العنوان (إلزامي)'),
            const SizedBox(height: 10),

            // Hook (required)
            adminTextField(_hookC, 'Hook (إلزامي)', maxLines: 2),
            const SizedBox(height: 10),

            // Article/Body (optional)
            adminTextField(_articleC, 'المقال (اختياري)', maxLines: 4),
            const SizedBox(height: 10),

            // Reset (optional)
            adminTextField(_resetC, 'تصحيح المفهوم - reset (اختياري)',
                maxLines: 3),
            const SizedBox(height: 10),

            // Core (optional)
            adminTextField(_coreC, 'المعلومة الأساسية - core (اختياري)',
                maxLines: 4),
            const SizedBox(height: 10),

            // Example (optional)
            adminTextField(_exampleC, 'مثال واقعي - example (اختياري)',
                maxLines: 3),
            const SizedBox(height: 10),

            // Lock (optional)
            adminTextField(_lockC, 'إغلاق/سلوك - lock (اختياري)', maxLines: 2),

            const SizedBox(height: 20),

            // ─────────────────────────────────────────────────────────────────
            // Visibility & Publish Controls
            // ─────────────────────────────────────────────────────────────────
            _sectionHeader('الظهور والنشر'),
            const SizedBox(height: 10),

            // isActive Toggle
            _toggleRow(
              label: 'ظاهر (isActive)',
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),
            const SizedBox(height: 10),

            // Publish Now Button
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                _actionChip(
                  icon: Icons.publish_rounded,
                  label: 'نشر الآن',
                  color: AppColors.secondaryOrange,
                  onTap: _publishNow,
                ),
                _datePickerChip(
                  label: _publishAt == null
                      ? 'publishAt'
                      : 'publishAt: ${_fmtDt(_publishAt!)}',
                  onTap: () async {
                    final dt = await _pickDateTime(initial: _publishAt);
                    if (dt != null) setState(() => _publishAt = dt);
                  },
                  onClear:
                      _publishAt == null ? null : () => setState(() => _publishAt = null),
                ),
                _datePickerChip(
                  label: _expireAt == null
                      ? 'expireAt'
                      : 'expireAt: ${_fmtDt(_expireAt!)}',
                  onTap: () async {
                    final dt = await _pickDateTime(initial: _expireAt);
                    if (dt != null) setState(() => _expireAt = dt);
                  },
                  onClear:
                      _expireAt == null ? null : () => setState(() => _expireAt = null),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ─────────────────────────────────────────────────────────────────
            // Featured Controls
            // ─────────────────────────────────────────────────────────────────
            _sectionHeader('ترشيحات Pro'),
            const SizedBox(height: 10),

            // isFeatured Toggle
            _toggleRow(
              label: 'مختارات (isFeatured)',
              value: _isFeatured,
              onChanged: (v) => setState(() => _isFeatured = v),
            ),
            const SizedBox(height: 10),

            // Featured Order
            Row(
              children: [
                Text('ترتيب المختارات: $_featuredOrder',
                    style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w800, fontSize: 13)),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: _featuredOrder > 0
                      ? () => setState(() => _featuredOrder--)
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => setState(() => _featuredOrder++),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Featured Until
            _datePickerChip(
              label: _featuredUntil == null
                  ? 'featuredUntil (اختياري)'
                  : 'featuredUntil: ${_fmtDt(_featuredUntil!)}',
              onTap: () async {
                final dt = await _pickDateTime(initial: _featuredUntil);
                if (dt != null) setState(() => _featuredUntil = dt);
              },
              onClear: _featuredUntil == null
                  ? null
                  : () => setState(() => _featuredUntil = null),
            ),

            const SizedBox(height: 24),

            // ─────────────────────────────────────────────────────────────────
            // Save Button
            // ─────────────────────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _primaryButton(
                  label: 'حفظ',
                  icon: Icons.save_rounded,
                  onTap: _saveDocument,
                ),
                const SizedBox(width: 12),
                _secondaryButton(
                  label: 'مسح',
                  icon: Icons.clear_rounded,
                  onTap: _clearForm,
                ),
              ],
            ),

            const SizedBox(height: 30),

            // ─────────────────────────────────────────────────────────────────
            // Bulk Import Section
            // ─────────────────────────────────────────────────────────────────
            InkWell(
              onTap: () => setState(() => _showBulkImport = !_showBulkImport),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      _showBulkImport
                          ? Icons.expand_less
                          : Icons.expand_more,
                      color: AppColors.primaryDeepTeal,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'استيراد جماعي (JSON)',
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        color: AppColors.primaryDeepTeal,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_showBulkImport) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _bulkJsonC,
                maxLines: 8,
                textAlign: TextAlign.left,
                textDirection: TextDirection.ltr,
                style: GoogleFonts.robotoMono(fontSize: 11),
                decoration: InputDecoration(
                  hintText: '[\n  {"type": "pro_insight", "section": "...", "title": "...", "hook": "...", ...}\n]',
                  hintStyle: GoogleFonts.robotoMono(fontSize: 10, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: _primaryButton(
                  label: 'استيراد',
                  icon: Icons.cloud_upload_rounded,
                  onTap: _runBulkImport,
                ),
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UI Components
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _sectionHeader(String text) {
    return Text(
      text,
      style: GoogleFonts.cairo(
        fontWeight: FontWeight.w900,
        fontSize: 14,
        color: AppColors.primaryDeepTeal,
      ),
    );
  }

  Widget _toggleRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.secondaryOrange,
          ),
        ],
      ),
    );
  }

  Widget _actionChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(
        label,
        style: GoogleFonts.cairo(
          fontWeight: FontWeight.w800,
          fontSize: 11,
          color: color,
        ),
      ),
      backgroundColor: color.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onPressed: onTap,
    );
  }

  Widget _datePickerChip({
    required String label,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onTap,
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Colors.black54),
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 160),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (onClear != null) ...[
            const SizedBox(width: 4),
            InkWell(
              onTap: onClear,
              child:
                  const Icon(Icons.close, size: 14, color: Colors.redAccent),
            ),
          ],
        ],
      ),
    );
  }

  Widget _primaryButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondaryOrange,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: Icon(icon, size: 18, color: Colors.white),
        label: Text(
          label,
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.w900,
            fontSize: 13,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _secondaryButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: BorderSide(color: Colors.grey[400]!),
        ),
        icon: Icon(icon, size: 18, color: Colors.grey[700]),
        label: Text(
          label,
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color: Colors.grey[700],
          ),
        ),
      ),
    );
  }
}

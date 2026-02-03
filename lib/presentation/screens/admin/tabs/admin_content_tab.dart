// PATH: lib/presentation/screens/admin/tabs/admin_content_tab.dart
// STATUS: Full File - FIXED (Bulk import uses selectedType ONLY, no auto-detect)
//         ✅ KYC: sectionKey enforced, tags removed
//         ✅ Pro Insight: tags enforced, sectionKey removed
//         ✅ Prevents “KYC items landing in Pro Insight” forever

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
  // --- Configuration Maps ---
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

  static const Map<String, String> _kycKeyMapping = {
    'client_basics': 'أساسيات العميل',
    'personality_types': 'أنماط الشخصيات',
    'motives_needs': 'الدوافع والاحتياجات',
    'objections_responses': 'الاعتراضات والردود',
    'negotiation': 'التفاوض',
    'closing': 'إغلاق الصفقة',
    'after_sale': 'متابعة وما بعد البيع',
  };

  static const Map<String, String> _tagNormalization = {
    'سيستم الشركة': 'سيستم الشركات',
  };

  // --- State Variables ---
  String _selectedType = 'pro_insight';
  String _selectedSection = 'البداية الصح';
  String? _selectedSectionKey;

  // --- Controllers ---
  final _docIdC = TextEditingController();
  final _titleC = TextEditingController();
  final _hookC = TextEditingController();
  final _articleC = TextEditingController();
  final _resetC = TextEditingController();
  final _coreC = TextEditingController();
  final _exampleC = TextEditingController();
  final _lockC = TextEditingController();
  final _bulkJsonC = TextEditingController();

  // --- Fields ---
  bool _isActive = true;
  bool _isFeatured = false;
  int _featuredOrder = 0;
  DateTime? _publishAt;
  DateTime? _expireAt;
  DateTime? _featuredUntil;

  // --- UI Flags ---
  bool _showBulkImport = false;

  @override
  void initState() {
    super.initState();
    _docIdC.addListener(_onDocIdChanged);

    // Ensure consistent defaults
    final sections = _sectionsByType[_selectedType] ?? const <String>[];
    if (sections.isNotEmpty) {
      _selectedSection = sections.first;
    }
  }

  @override
  void dispose() {
    _docIdC.removeListener(_onDocIdChanged);
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

  // Auto-fill form when pasting a Doc ID
  void _onDocIdChanged() async {
    final id = _docIdC.text.trim();
    if (id.isEmpty) return;

    try {
      final snap = await FirebaseFirestore.instance
          .collection(_collectionName(_selectedType))
          .doc(id)
          .get();

      if (!snap.exists || !mounted) return;

      final data = snap.data()!;
      setState(() {
        if (_selectedType == 'know_your_client') {
          final sk = (data['sectionKey'] ?? '').toString().trim();
          _selectedSectionKey = sk.isNotEmpty ? sk : _kycKeyMapping.keys.first;
          _selectedSection = _kycKeyMapping[_selectedSectionKey] ??
              _kycKeyMapping.values.first;
        } else {
          // Pro Insight: try to infer section from tags if present
          final tags =
              (data['tags'] is List) ? (data['tags'] as List) : const [];
          final firstTag = tags.isNotEmpty ? tags.first.toString().trim() : '';
          if (firstTag.isNotEmpty) {
            _selectedSection = _tagNormalization[firstTag] ?? firstTag;
          }
        }
      });
    } catch (_) {}
  }

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
      if (type == 'pro_insight' && _tagNormalization.containsKey(trimmed)) {
        trimmed = _tagNormalization[trimmed]!;
      }
      result.add(trimmed);
    }
    return result.toList();
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
    _bulkJsonC.clear();

    setState(() {
      _isActive = true;
      _isFeatured = false;
      _featuredOrder = 0;
      _publishAt = null;
      _expireAt = null;
      _featuredUntil = null;

      if (_selectedType == 'know_your_client') {
        _selectedSectionKey = _kycKeyMapping.keys.first;
        _selectedSection = _kycKeyMapping.values.first;
      } else {
        _selectedSectionKey = null;
        final sections = _sectionsByType[_selectedType] ?? const <String>[];
        _selectedSection = sections.isNotEmpty ? sections.first : '';
      }
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ✅ STRICT SAVE LOGIC (Separates Tags vs SectionKey)
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> _saveDocument() async {
    final title = _titleC.text.trim();
    final hook = _hookC.text.trim();

    if (title.isEmpty || hook.isEmpty) {
      widget.snack('العنوان و Hook مطلوبين');
      return;
    }
    if (_selectedType == 'know_your_client') {
      final sk = (_selectedSectionKey ?? '').trim();
      if (sk.isEmpty) {
        widget.snack('القسم (Section Key) مطلوب لـ "اعرف عميلك"');
        return;
      }
    }

    widget.setSaving(true);
    try {
      final collection = _collectionName(_selectedType);
      final docId = _docIdC.text.trim();

      final data = <String, dynamic>{
        'title': title,
        'hook': hook,
        'isActive': _isActive,
        'isFeatured': _isFeatured,
        'featuredOrder': _featuredOrder,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_articleC.text.isNotEmpty) data['article'] = _articleC.text.trim();
      if (_resetC.text.isNotEmpty) data['reset'] = _resetC.text.trim();
      if (_coreC.text.isNotEmpty) data['core'] = _coreC.text.trim();
      if (_exampleC.text.isNotEmpty) data['example'] = _exampleC.text.trim();
      if (_lockC.text.isNotEmpty) data['lock'] = _lockC.text.trim();
      if (_publishAt != null) {
        data['publishAt'] = Timestamp.fromDate(_publishAt!);
      }

      if (_selectedType == 'know_your_client') {
        data['sectionKey'] = (_selectedSectionKey ?? '').trim();
        // DO NOT write tags for KYC
      } else {
        final tags = _normalizeTags([_selectedSection], _selectedType);
        data['tags'] = tags;
        // DO NOT write sectionKey for Pro Insight
      }

      if (docId.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection(collection)
            .doc(docId)
            .set(data, SetOptions(merge: true));
      } else {
        data['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection(collection).add(data);
      }

      widget.snack('تم الحفظ بنجاح ✅');
      _clearForm();
    } catch (e) {
      widget.snack('خطأ: $e');
    } finally {
      widget.setSaving(false);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ✅ STRICT BULK IMPORT LOGIC (Selected Type ONLY)
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> _runBulkImport() async {
    final jsonText = _bulkJsonC.text.trim();
    if (jsonText.isEmpty) {
      widget.snack('الصندوق فارغ');
      return;
    }

    // Selected target type is the ONLY truth.
    final targetType = _selectedType;
    final targetCollection = _collectionName(targetType);

    // Ensure defaults for injection
    final defaultKycSectionKey = _selectedSectionKey?.trim().isNotEmpty == true
        ? _selectedSectionKey!.trim()
        : _kycKeyMapping.keys.first;

    final defaultProInsightTag = _selectedSection.trim().isNotEmpty
        ? _selectedSection.trim()
        : (_sectionsByType['pro_insight']?.first ?? 'البداية الصح');

    try {
      final raw = json.decode(jsonText);

      if (raw is! List) {
        widget.snack('لازم يكون JSON Array: [ {...}, {...} ]');
        return;
      }

      widget.setSaving(true);
      int count = 0;

      for (int i = 0; i < raw.length; i += 450) {
        // keep headroom under 500 writes
        final batch = FirebaseFirestore.instance.batch();
        final chunk = raw.skip(i).take(450);

        for (final item in chunk) {
          if (item is! Map) continue;

          final data = Map<String, dynamic>.from(item);

          // Determine/Generate docId
          final docId = (data['docId']?.toString().trim().isNotEmpty == true)
              ? data['docId'].toString().trim()
              : FirebaseFirestore.instance
                  .collection(targetCollection)
                  .doc()
                  .id;

          data.remove('docId');

          // Normalize timestamps
          data['updatedAt'] = FieldValue.serverTimestamp();
          data['createdAt'] = data['createdAt'] ?? FieldValue.serverTimestamp();

          // ✅ STRICT TYPE ENFORCEMENT
          if (targetType == 'know_your_client') {
            // KYC MUST have sectionKey
            final sk = (data['sectionKey'] ?? '').toString().trim();
            data['sectionKey'] = sk.isNotEmpty ? sk : defaultKycSectionKey;

            // Remove tags if mistakenly present
            data.remove('tags');
          } else {
            // Pro Insight MUST have tags
            final tagsRaw = data['tags'];
            List<String> tags = [];

            if (tagsRaw is List) {
              tags = tagsRaw.map((e) => e.toString()).toList();
            } else if (tagsRaw is String) {
              tags = [tagsRaw];
            }

            tags = _normalizeTags(
              tags.isNotEmpty ? tags : [defaultProInsightTag],
              'pro_insight',
            );

            data['tags'] = tags;

            // Remove sectionKey if mistakenly present
            data.remove('sectionKey');
          }

          final ref = FirebaseFirestore.instance
              .collection(targetCollection)
              .doc(docId);
          batch.set(ref, data, SetOptions(merge: true));
          count++;
        }

        await batch.commit();
      }

      widget.snack('تم استيراد $count موضوع بنجاح ✅');
      setState(() => _bulkJsonC.clear());
    } catch (e) {
      widget.snack('خطأ في الـ JSON: $e');
    } finally {
      widget.setSaving(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionHeader('نوع المحتوى والقسم'),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              decoration: adminDropDecor().copyWith(labelText: 'نوع المحتوى'),
              items: _contentTypes.entries
                  .map((e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(
                          e.value,
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _selectedType = v;

                  if (_selectedType == 'know_your_client') {
                    _selectedSectionKey = _kycKeyMapping.keys.first;
                    _selectedSection = _kycKeyMapping.values.first;
                  } else {
                    _selectedSectionKey = null;
                    final sections = _sectionsByType[v] ?? const <String>[];
                    _selectedSection =
                        sections.isNotEmpty ? sections.first : '';
                  }
                });
              },
            ),
            const SizedBox(height: 10),
            if (_selectedType == 'know_your_client') ...[
              DropdownButtonFormField<String>(
                initialValue: (_selectedSectionKey?.trim().isNotEmpty == true)
                    ? _selectedSectionKey
                    : _kycKeyMapping.keys.first,
                decoration: adminDropDecor()
                    .copyWith(labelText: 'قسم اعرف عميلك (Section Key)'),
                items: _kycKeyMapping.entries
                    .map((e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(
                            e.value,
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    _selectedSectionKey = v;
                    _selectedSection = _kycKeyMapping[v]!;
                  });
                },
              ),
              const SizedBox(height: 10),
            ] else ...[
              DropdownButtonFormField<String>(
                initialValue: _selectedSection,
                decoration: adminDropDecor().copyWith(labelText: 'القسم (Tag)'),
                items: (_sectionsByType[_selectedType] ?? const <String>[])
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(
                            s,
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedSection = v);
                },
              ),
            ],
            const SizedBox(height: 20),
            _sectionHeader('بيانات الموضوع'),
            const SizedBox(height: 10),
            adminTextField(
              _docIdC,
              'docId (للتعديل فقط - اتركه فارغاً للجديد)',
            ),
            const SizedBox(height: 10),
            adminTextField(_titleC, 'العنوان (Title) *'),
            const SizedBox(height: 10),
            adminTextField(_hookC, 'المقدمة الخاطفة (Hook) *', maxLines: 2),
            const SizedBox(height: 10),
            adminTextField(_articleC, 'المقال (Article)', maxLines: 4),
            const SizedBox(height: 10),
            adminTextField(_resetC, 'تصحيح المفهوم (Reset)', maxLines: 3),
            const SizedBox(height: 10),
            adminTextField(_coreC, 'الخلاصة (Core)', maxLines: 3),
            const SizedBox(height: 10),
            adminTextField(_exampleC, 'مثال عملي (Example)', maxLines: 3),
            const SizedBox(height: 10),
            adminTextField(_lockC, 'الخاتمة/الإغلاق (Lock)', maxLines: 2),
            const SizedBox(height: 20),
            _sectionHeader('الظهور والنشر'),
            const SizedBox(height: 10),
            _toggleRow(
              label: 'نشط (isActive)',
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),
            const SizedBox(height: 10),
            _toggleRow(
              label: 'مميز (isFeatured)',
              value: _isFeatured,
              onChanged: (v) => setState(() => _isFeatured = v),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _primaryButton(
                  label: 'حفظ الموضوع',
                  icon: Icons.save_rounded,
                  onTap: _saveDocument,
                ),
                const SizedBox(width: 10),
                _secondaryButton(
                  label: 'تفريغ الخانات',
                  icon: Icons.refresh,
                  onTap: _clearForm,
                ),
              ],
            ),
            const SizedBox(height: 40),
            _dividerWithText('أدوات الرفع الجماعي'),
            const SizedBox(height: 10),
            Center(
              child: _actionChip(
                icon: _showBulkImport
                    ? Icons.keyboard_arrow_up
                    : Icons.unarchive_rounded,
                label: _showBulkImport
                    ? "إخفاء لوحة الرفع"
                    : "فتح لوحة الرفع الجماعي (JSON)",
                color: AppColors.secondaryOrange,
                onTap: () => setState(() => _showBulkImport = !_showBulkImport),
              ),
            ),
            if (_showBulkImport) ...[
              const SizedBox(height: 15),
              adminTextField(
                _bulkJsonC,
                'الصق مصفوفة JSON هنا (Array)...',
                maxLines: 10,
              ),
              const SizedBox(height: 10),
              Text(
                'مهم: الرفع الجماعي سيذهب لنوع المحتوى المختار بالأعلى فقط.',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 15),
              _primaryButton(
                label: 'بدء الاستيراد الجماعي الآن',
                icon: Icons.cloud_upload_rounded,
                onTap: _runBulkImport,
              ),
            ],
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  // --- UI Helper Widgets ---

  Widget _sectionHeader(String text) => Text(
        text,
        style: GoogleFonts.cairo(
          fontWeight: FontWeight.w900,
          fontSize: 14,
          color: AppColors.primaryDeepTeal,
        ),
      );

  Widget _dividerWithText(String text) => Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              text,
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      );

  Widget _toggleRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) =>
      Container(
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
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: AppColors.secondaryOrange,
            ),
          ],
        ),
      );

  Widget _actionChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) =>
      ActionChip(
        avatar: Icon(icon, size: 16, color: color),
        label: Text(
          label,
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.w800,
            fontSize: 11,
            color: color,
          ),
        ),
        backgroundColor: color.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onPressed: onTap,
      );

  Widget _primaryButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) =>
      ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDeepTeal,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
      );

  Widget _secondaryButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) =>
      OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          side: BorderSide(color: Colors.grey[300]!),
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
      );
}

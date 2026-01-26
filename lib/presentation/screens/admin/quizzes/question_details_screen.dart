// PATH: lib/presentation/screens/admin/quizzes/question_details_screen.dart
// Question details screen: quizzes collection + Arabic categories only

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/app_config_service.dart';
import '../widgets/admin_shared_widgets.dart';

class QuestionDetailsScreen extends StatefulWidget {
  final String docId;
  final void Function(bool) setSaving;
  final void Function(String) snack;
  final Future<bool> Function(String, String) confirm;

  const QuestionDetailsScreen({
    super.key,
    required this.docId,
    required this.setSaving,
    required this.snack,
    required this.confirm,
  });

  @override
  State<QuestionDetailsScreen> createState() => _QuestionDetailsScreenState();
}

class _QuestionDetailsScreenState extends State<QuestionDetailsScreen> {
  // ═══════════════════════════════════════════════════════════════════════════
  // Collection & Category Values
  // ═══════════════════════════════════════════════════════════════════════════

  static const String _collection = 'quizzes';

  static const List<String> _categoryValues = [
    'دوري النجوم',
    'دوري المحترفين',
  ];

  static const List<int> _difficultyValues = [1, 2, 3, 4, 5];

  // ═══════════════════════════════════════════════════════════════════════════
  // State
  // ═══════════════════════════════════════════════════════════════════════════

  bool _loading = true;
  bool _changed = false;

  // Edit form
  final _qC = TextEditingController();
  final _o0C = TextEditingController();
  final _o1C = TextEditingController();
  final _o2C = TextEditingController();
  final _o3C = TextEditingController();
  int _correctIndex = 0;
  String _category = 'دوري النجوم';
  int _difficulty = 3;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _loadQuestion();
  }

  @override
  void dispose() {
    _qC.dispose();
    _o0C.dispose();
    _o1C.dispose();
    _o2C.dispose();
    _o3C.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Load Question
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _loadQuestion() async {
    setState(() => _loading = true);

    try {
      final doc = await FirebaseFirestore.instance
          .collection(_collection)
          .doc(widget.docId)
          .get();

      if (!doc.exists) {
        widget.snack('السؤال غير موجود');
        if (mounted) Navigator.pop(context);
        return;
      }

      final data = doc.data()!;
      final options = ((data['options'] as List?) ?? []).cast<String>();

      _qC.text = (data['question'] ?? '').toString();
      _o0C.text = options.isNotEmpty ? options[0] : '';
      _o1C.text = options.length > 1 ? options[1] : '';
      _o2C.text = options.length > 2 ? options[2] : '';
      _o3C.text = options.length > 3 ? options[3] : '';
      _correctIndex = ((data['correctAnswer'] as int?) ?? 0).clamp(0, 3);

      // Category (Arabic only)
      final cat = (data['category'] ?? '').toString();
      _category = _categoryValues.contains(cat) ? cat : 'دوري النجوم';
      
      // Difficulty (1-5)
      _difficulty = ((data['difficulty'] as int?) ?? 3).clamp(1, 5);
      
      _isActive = data['isActive'] == true;

      setState(() => _loading = false);
    } catch (e) {
      widget.snack('خطأ في التحميل: $e');
      if (mounted) Navigator.pop(context);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Actions
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _saveChanges() async {
    final question = _qC.text.trim();
    final options = [
      _o0C.text.trim(),
      _o1C.text.trim(),
      _o2C.text.trim(),
      _o3C.text.trim(),
    ];

    // Validation
    if (question.isEmpty || question.length < 10) {
      widget.snack('السؤال يجب أن يكون 10 أحرف على الأقل');
      return;
    }

    for (int i = 0; i < 4; i++) {
      if (options[i].isEmpty) {
        widget.snack('الاختيار ${i + 1} مطلوب');
        return;
      }
    }

    widget.setSaving(true);

    try {
      // quizzes collection: only required fields
      await FirebaseFirestore.instance
          .collection(_collection)
          .doc(widget.docId)
          .update({
        'category': _category,
        'difficulty': _difficulty,
        'question': question,
        'options': options,
        'correctAnswer': _correctIndex,
        'isActive': _isActive,
      });

      widget.snack('تم الحفظ ✅');
      setState(() => _changed = true);
      await _loadQuestion();
    } catch (e) {
      widget.snack('خطأ: $e');
    } finally {
      widget.setSaving(false);
    }
  }

  /// Toggle isActive (Hide/Show)
  Future<void> _toggleActive() async {
    widget.setSaving(true);

    try {
      final newValue = !_isActive;
      await FirebaseFirestore.instance
          .collection(_collection)
          .doc(widget.docId)
          .update({'isActive': newValue});
      setState(() {
        _isActive = newValue;
        _changed = true;
      });
      widget.snack(newValue ? 'تم الإظهار ✅' : 'تم الإخفاء ✅');
    } catch (e) {
      widget.snack('خطأ: $e');
    } finally {
      widget.setSaving(false);
    }
  }

  /// Hard delete - permanently removes the document
  Future<void> _deleteQuestion() async {
    final confirmed = await widget.confirm(
      'حذف السؤال نهائياً؟',
      'سيتم حذف السؤال من قاعدة البيانات ولا يمكن استرجاعه.',
    );

    if (!confirmed) return;

    widget.setSaving(true);

    try {
      await FirebaseFirestore.instance
          .collection(_collection)
          .doc(widget.docId)
          .delete();

      widget.snack('تم الحذف ✅');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      widget.snack('خطأ: $e');
      widget.setSaving(false);
    }
  }

  /// Move league - only updates category field to Arabic value
  Future<void> _moveLeague() async {
    String newCategory = _category;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text('نقل السؤال',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            content: DropdownButtonFormField<String>(
              initialValue: newCategory,
              decoration: adminDropDecor().copyWith(labelText: 'الدوري'),
              items: _categoryValues
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(
                          c,
                          style: GoogleFonts.cairo(fontSize: 12),
                        ),
                      ))
                  .toList(),
              onChanged: (v) => setLocal(() => newCategory = v ?? newCategory),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('إلغاء', style: GoogleFonts.cairo()),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  widget.setSaving(true);
                  try {
                    // Simply update category field (Arabic string)
                    await FirebaseFirestore.instance
                        .collection(_collection)
                        .doc(widget.docId)
                        .update({'category': newCategory});
                    setState(() {
                      _category = newCategory;
                      _changed = true;
                    });
                    widget.snack('تم النقل ✅');
                  } catch (e) {
                    widget.snack('خطأ: $e');
                  } finally {
                    widget.setSaving(false);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDeepTeal,
                ),
                child: Text('نقل',
                    style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _shareQuestion() {
    if (!AppConfigService().quizShareEnabled) {
      widget.snack('المشاركة غير متاحة حالياً');
      return;
    }

    final deepLink = 'lpro://quiz/${widget.docId}';
    Clipboard.setData(ClipboardData(text: deepLink));
    widget.snack('تم نسخ الرابط ✅');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UI
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _changed);
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFDFBF7),
        appBar: AppBar(
          title: Text(
            'تفاصيل السؤال',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          backgroundColor: AppColors.primaryDeepTeal,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ═══════════════════════════════════════════════════════
                      // Info bar
                      // ═══════════════════════════════════════════════════════
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            adminStatusBadge(_isActive),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '$_category • صعوبة $_difficulty',
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                            Text(
                              'ID: ${widget.docId.substring(0, 8)}...',
                              style: GoogleFonts.cairo(
                                fontSize: 10,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ═══════════════════════════════════════════════════════
                      // Quick Actions
                      // ═══════════════════════════════════════════════════════
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _actionChip(
                            icon: _isActive
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            label: _isActive ? 'إخفاء' : 'إظهار',
                            color: _isActive ? Colors.orange : Colors.green,
                            onTap: _toggleActive,
                          ),
                          _actionChip(
                            icon: Icons.swap_horiz_rounded,
                            label: 'نقل',
                            color: AppColors.primaryDeepTeal,
                            onTap: _moveLeague,
                          ),
                          _actionChip(
                            icon: Icons.share_outlined,
                            label: 'مشاركة',
                            color: AppColors.secondaryOrange,
                            onTap: _shareQuestion,
                          ),
                          _actionChip(
                            icon: Icons.delete_forever_outlined,
                            label: 'حذف نهائي',
                            color: Colors.red,
                            onTap: _deleteQuestion,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ═══════════════════════════════════════════════════════
                      // Edit Form
                      // ═══════════════════════════════════════════════════════
                      _sectionHeader('تعديل السؤال'),
                      const SizedBox(height: 12),

                      // Category + Difficulty
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _category,
                              decoration:
                                  adminDropDecor().copyWith(labelText: 'الدوري'),
                              items: _categoryValues
                                  .map((c) => DropdownMenuItem(
                                        value: c,
                                        child: Text(
                                          c,
                                          style: GoogleFonts.cairo(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 12),
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => _category = v);
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              initialValue: _difficulty,
                              decoration:
                                  adminDropDecor().copyWith(labelText: 'الصعوبة (1-5)'),
                              items: _difficultyValues
                                  .map((d) => DropdownMenuItem(
                                        value: d,
                                        child: Text(
                                          '$d',
                                          style: GoogleFonts.cairo(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 12),
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => _difficulty = v);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Question text
                      adminTextField(_qC, 'نص السؤال', maxLines: 3),
                      const SizedBox(height: 12),

                      // Options
                      _optionField(_o0C, 'اختيار 1', 0),
                      const SizedBox(height: 8),
                      _optionField(_o1C, 'اختيار 2', 1),
                      const SizedBox(height: 8),
                      _optionField(_o2C, 'اختيار 3', 2),
                      const SizedBox(height: 8),
                      _optionField(_o3C, 'اختيار 4', 3),
                      const SizedBox(height: 12),

                      // Correct answer
                      DropdownButtonFormField<int>(
                        initialValue: _correctIndex,
                        decoration: adminDropDecor()
                            .copyWith(labelText: 'الإجابة الصحيحة'),
                        items: List.generate(
                          4,
                          (i) => DropdownMenuItem(
                            value: i,
                            child: Text(
                              'الاختيار ${i + 1}',
                              style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.w800, fontSize: 12),
                            ),
                          ),
                        ),
                        onChanged: (v) {
                          if (v != null) setState(() => _correctIndex = v);
                        },
                      ),
                      const SizedBox(height: 12),

                      // isActive toggle
                      _toggleRow(
                        label: 'ظاهر (isActive)',
                        value: _isActive,
                        onChanged: (v) => setState(() => _isActive = v),
                      ),
                      const SizedBox(height: 20),

                      // Save button
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 46),
                          child: ElevatedButton.icon(
                            onPressed: _saveChanges,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondaryOrange,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 28, vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: const Icon(Icons.save_rounded,
                                size: 20, color: Colors.white),
                            label: Text(
                              'حفظ التعديلات',
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
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

  Widget _optionField(TextEditingController c, String hint, int index) {
    final isCorrect = _correctIndex == index;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: isCorrect ? Border.all(color: Colors.green, width: 2) : null,
      ),
      child: Row(
        children: [
          Expanded(child: adminTextField(c, hint)),
          if (isCorrect)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(Icons.check_circle, color: Colors.green, size: 20),
            ),
        ],
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
              style:
                  GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 13),
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
      visualDensity: VisualDensity.compact,
      onPressed: onTap,
    );
  }
}

// PATH: lib/presentation/screens/admin/tabs/admin_quiz_tab.dart
// Quiz CMS v1: Search-first UI + Add + Bulk Import

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/models/admin_control_models.dart';
import '../../../../features/quizzes/models/quiz.dart';
import '../../../../features/quizzes/repositories/quiz_repository.dart';
import '../widgets/admin_shared_widgets.dart';
import '../quizzes/question_details_screen.dart';

class AdminQuizTab extends StatefulWidget {
  final QuizRepository quizRepo;
  final void Function(bool) setSaving;
  final void Function(String) snack;
  final Future<bool> Function(String, String) confirm;

  const AdminQuizTab({
    super.key,
    required this.quizRepo,
    required this.setSaving,
    required this.snack,
    required this.confirm,
  });

  @override
  State<AdminQuizTab> createState() => _AdminQuizTabState();
}

class _AdminQuizTabState extends State<AdminQuizTab> {
  // ═══════════════════════════════════════════════════════════════════════════
  // League Mapping (Arabic -> Internal)
  // ═══════════════════════════════════════════════════════════════════════════

  static const Map<String, String?> _leagueMap = {
    'كل الدوريات': null,
    'دوري النجوم': QuizCategory.stars,
    'دوري المحترفين': QuizCategory.pros,
    'عام': QuizCategory.general,
  };

  static const Map<String, String> _leagueLabels = {
    QuizCategory.stars: 'دوري النجوم',
    QuizCategory.pros: 'دوري المحترفين',
    QuizCategory.general: 'عام',
  };

  static List<String> get _leagueOptions => _leagueMap.keys.toList();

  // ═══════════════════════════════════════════════════════════════════════════
  // State
  // ═══════════════════════════════════════════════════════════════════════════

  String _selectedLeague = 'كل الدوريات';
  final _searchC = TextEditingController();
  List<Quiz> _searchResults = [];
  bool _isSearching = false;
  bool _showAddForm = false;
  bool _showBulkImport = false;

  // Add form controllers
  final _qC = TextEditingController();
  final _o0C = TextEditingController();
  final _o1C = TextEditingController();
  final _o2C = TextEditingController();
  final _o3C = TextEditingController();
  int _correctIndex = 0;
  String _addLeague = QuizCategory.stars;
  String _addLevel = QuizLeague.bronze;
  bool _addIsActive = true;

  // Bulk import controller
  final _bulkJsonC = TextEditingController();

  @override
  void dispose() {
    _searchC.dispose();
    _qC.dispose();
    _o0C.dispose();
    _o1C.dispose();
    _o2C.dispose();
    _o3C.dispose();
    _bulkJsonC.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Search
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _runSearch() async {
    setState(() => _isSearching = true);

    try {
      final category = _leagueMap[_selectedLeague];
      final searchText = _searchC.text.trim().toLowerCase();

      Query<Map<String, dynamic>> query =
          FirebaseFirestore.instance.collection(FirestorePaths.quizzes);

      // Filter by category if not "all"
      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }

      // Exclude deleted
      query = query.where('isDeleted', isEqualTo: false);

      // Limit and order
      query = query.orderBy('createdAt', descending: true).limit(100);

      final snap = await query.get();

      List<Quiz> results =
          snap.docs.map((d) => Quiz.fromFirestore(d.data(), d.id)).toList();

      // Client-side search filter
      if (searchText.isNotEmpty) {
        results = results
            .where((q) => q.question.toLowerCase().contains(searchText))
            .toList();
      }

      // Limit to 30
      if (results.length > 30) {
        results = results.take(30).toList();
      }

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      widget.snack('خطأ في البحث: $e');
      setState(() => _isSearching = false);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Add Single Question
  // ═══════════════════════════════════════════════════════════════════════════

  void _clearAddForm() {
    _qC.clear();
    _o0C.clear();
    _o1C.clear();
    _o2C.clear();
    _o3C.clear();
    setState(() {
      _correctIndex = 0;
      _addIsActive = true;
    });
  }

  Future<void> _saveNewQuestion() async {
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

    if (_correctIndex < 0 || _correctIndex > 3) {
      widget.snack('اختر الإجابة الصحيحة');
      return;
    }

    widget.setSaving(true);

    try {
      final control = AdminControlFields(
        isActive: _addIsActive,
        sectionKey: FirestorePaths.sectionKeyQuiz,
      );

      final quiz = Quiz(
        id: '',
        question: question,
        options: options,
        correctOptionIndex: _correctIndex,
        category: _addLeague,
        league: _addLevel,
        control: control,
      );

      quiz.validate();
      await widget.quizRepo.create(quiz);

      widget.snack('تم إضافة السؤال ✅');
      _clearAddForm();
      await _runSearch();
    } catch (e) {
      widget.snack('خطأ: $e');
    } finally {
      widget.setSaving(false);
    }
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

          // Validate category
          final category = (item['category'] ?? '').toString().trim();
          if (category.isEmpty) {
            failures.add('[$index] category مطلوب');
            continue;
          }

          // Map Arabic category to internal
          String internalCategory = category;
          if (_leagueLabels.containsValue(category)) {
            internalCategory = _leagueLabels.entries
                .firstWhere((e) => e.value == category)
                .key;
          }

          if (!QuizCategory.isValid(internalCategory)) {
            // Try to match
            if (category.contains('نجوم')) {
              internalCategory = QuizCategory.stars;
            } else if (category.contains('محترفين')) {
              internalCategory = QuizCategory.pros;
            } else {
              internalCategory = QuizCategory.general;
            }
          }

          // Validate question
          final question = (item['question'] ?? '').toString().trim();
          if (question.isEmpty || question.length < 10) {
            failures.add('[$index] السؤال قصير أو فارغ');
            continue;
          }

          // Validate options
          final rawOptions = item['options'];
          if (rawOptions is! List || rawOptions.length != 4) {
            failures.add('[$index] options يجب أن تكون 4 عناصر');
            continue;
          }

          final options = <String>[];
          bool optionsValid = true;
          for (int oi = 0; oi < 4; oi++) {
            final opt = rawOptions[oi].toString().trim();
            if (opt.isEmpty) {
              failures.add('[$index] الاختيار ${oi + 1} فارغ');
              optionsValid = false;
              break;
            }
            options.add(opt);
          }
          if (!optionsValid) continue;

          // Validate correctAnswer
          final correctRaw = item['correctAnswer'];
          final correct = (correctRaw is int)
              ? correctRaw
              : int.tryParse((correctRaw ?? '').toString()) ?? -1;

          if (correct < 0 || correct > 3) {
            failures.add('[$index] correctAnswer يجب أن يكون 0-3');
            continue;
          }

          // Build data
          final isActive = item['isActive'] != false;
          final league = (item['league'] ?? QuizLeague.bronze).toString();
          final validLeague =
              QuizLeague.isValid(league) ? league : QuizLeague.bronze;

          final data = <String, dynamic>{
            'question': question,
            'options': options,
            'correctOptionIndex': correct,
            'category': internalCategory,
            'league': validLeague,
            'difficulty': 3,
            'isActive': isActive,
            'isDeleted': false,
            'sectionKey': FirestorePaths.sectionKeyQuiz,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          };

          final docRef = FirebaseFirestore.instance
              .collection(FirestorePaths.quizzes)
              .doc();
          batch.set(docRef, data);
          importedCount++;
        }

        await batch.commit();
      }

      String report = 'تم استيراد: $importedCount';
      if (failures.isNotEmpty) {
        report += '\nفشل: ${failures.length}';
        if (failures.length <= 5) {
          report += '\n${failures.join('\n')}';
        } else {
          report +=
              '\n${failures.take(5).join('\n')}\n...و ${failures.length - 5} أخرى';
        }
      }
      widget.snack(report);

      if (importedCount > 0) {
        _bulkJsonC.clear();
        await _runSearch();
      }
    } catch (e) {
      widget.snack('خطأ في الاستيراد: $e');
    } finally {
      widget.setSaving(false);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UI
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
            // ═══════════════════════════════════════════════════════════════════
            // Search Section
            // ═══════════════════════════════════════════════════════════════════
            _sectionHeader('بحث الأسئلة'),
            const SizedBox(height: 10),

            // League filter
            DropdownButtonFormField<String>(
              value: _selectedLeague,
              decoration: adminDropDecor().copyWith(labelText: 'الدوري'),
              items: _leagueOptions
                  .map((l) => DropdownMenuItem(
                        value: l,
                        child: Text(l,
                            style: GoogleFonts.cairo(
                                fontWeight: FontWeight.w800, fontSize: 13)),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedLeague = v);
              },
            ),
            const SizedBox(height: 10),

            // Search input
            adminTextField(_searchC, 'بحث في نص السؤال...'),
            const SizedBox(height: 10),

            // Search button
            Align(
              alignment: Alignment.centerRight,
              child: _actionButton(
                label: 'بحث',
                icon: Icons.search,
                color: AppColors.primaryDeepTeal,
                onTap: _runSearch,
              ),
            ),
            const SizedBox(height: 16),

            // Results
            if (_isSearching)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_searchResults.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'لا نتائج. اضغط "بحث" للبدء.',
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _searchResults.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _quizCard(_searchResults[i]),
              ),

            const SizedBox(height: 24),

            // ═══════════════════════════════════════════════════════════════════
            // Add Question Section
            // ═══════════════════════════════════════════════════════════════════
            _expandableSection(
              title: 'إضافة سؤال جديد',
              icon: Icons.add_circle_outline,
              isExpanded: _showAddForm,
              onToggle: () => setState(() => _showAddForm = !_showAddForm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),

                  // Category (league)
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _addLeague,
                          decoration:
                              adminDropDecor().copyWith(labelText: 'الدوري'),
                          items: QuizCategory.values
                              .map((c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(
                                      _leagueLabels[c] ?? c,
                                      style: GoogleFonts.cairo(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12),
                                    ),
                                  ))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _addLeague = v);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _addLevel,
                          decoration:
                              adminDropDecor().copyWith(labelText: 'المستوى'),
                          items: QuizLeague.values
                              .map((l) => DropdownMenuItem(
                                    value: l,
                                    child: Text(
                                      l,
                                      style: GoogleFonts.cairo(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12),
                                    ),
                                  ))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _addLevel = v);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Question
                  adminTextField(_qC, 'نص السؤال (10 أحرف على الأقل)',
                      maxLines: 2),
                  const SizedBox(height: 10),

                  // Options
                  adminTextField(_o0C, 'اختيار 1'),
                  const SizedBox(height: 6),
                  adminTextField(_o1C, 'اختيار 2'),
                  const SizedBox(height: 6),
                  adminTextField(_o2C, 'اختيار 3'),
                  const SizedBox(height: 6),
                  adminTextField(_o3C, 'اختيار 4'),
                  const SizedBox(height: 10),

                  // Correct answer
                  DropdownButtonFormField<int>(
                    value: _correctIndex,
                    decoration:
                        adminDropDecor().copyWith(labelText: 'الإجابة الصحيحة'),
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
                  const SizedBox(height: 10),

                  // isActive toggle
                  _toggleRow(
                    label: 'ظاهر (isActive)',
                    value: _addIsActive,
                    onChanged: (v) => setState(() => _addIsActive = v),
                  ),
                  const SizedBox(height: 14),

                  // Save button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _actionButton(
                        label: 'حفظ',
                        icon: Icons.save_rounded,
                        color: AppColors.secondaryOrange,
                        onTap: _saveNewQuestion,
                      ),
                      const SizedBox(width: 10),
                      _actionButton(
                        label: 'مسح',
                        icon: Icons.clear_rounded,
                        color: Colors.grey,
                        onTap: _clearAddForm,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ═══════════════════════════════════════════════════════════════════
            // Bulk Import Section
            // ═══════════════════════════════════════════════════════════════════
            _expandableSection(
              title: 'استيراد جماعي (JSON)',
              icon: Icons.cloud_upload_outlined,
              isExpanded: _showBulkImport,
              onToggle: () =>
                  setState(() => _showBulkImport = !_showBulkImport),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  TextField(
                    controller: _bulkJsonC,
                    maxLines: 8,
                    textAlign: TextAlign.left,
                    textDirection: TextDirection.ltr,
                    style: GoogleFonts.robotoMono(fontSize: 11),
                    decoration: InputDecoration(
                      hintText:
                          '[\n  {"category": "دوري النجوم", "question": "...", "options": ["a","b","c","d"], "correctAnswer": 0}\n]',
                      hintStyle:
                          GoogleFonts.robotoMono(fontSize: 10, color: Colors.grey),
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
                    child: _actionButton(
                      label: 'استيراد',
                      icon: Icons.cloud_upload_rounded,
                      color: AppColors.secondaryOrange,
                      onTap: _runBulkImport,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Quiz Card (Result)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _quizCard(Quiz q) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => QuestionDetailsScreen(
              docId: q.id,
              quizRepo: widget.quizRepo,
              setSaving: widget.setSaving,
              snack: widget.snack,
              confirm: widget.confirm,
            ),
          ),
        );
        if (result == true) {
          await _runSearch();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                adminStatusBadge(q.isActive),
                const Spacer(),
                Text(
                  '${_leagueLabels[q.category] ?? q.category} • ${q.league}',
                  style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              q.question,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.touch_app_rounded,
                    size: 14, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(
                  'اضغط للتفاصيل',
                  style: GoogleFonts.cairo(
                    fontSize: 10,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
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

  Widget _expandableSection({
    required String title,
    required IconData icon,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: onToggle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.primaryDeepTeal,
                ),
                const SizedBox(width: 8),
                Icon(icon, size: 18, color: AppColors.secondaryOrange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: AppColors.primaryDeepTeal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppColors.primaryDeepTeal.withValues(alpha: 0.1)),
            ),
            child: child,
          ),
      ],
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
            activeColor: AppColors.secondaryOrange,
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 42),
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: Icon(icon, size: 18, color: Colors.white),
        label: Text(
          label,
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.w900,
            fontSize: 12,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

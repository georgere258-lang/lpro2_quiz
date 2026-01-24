// PATH: lib/presentation/screens/admin/tabs/admin_quiz_tab.dart
// Quiz tab for admin panel

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/models/admin_control_models.dart';
import '../../../../core/services/app_config_service.dart';
import '../../../../features/quizzes/models/quiz.dart';
import '../../../../features/quizzes/repositories/quiz_repository.dart';
import '../widgets/admin_shared_widgets.dart';

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
  String _selectedCategory = QuizCategory.general;
  String _selectedLeague = QuizLeague.bronze;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: DropdownButtonFormField<String>(value: _selectedCategory, items: QuizCategory.values.map((c) => DropdownMenuItem(value: c, child: Text(c, style: GoogleFonts.cairo(fontSize: 12)))).toList(), onChanged: (v) => setState(() => _selectedCategory = v ?? _selectedCategory), decoration: adminDropDecor())),
                const SizedBox(width: 8),
                Expanded(child: DropdownButtonFormField<String>(value: _selectedLeague, items: QuizLeague.values.map((l) => DropdownMenuItem(value: l, child: Text(l, style: GoogleFonts.cairo(fontSize: 12)))).toList(), onChanged: (v) => setState(() => _selectedLeague = v ?? _selectedLeague), decoration: adminDropDecor())),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<List<Quiz>>(
                stream: widget.quizRepo.watchByCategoryLeague(category: _selectedCategory, league: _selectedLeague, includeInactive: true, includeDeleted: false, limit: 50),
                builder: (ctx, snap) {
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                  final quizzes = snap.data!;
                  if (quizzes.isEmpty) return Center(child: Text('لا توجد أسئلة', style: GoogleFonts.cairo()));
                  return ListView.separated(
                    itemCount: quizzes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) => _quizCard(quizzes[i]),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            adminCenterBtn(onPressed: () => _openQuizEditor(), bg: AppColors.secondaryOrange, child: adminBtnText('إضافة سؤال جديد', size: 12)),
          ],
        ),
      ),
    );
  }

  Widget _quizCard(Quiz q) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.black.withValues(alpha: 0.08))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [adminStatusBadge(q.isActive), const Spacer(), Text('${q.league} • ${q.category}', style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey))]),
          const SizedBox(height: 8),
          Text(q.question, style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          ...q.options.asMap().entries.map((e) => Text('${e.key + 1}. ${e.value}${e.key == q.correctOptionIndex ? ' ✓' : ''}', style: GoogleFonts.cairo(fontSize: 11, color: e.key == q.correctOptionIndex ? Colors.green : Colors.black87))),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              adminTinyBtn(q.isActive ? 'إخفاء' : 'إظهار', () async { widget.setSaving(true); try { await widget.quizRepo.toggleActive(q.id, !q.isActive); widget.snack('✅'); } catch (_) { widget.snack('فشل'); } finally { widget.setSaving(false); } }),
              adminTinyBtn('تعديل', () => _openQuizEditor(quiz: q)),
              adminTinyBtn('نقل', () => _openMoveQuizDialog(q)),
              adminTinyBtn('حذف', () async { if (await widget.confirm('حذف السؤال؟', 'سيتم إخفاء السؤال نهائياً')) { widget.setSaving(true); try { await widget.quizRepo.softDelete(q.id); widget.snack('تم الحذف ✅'); } catch (_) { widget.snack('فشل'); } finally { widget.setSaving(false); } } }),
              adminTinyBtn('مشاركة', () {
                if (!AppConfigService().quizShareEnabled) {
                  widget.snack('المشاركة غير متاحة حالياً');
                  return;
                }
                final payload = widget.quizRepo.buildSharePayload(q);
                Clipboard.setData(ClipboardData(text: payload['deepLink']));
                widget.snack('تم نسخ الرابط ✅');
              }),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openQuizEditor({Quiz? quiz}) async {
    final qC = TextEditingController(text: quiz?.question ?? '');
    final o0 = TextEditingController(text: quiz?.options.elementAtOrNull(0) ?? '');
    final o1 = TextEditingController(text: quiz?.options.elementAtOrNull(1) ?? '');
    final o2 = TextEditingController(text: quiz?.options.elementAtOrNull(2) ?? '');
    final o3 = TextEditingController(text: quiz?.options.elementAtOrNull(3) ?? '');
    int correct = quiz?.correctOptionIndex ?? 0;
    String cat = quiz?.category ?? _selectedCategory;
    String league = quiz?.league ?? _selectedLeague;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) => Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 12),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(quiz == null ? 'إضافة سؤال' : 'تعديل سؤال', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  adminTextField(qC, 'نص السؤال...', maxLines: 2),
                  const SizedBox(height: 8),
                  adminTextField(o0, 'اختيار 1'), const SizedBox(height: 6),
                  adminTextField(o1, 'اختيار 2'), const SizedBox(height: 6),
                  adminTextField(o2, 'اختيار 3'), const SizedBox(height: 6),
                  adminTextField(o3, 'اختيار 4'), const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: DropdownButtonFormField<String>(value: cat, items: QuizCategory.values.map((c) => DropdownMenuItem(value: c, child: Text(c, style: GoogleFonts.cairo(fontSize: 12)))).toList(), onChanged: (v) => setLocal(() => cat = v ?? cat), decoration: adminDropDecor())),
                      const SizedBox(width: 8),
                      Expanded(child: DropdownButtonFormField<String>(value: league, items: QuizLeague.values.map((l) => DropdownMenuItem(value: l, child: Text(l, style: GoogleFonts.cairo(fontSize: 12)))).toList(), onChanged: (v) => setLocal(() => league = v ?? league), decoration: adminDropDecor())),
                    ],
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(value: correct, items: List.generate(4, (i) => DropdownMenuItem(value: i, child: Text('الإجابة الصحيحة: ${i + 1}', style: GoogleFonts.cairo(fontSize: 12)))), onChanged: (v) => setLocal(() => correct = v ?? 0), decoration: adminDropDecor()),
                  const SizedBox(height: 12),
                  adminCenterBtn(
                    onPressed: () async {
                      final nav = Navigator.of(context);
                      final options = [o0.text.trim(), o1.text.trim(), o2.text.trim(), o3.text.trim()].where((o) => o.isNotEmpty).toList();
                      if (qC.text.trim().length < 10 || options.length < 2) { widget.snack('أكمل البيانات'); return; }
                      widget.setSaving(true);
                      try {
                        final control = AdminControlFields(isActive: quiz?.isActive ?? true, sectionKey: FirestorePaths.sectionKeyQuiz);
                        final newQuiz = Quiz(id: quiz?.id ?? '', question: qC.text.trim(), options: options, correctOptionIndex: correct.clamp(0, options.length - 1), category: cat, league: league, control: control);
                        newQuiz.validate();
                        if (quiz == null) {
                          await widget.quizRepo.create(newQuiz);
                        } else {
                          await widget.quizRepo.update(quiz.id, newQuiz.toFirestore());
                        }
                        widget.snack('✅');
                        nav.pop();
                      } catch (e) {
                        widget.snack('خطأ: $e');
                      } finally {
                        widget.setSaving(false);
                      }
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
      ),
    );
  }

  Future<void> _openMoveQuizDialog(Quiz q) async {
    String newCat = q.category;
    String newLeague = q.league;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text('نقل السؤال', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(value: newCat, items: QuizCategory.values.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), onChanged: (v) => setLocal(() => newCat = v ?? newCat), decoration: adminDropDecor()),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(value: newLeague, items: QuizLeague.values.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(), onChanged: (v) => setLocal(() => newLeague = v ?? newLeague), decoration: adminDropDecor()),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('إلغاء', style: GoogleFonts.cairo())),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                widget.setSaving(true);
                try { await widget.quizRepo.move(q.id, newCategory: newCat, newLeague: newLeague); widget.snack('تم النقل ✅'); } catch (_) { widget.snack('فشل'); } finally { widget.setSaving(false); }
              },
              child: Text('نقل', style: GoogleFonts.cairo(color: AppColors.primaryDeepTeal)),
            ),
          ],
        ),
      ),
    );
  }
}

// PATH: lib/presentation/screens/admin_panel.dart
// STATUS: Full File – Buttons text no clipping + Pro Card + Quizzes (Single + Batch + List + Delete)

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // ---------- Tab 1: Pro Card ----------
  final TextEditingController _proController = TextEditingController();

  // ---------- Tab 2: Quizzes ----------
  final TextEditingController _qText = TextEditingController();
  final TextEditingController _opt0 = TextEditingController();
  final TextEditingController _opt1 = TextEditingController();
  final TextEditingController _opt2 = TextEditingController();
  final TextEditingController _opt3 = TextEditingController();

  int _correctIndex = 0;
  String _category = "دوري النجوم";

  // Batch JSON paste
  final TextEditingController _batchJson = TextEditingController();

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _proController.dispose();

    _qText.dispose();
    _opt0.dispose();
    _opt1.dispose();
    _opt2.dispose();
    _opt3.dispose();
    _batchJson.dispose();

    super.dispose();
  }

  // =========================
  // Helpers
  // =========================
  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, textAlign: TextAlign.right)),
    );
  }

  String _trim(TextEditingController c) => c.text.trim();

  List<String> _options() => [
        _trim(_opt0),
        _trim(_opt1),
        _trim(_opt2),
        _trim(_opt3),
      ];

  bool _validateSingleQuestion() {
    final q = _trim(_qText);
    if (q.isEmpty) return false;

    final ops = _options();
    if (ops.any((e) => e.isEmpty)) return false;

    if (_correctIndex < 0 || _correctIndex > 3) return false;

    return true;
  }

  String _autoDocId() {
    final ms = DateTime.now().millisecondsSinceEpoch;
    return "${_category}_$ms";
  }

  Map<String, dynamic> _buildQuizDoc({
    required String category,
    required String question,
    required List<String> options,
    required int correctAnswer,
  }) {
    return {
      "category": category,
      "question": question,
      "options": options,
      "correctAnswer": correctAnswer,
      "createdAt": FieldValue.serverTimestamp(),
      "isHidden": false,
    };
  }

  Widget _btnText(String text,
      {Color color = Colors.white, double size = 13.5}) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: GoogleFonts.cairo(
          fontWeight: FontWeight.w900,
          fontSize: size,
          color: color,
          height: 1.1,
        ),
      ),
    );
  }

  // =========================
  // Actions
  // =========================
  Future<void> _publishProCard() async {
    final text = _trim(_proController);
    if (text.isEmpty) {
      _snack("اكتب نص المعلومة الأول.");
      return;
    }

    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance
          .collection('home_pro_card')
          .doc('current')
          .set({
        'text': text,
        'isActive': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _snack("تم نشر المعلومة ✅");
    } catch (_) {
      _snack("فشل النشر. تأكد من الصلاحيات (Rules).");
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _uploadSingleQuestion() async {
    if (!_validateSingleQuestion()) {
      _snack("راجع السؤال والاختيارات (لازم 4 اختيارات + إجابة صحيحة).");
      return;
    }

    setState(() => _saving = true);
    try {
      final docId = _autoDocId();

      await FirebaseFirestore.instance.collection("quizzes").doc(docId).set(
            _buildQuizDoc(
              category: _category,
              question: _trim(_qText),
              options: _options(),
              correctAnswer: _correctIndex,
            ),
          );

      _snack("تم رفع السؤال ✅");

      _qText.clear();
      _opt0.clear();
      _opt1.clear();
      _opt2.clear();
      _opt3.clear();
      setState(() => _correctIndex = 0);
    } catch (_) {
      _snack("فشل الرفع. غالبًا Rules مانعة كتابة quizzes للأدمن.");
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _uploadBatchJson() async {
    final raw = _trim(_batchJson);
    if (raw.isEmpty) {
      _snack("الصق JSON الأول.");
      return;
    }

    setState(() => _saving = true);
    try {
      final decoded = jsonDecode(raw);

      if (decoded is! List) {
        _snack("لازم JSON يكون Array [...].");
        return;
      }

      final batch = FirebaseFirestore.instance.batch();
      int count = 0;

      for (final item in decoded) {
        if (item is! Map) continue;

        final q = (item["question"] ?? "").toString().trim();
        final opts = (item["options"] is List)
            ? (item["options"] as List).map((e) => e.toString()).toList()
            : <String>[];
        final ca = item["correctAnswer"];
        final category = (item["category"] ?? _category).toString().trim();

        if (q.isEmpty) continue;
        if (opts.length != 4) continue;
        if (ca is! int || ca < 0 || ca > 3) continue;

        final docId =
            "${category}_${DateTime.now().millisecondsSinceEpoch}_$count";
        final ref = FirebaseFirestore.instance.collection("quizzes").doc(docId);

        batch.set(
          ref,
          _buildQuizDoc(
            category: category,
            question: q,
            options: opts,
            correctAnswer: ca,
          ),
        );

        count++;
      }

      if (count == 0) {
        _snack("مفيش عناصر صالحة في الـ JSON. تأكد من الشكل.");
        return;
      }

      await batch.commit();
      _snack("تم رفع Batch: $count سؤال ✅");
      _batchJson.clear();
    } catch (_) {
      _snack("JSON غير صالح. لازم يكون Array من Objects.");
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteQuizDoc(String docId) async {
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance
          .collection("quizzes")
          .doc(docId)
          .delete();
      _snack("تم حذف السؤال ✅");
    } catch (_) {
      _snack("فشل الحذف. تأكد من Rules وصلاحيات الأدمن.");
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("لوحة التحكم",
            style: GoogleFonts.cairo(fontWeight: FontWeight.w900)),
        backgroundColor: AppColors.primaryDeepTeal,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.secondaryOrange,
          labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w900),
          labelPadding: const EdgeInsets.symmetric(horizontal: 12),
          tabs: const [
            Tab(
                child: FittedBox(
                    fit: BoxFit.scaleDown, child: Text("معلومة Pro"))),
            Tab(
                child:
                    FittedBox(fit: BoxFit.scaleDown, child: Text("الدوريات"))),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _buildProCardTab(),
              _buildQuizzesTab(),
            ],
          ),
          if (_saving)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: Colors.black.withOpacity(0.05),
                  child: const Center(
                    child: SizedBox(
                      width: 34,
                      height: 34,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProCardTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          TextField(
            controller: _proController,
            maxLines: 4,
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              hintText: "اكتب معلومة Pro...",
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryOrange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _publishProCard,
              child: _btnText("نشر فوري"),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "ملاحظة: نشر المعلومة يحتاج صلاحيات Admin في Firestore Rules.",
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.black54,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildQuizzesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _card(
            title: "إضافة سؤال واحد",
            child: Column(
              children: [
                _rowLabel("اختر الدوري"),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  items: const [
                    DropdownMenuItem(
                        value: "دوري النجوم", child: Text("دوري النجوم")),
                    DropdownMenuItem(
                        value: "دوري المحترفين", child: Text("دوري المحترفين")),
                  ],
                  onChanged: (v) => setState(() => _category = v ?? _category),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _textBox(controller: _qText, hint: "نص السؤال"),
                const SizedBox(height: 10),
                _textBox(controller: _opt0, hint: "اختيار 1"),
                const SizedBox(height: 8),
                _textBox(controller: _opt1, hint: "اختيار 2"),
                const SizedBox(height: 8),
                _textBox(controller: _opt2, hint: "اختيار 3"),
                const SizedBox(height: 8),
                _textBox(controller: _opt3, hint: "اختيار 4"),
                const SizedBox(height: 12),
                _rowLabel("الإجابة الصحيحة"),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  initialValue: _correctIndex,
                  items: const [
                    DropdownMenuItem(value: 0, child: Text("اختيار 1")),
                    DropdownMenuItem(value: 1, child: Text("اختيار 2")),
                    DropdownMenuItem(value: 2, child: Text("اختيار 3")),
                    DropdownMenuItem(value: 3, child: Text("اختيار 4")),
                  ],
                  onChanged: (v) => setState(() => _correctIndex = v ?? 0),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondaryOrange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _uploadSingleQuestion,
                    child: _btnText("رفع السؤال"),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _card(
            title: "رفع Batch JSON (سريع)",
            subtitle:
                "الصيغة: Array من Objects — كل Object فيه question و options(4) و correctAnswer (0..3) و category اختياري",
            child: Column(
              children: [
                TextField(
                  controller: _batchJson,
                  maxLines: 8,
                  textAlign: TextAlign.left,
                  decoration: InputDecoration(
                    hintText:
                        '[\n  {"category":"دوري النجوم","question":"...","options":["a","b","c","d"],"correctAnswer":2}\n]',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDeepTeal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _uploadBatchJson,
                    child: _btnText("رفع الـ Batch"),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _card(
            title: "آخر الأسئلة (للمراجعة والحذف)",
            child: _recentQuizzesList(),
          ),
        ],
      ),
    );
  }

  Widget _recentQuizzesList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection("quizzes")
          .orderBy("createdAt", descending: true)
          .limit(30)
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Text(
            "خطأ في القراءة — تأكد من Rules (allow read).",
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
          );
        }
        if (!snap.hasData) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return Text(
            "لا توجد أسئلة الآن.",
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(fontWeight: FontWeight.w900),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final doc = docs[i];
            final data = doc.data();

            final category = (data["category"] ?? "").toString();
            final question = (data["question"] ?? "").toString();

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.primaryDeepTeal.withOpacity(0.10),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    category,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AppColors.secondaryOrange,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    question,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.cairo(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryDeepTeal,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => _deleteQuizDoc(doc.id),
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.red, size: 18),
                      label: Text(
                        "حذف",
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.w900,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // =========================
  // Small UI helpers
  // =========================
  Widget _card(
      {required String title, String? subtitle, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: AppColors.primaryDeepTeal.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            textAlign: TextAlign.right,
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: AppColors.primaryDeepTeal,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.right,
              style: GoogleFonts.cairo(
                fontSize: 12,
                height: 1.6,
                fontWeight: FontWeight.w700,
                color: Colors.black54,
              ),
            ),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _rowLabel(String text) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        text,
        style: GoogleFonts.cairo(
          fontWeight: FontWeight.w900,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _textBox(
      {required TextEditingController controller, required String hint}) {
    return TextField(
      controller: controller,
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

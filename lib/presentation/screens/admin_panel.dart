// PATH: lib/presentation/screens/admin_panel.dart
// STATUS: Full File – ✅ Pro Card CMS + Quizzes (single + batch) + News Ticker Admin (CRUD) + Know Client placeholder
//
// FIXES (Critical):
// - News ticker writes ALWAYS include updatedAt (serverTimestamp).
// - toggle/edit also update updatedAt.
// - startDate/endDate never written as null; if cleared -> FieldValue.delete().
//
// ✅ NEW (Stability):
// - Admin list stream no longer uses orderBy(createdAt) to avoid transient-null freezes.
// - Stable client-side sorting: priority desc, updatedAt desc, docId desc.

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../features/pro_card/repositories/pro_card_repository.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // =========================
  // Tab 1: Pro Card (CMS)
  // =========================
  final ProCardRepository _proCardRepo = ProCardRepository();

  // =========================
  // Tab 2: Quizzes (Single + Batch)
  // =========================
  final TextEditingController _qText = TextEditingController();
  final TextEditingController _opt0 = TextEditingController();
  final TextEditingController _opt1 = TextEditingController();
  final TextEditingController _opt2 = TextEditingController();
  final TextEditingController _opt3 = TextEditingController();
  final TextEditingController _batchJson = TextEditingController();

  final List<String> _quizCategories = const ["دوري النجوم", "دوري المحترفين"];
  String _selectedCategory = "دوري النجوم";
  int _correctIndex = 0;

  // =========================
  // Tab 3: News Ticker (CRUD)
  // =========================
  static const String _tickerCol = "news_ticker_items";
  final TextEditingController _tickerText = TextEditingController();
  int _tickerPriority = 0;
  bool _tickerNotify = false;
  DateTime? _tickerStart;
  DateTime? _tickerEnd;

  // =========================
  // Tab 4: Know Client (placeholder)
  // =========================
  static const String _kycCollection = "know_your_client";
  static const String _kycNotificationsQueue = "notifications_queue";
  static const List<String> _kycSections = [
    'أساسيات العميل',
    'أنماط الشخصيات',
    'الدوافع والاحتياجات',
    'الاعتراضات والردود',
    'التفاوض',
    'إغلاق الصفقة',
    'متابعة وما بعد البيع',
  ];
  final String _kycFilterSection = 'الكل';
  final TextEditingController _kycSearch = TextEditingController();

  bool _saving = false;

  // UI constants
  static const double _btnW = 220;
  static const double _btnH = 44;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();

    _qText.dispose();
    _opt0.dispose();
    _opt1.dispose();
    _opt2.dispose();
    _opt3.dispose();
    _batchJson.dispose();

    _tickerText.dispose();

    _kycSearch.dispose();
    super.dispose();
  }

  // =========================
  // Helpers
  // =========================
  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          textAlign: TextAlign.right,
          style: GoogleFonts.cairo(),
        ),
      ),
    );
  }

  String _trim(TextEditingController c) => c.text.trim();

  Widget _btnText(String text,
      {Color color = Colors.white, double size = 13.5}) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        text,
        maxLines: 1,
        style: GoogleFonts.cairo(
          fontWeight: FontWeight.w900,
          fontSize: size,
          color: color,
        ),
      ),
    );
  }

  Widget _tf(TextEditingController c, String hint, {int maxLines = 1}) {
    return TextField(
      controller: c,
      maxLines: maxLines,
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

  Widget _centerBtn({
    required VoidCallback? onPressed,
    required Widget child,
    Color? bg,
  }) {
    return Align(
      alignment: Alignment.center,
      child: SizedBox(
        width: _btnW,
        height: _btnH,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: bg,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: child,
        ),
      ),
    );
  }

  Future<DateTime?> _pickDateTime(BuildContext context) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 3),
      initialDate: now,
    );
    if (date == null) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(minutes: 10))),
    );
    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  String _dtStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  // =========================
  // Pro Card
  // =========================
  Future<void> _openProEditor({Map<String, dynamic>? current}) async {
    final textC =
        TextEditingController(text: (current?['text'] ?? '').toString());
    bool isActive = current?['isActive'] == true;

    DateTime? publishAt = (current?['publishAt'] is Timestamp)
        ? (current!['publishAt'] as Timestamp).toDate()
        : null;

    DateTime? expireAt = (current?['expireAt'] is Timestamp)
        ? (current!['expireAt'] as Timestamp).toDate()
        : null;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('رسالة Pro الحية',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
              _tf(textC, 'نص الرسالة...', maxLines: 4),
              SwitchListTile(
                value: isActive,
                onChanged: (v) => setLocal(() => isActive = v),
                title: Text('ظاهر (isActive)',
                    style: GoogleFonts.cairo(fontSize: 12)),
              ),
              ListTile(
                title: Text(
                  'وقت النشر (publishAt): ${publishAt != null ? _dtStr(publishAt!) : "—"}',
                  style: GoogleFonts.cairo(fontSize: 12),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_month),
                  onPressed: () async {
                    final dt = await _pickDateTime(context);
                    if (dt != null) setLocal(() => publishAt = dt);
                  },
                ),
              ),
              ListTile(
                title: Text(
                  'وقت الانتهاء (expireAt): ${expireAt != null ? _dtStr(expireAt!) : "—"}',
                  style: GoogleFonts.cairo(fontSize: 12),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_month),
                  onPressed: () async {
                    final dt = await _pickDateTime(context);
                    if (dt != null) setLocal(() => expireAt = dt);
                  },
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryDeepTeal),
                      onPressed: () async {
                        final text = textC.text.trim();
                        setState(() => _saving = true);
                        try {
                          await _proCardRepo.setCurrent(
                            text: text,
                            isActive: isActive,
                            publishAt: publishAt,
                            expireAt: expireAt,
                          );
                          _snack('تم الحفظ ✅');
                          if (!mounted) return;
                          Navigator.pop(context);
                        } catch (_) {
                          _snack('فشل الحفظ. راجع Rules.');
                        } finally {
                          if (mounted) setState(() => _saving = false);
                        }
                      },
                      child: _btnText('حفظ'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondaryOrange),
                      onPressed: () async {
                        final text = textC.text.trim();
                        setState(() => _saving = true);
                        try {
                          await _proCardRepo.setCurrent(
                            text: text,
                            isActive: true,
                            publishAt: DateTime.now(),
                            expireAt: expireAt,
                          );
                          _snack('تم النشر الآن ✅');
                          if (!mounted) return;
                          Navigator.pop(context);
                        } catch (_) {
                          _snack('فشل النشر.');
                        } finally {
                          if (mounted) setState(() => _saving = false);
                        }
                      },
                      child: _btnText('نشر الآن'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _centerBtn(
                onPressed: () async {
                  if (publishAt == null) {
                    _snack('اختر وقت النشر (publishAt) أولاً.');
                    return;
                  }
                  final text = textC.text.trim();
                  setState(() => _saving = true);
                  try {
                    await _proCardRepo.setCurrent(
                      text: text,
                      isActive: false,
                      publishAt: publishAt,
                      expireAt: expireAt,
                    );
                    _snack('تمت الجدولة ✅');
                    if (!mounted) return;
                    Navigator.pop(context);
                  } catch (_) {
                    _snack('فشل الجدولة.');
                  } finally {
                    if (mounted) setState(() => _saving = false);
                  }
                },
                bg: Colors.black87,
                child: _btnText('جدولة', size: 12.5),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  // =========================
  // Quizzes: Add Single
  // =========================
  Future<void> _addSingleQuestion() async {
    final q = _trim(_qText);
    final o0 = _trim(_opt0);
    final o1 = _trim(_opt1);
    final o2 = _trim(_opt2);
    final o3 = _trim(_opt3);

    if (q.isEmpty || o0.isEmpty || o1.isEmpty || o2.isEmpty || o3.isEmpty) {
      _snack('املأ السؤال وكل الاختيارات.');
      return;
    }

    final options = [o0, o1, o2, o3];

    setState(() => _saving = true);
    try {
      final docId =
          "${_selectedCategory}_${DateTime.now().millisecondsSinceEpoch}";
      await FirebaseFirestore.instance.collection("quizzes").doc(docId).set({
        "question": q,
        "options": options,
        "correctAnswer": _correctIndex,
        "category": _selectedCategory,
        "createdAt": FieldValue.serverTimestamp(),
        "isHidden": false,
      });
      _snack("تمت الإضافة ✅");
      _qText.clear();
      _opt0.clear();
      _opt1.clear();
      _opt2.clear();
      _opt3.clear();
      setState(() => _correctIndex = 0);
    } catch (_) {
      _snack("فشل الإضافة. راجع Rules.");
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // =========================
  // Quizzes: Batch Upload
  // =========================
  Future<void> _uploadBatchJson() async {
    final raw = _trim(_batchJson);
    if (raw.isEmpty) return;

    setState(() => _saving = true);
    try {
      final decoded = jsonDecode(raw) as List;
      final batch = FirebaseFirestore.instance.batch();

      for (var i = 0; i < decoded.length; i++) {
        final item = decoded[i] as Map<String, dynamic>;

        final String category =
            (item["category"] ?? _selectedCategory).toString();
        final String question = (item["question"] ?? "").toString();
        final List<String> options =
            List<String>.from(item["options"] ?? const []);
        final int correct = (item["correctAnswer"] ?? 0) as int;

        if (question.trim().isEmpty || options.length != 4) continue;

        final docId = "${category}_${DateTime.now().millisecondsSinceEpoch}_$i";

        batch.set(FirebaseFirestore.instance.collection("quizzes").doc(docId), {
          "question": question.trim(),
          "options": options,
          "correctAnswer": correct,
          "category": category,
          "createdAt": FieldValue.serverTimestamp(),
          "isHidden": false,
        });
      }

      await batch.commit();
      _snack("تم الرفع ✅");
      _batchJson.clear();
    } catch (_) {
      _snack("خطأ في JSON");
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // =========================
  // News Ticker: CRUD
  // =========================
  Map<String, dynamic> _tickerPayload({
    required String textAr,
    required int priority,
    required bool isActive,
    required bool notify,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final data = <String, dynamic>{
      'text_ar': textAr.trim(),
      'priority': priority,
      'isActive': isActive,
      'notify': notify,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(), // ✅ FIX
      'source': 'admin',
    };

    if (startDate != null) {
      data['startDate'] = Timestamp.fromDate(startDate);
    }
    if (endDate != null) {
      data['endDate'] = Timestamp.fromDate(endDate);
    }

    return data;
  }

  Future<void> _addTickerItem() async {
    final text = _trim(_tickerText);
    if (text.isEmpty) {
      _snack('اكتب نص الخبر.');
      return;
    }

    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection(_tickerCol).add(
            _tickerPayload(
              textAr: text,
              priority: _tickerPriority,
              isActive: true,
              notify: _tickerNotify,
              startDate: _tickerStart,
              endDate: _tickerEnd,
            ),
          );
      _snack('تمت الإضافة ✅');
      _tickerText.clear();
      setState(() {
        _tickerPriority = 0;
        _tickerNotify = false;
        _tickerStart = null;
        _tickerEnd = null;
      });
    } catch (_) {
      _snack('فشل الإضافة. راجع Rules.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _toggleTickerActive(String docId, bool current) async {
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance
          .collection(_tickerCol)
          .doc(docId)
          .update({
        'isActive': !current,
        'updatedAt': FieldValue.serverTimestamp(), // ✅ FIX
      });
      _snack(current ? 'تم الإخفاء ✅' : 'تم الإظهار ✅');
    } catch (_) {
      _snack('فشل التعديل.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteTicker(String docId) async {
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance
          .collection(_tickerCol)
          .doc(docId)
          .delete();
      _snack('تم الحذف ✅');
    } catch (_) {
      _snack('فشل الحذف.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openEditTickerSheet({
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    final c = TextEditingController(text: (data['text_ar'] ?? '').toString());
    int pr = (data['priority'] ?? 0) is int ? (data['priority'] as int) : 0;
    bool active = data['isActive'] == true;
    bool notify = data['notify'] == true;

    DateTime? start = data['startDate'] is Timestamp
        ? (data['startDate'] as Timestamp).toDate()
        : null;
    DateTime? end = data['endDate'] is Timestamp
        ? (data['endDate'] as Timestamp).toDate()
        : null;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('تعديل خبر الشريط',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
              _tf(c, 'نص الخبر...', maxLines: 3),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: pr,
                      items: List.generate(
                        11,
                        (i) => DropdownMenuItem(
                          value: i,
                          child: Text('الأولوية: $i',
                              style: GoogleFonts.cairo(fontSize: 12)),
                        ),
                      ),
                      onChanged: (v) => setLocal(() => pr = v ?? 0),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SwitchListTile(
                      value: notify,
                      onChanged: (v) => setLocal(() => notify = v),
                      title: Text('إرسال إشعار',
                          style: GoogleFonts.cairo(fontSize: 12)),
                    ),
                  ),
                ],
              ),
              SwitchListTile(
                value: active,
                onChanged: (v) => setLocal(() => active = v),
                title: Text('ظاهر في الشريط',
                    style: GoogleFonts.cairo(fontSize: 12)),
              ),
              ListTile(
                title: Text(
                  'بداية الظهور: ${start != null ? _dtStr(start!) : "—"}',
                  style: GoogleFonts.cairo(fontSize: 12),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_month),
                  onPressed: () async {
                    final dt = await _pickDateTime(context);
                    if (dt != null) setLocal(() => start = dt);
                  },
                ),
              ),
              ListTile(
                title: Text(
                  'نهاية الظهور: ${end != null ? _dtStr(end!) : "—"}',
                  style: GoogleFonts.cairo(fontSize: 12),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_month),
                  onPressed: () async {
                    final dt = await _pickDateTime(context);
                    if (dt != null) setLocal(() => end = dt);
                  },
                ),
              ),
              const SizedBox(height: 10),
              _centerBtn(
                onPressed: () async {
                  final text = c.text.trim();
                  if (text.isEmpty) {
                    _snack('النص فارغ.');
                    return;
                  }
                  setState(() => _saving = true);
                  try {
                    final update = <String, dynamic>{
                      'text_ar': text,
                      'priority': pr,
                      'isActive': active,
                      'notify': notify,
                      'source': 'admin',
                      'updatedAt': FieldValue.serverTimestamp(), // ✅ FIX
                    };

                    if (start != null) {
                      update['startDate'] = Timestamp.fromDate(start!);
                    } else {
                      update['startDate'] = FieldValue.delete();
                    }

                    if (end != null) {
                      update['endDate'] = Timestamp.fromDate(end!);
                    } else {
                      update['endDate'] = FieldValue.delete();
                    }

                    await FirebaseFirestore.instance
                        .collection(_tickerCol)
                        .doc(docId)
                        .update(update);

                    _snack('تم الحفظ ✅');
                    if (!mounted) return;
                    Navigator.pop(context);
                  } catch (_) {
                    _snack('فشل الحفظ.');
                  } finally {
                    if (mounted) setState(() => _saving = false);
                  }
                },
                bg: AppColors.primaryDeepTeal,
                child: _btnText('حفظ التعديل', size: 12.5),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "لوحة التحكم الاستراتيجية",
          style: GoogleFonts.cairo(fontWeight: FontWeight.w900),
        ),
        backgroundColor: AppColors.primaryDeepTeal,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.secondaryOrange,
          tabs: const [
            Tab(text: "Pro Card"),
            Tab(text: "Quizzes"),
            Tab(text: "شريط الأخبار"),
            Tab(text: "اعرف عميلك"),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _buildProTab(),
              _buildQuizTab(),
              _buildTickerTab(),
              _buildKycTab(),
            ],
          ),
          if (_saving)
            Positioned.fill(
              child: Container(
                color: Colors.black12,
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProTab() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _centerBtn(
              onPressed: () => _openProEditor(),
              bg: AppColors.primaryDeepTeal,
              child: _btnText('تعديل / إنشاء الرسالة الحية', size: 12.5),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<Map<String, dynamic>?>(
                stream: _proCardRepo.watchCurrent(),
                builder: (ctx, snap) {
                  if (!snap.hasData) {
                    return Center(
                      child: snap.connectionState == ConnectionState.waiting
                          ? const CircularProgressIndicator()
                          : Text(
                              'لا توجد رسالة. اضغط زر "تعديل / إنشاء".',
                              style: GoogleFonts.cairo(fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                    );
                  }
                  final d = snap.data;
                  if (d == null ||
                      (d['text'] ?? '').toString().trim().isEmpty) {
                    return Center(
                      child: Text(
                        'لا توجد رسالة. اضغط زر "تعديل / إنشاء".',
                        style: GoogleFonts.cairo(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  final text = (d['text'] ?? '').toString();
                  final isActive = d['isActive'] == true;

                  DateTime? publishAt = (d['publishAt'] is Timestamp)
                      ? (d['publishAt'] as Timestamp).toDate()
                      : null;
                  DateTime? expireAt = (d['expireAt'] is Timestamp)
                      ? (d['expireAt'] as Timestamp).toDate()
                      : null;

                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.primaryDeepTeal.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? Colors.green.withOpacity(0.2)
                                          : Colors.red.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      isActive ? 'ظاهر' : 'مخفي',
                                      style: GoogleFonts.cairo(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12,
                                        color: isActive
                                            ? Colors.green[800]
                                            : Colors.red[800],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(text,
                                  style: GoogleFonts.cairo(
                                      fontSize: 14, height: 1.6)),
                              const SizedBox(height: 10),
                              Text(
                                'وقت النشر: ${publishAt != null ? _dtStr(publishAt) : "—"}',
                                style: GoogleFonts.cairo(
                                    fontSize: 11, color: Colors.grey[700]),
                              ),
                              Text(
                                'وقت الانتهاء: ${expireAt != null ? _dtStr(expireAt) : "—"}',
                                style: GoogleFonts.cairo(
                                    fontSize: 11, color: Colors.grey[700]),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 120,
                              height: 40,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  setState(() => _saving = true);
                                  try {
                                    await _proCardRepo.setCurrent(
                                      text: text,
                                      isActive: !isActive,
                                      publishAt: publishAt,
                                      expireAt: expireAt,
                                    );
                                    _snack(isActive
                                        ? 'تم الإخفاء ✅'
                                        : 'تم الإظهار ✅');
                                  } catch (_) {
                                    _snack('فشل التعديل.');
                                  } finally {
                                    if (mounted)
                                      setState(() => _saving = false);
                                  }
                                },
                                icon: Icon(
                                  isActive
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  size: 18,
                                ),
                                label: _btnText(isActive ? 'إخفاء' : 'إظهار',
                                    size: 12),
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 120,
                              height: 40,
                              child: ElevatedButton.icon(
                                onPressed: () => _openProEditor(current: d),
                                icon: const Icon(Icons.edit, size: 18),
                                label: _btnText('تعديل', size: 12),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizTab() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    items: _quizCategories
                        .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(e,
                                  style: GoogleFonts.cairo(fontSize: 12)),
                            ))
                        .toList(),
                    onChanged: (v) => setState(
                        () => _selectedCategory = v ?? _selectedCategory),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('إضافة سؤال واحد',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    _tf(_qText, "نص السؤال...", maxLines: 2),
                    const SizedBox(height: 8),
                    _tf(_opt0, "اختيار 1", maxLines: 1),
                    const SizedBox(height: 6),
                    _tf(_opt1, "اختيار 2", maxLines: 1),
                    const SizedBox(height: 6),
                    _tf(_opt2, "اختيار 3", maxLines: 1),
                    const SizedBox(height: 6),
                    _tf(_opt3, "اختيار 4", maxLines: 1),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: _correctIndex,
                      items: const [
                        DropdownMenuItem(
                            value: 0, child: Text("الإجابة الصحيحة: 1")),
                        DropdownMenuItem(
                            value: 1, child: Text("الإجابة الصحيحة: 2")),
                        DropdownMenuItem(
                            value: 2, child: Text("الإجابة الصحيحة: 3")),
                        DropdownMenuItem(
                            value: 3, child: Text("الإجابة الصحيحة: 4")),
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
                    const SizedBox(height: 10),
                    _centerBtn(
                      onPressed: _addSingleQuestion,
                      bg: AppColors.secondaryOrange,
                      child: _btnText("إضافة السؤال", size: 12.5),
                    ),
                    const SizedBox(height: 18),
                    Text('رفع جماعي (JSON)',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    _tf(_batchJson, "JSON Array…", maxLines: 10),
                    const SizedBox(height: 8),
                    Text(
                      "صيغة كل عنصر:\n"
                      "{\n"
                      "  \"category\": \"دوري النجوم\",\n"
                      "  \"question\": \"...\",\n"
                      "  \"options\": [\"A\",\"B\",\"C\",\"D\"],\n"
                      "  \"correctAnswer\": 2\n"
                      "}",
                      style: GoogleFonts.cairo(fontSize: 11),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 10),
                    _centerBtn(
                      onPressed: _uploadBatchJson,
                      bg: AppColors.primaryDeepTeal,
                      child: _btnText("رفع الكل", size: 12.5),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTickerTab() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('إضافة خبر للشريط',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            _tf(_tickerText, "نص الخبر...", maxLines: 2),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _tickerPriority,
                    items: List.generate(
                      11,
                      (i) => DropdownMenuItem(
                        value: i,
                        child: Text('الأولوية: $i',
                            style: GoogleFonts.cairo(fontSize: 12)),
                      ),
                    ),
                    onChanged: (v) => setState(() => _tickerPriority = v ?? 0),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SwitchListTile(
                    value: _tickerNotify,
                    onChanged: (v) => setState(() => _tickerNotify = v),
                    title: Text('إرسال إشعار',
                        style: GoogleFonts.cairo(fontSize: 12)),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final dt = await _pickDateTime(context);
                      if (dt != null) setState(() => _tickerStart = dt);
                    },
                    icon: const Icon(Icons.calendar_month, size: 18),
                    label: _btnText(
                      _tickerStart == null
                          ? 'بداية الظهور'
                          : _dtStr(_tickerStart!),
                      color: Colors.black87,
                      size: 11.5,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final dt = await _pickDateTime(context);
                      if (dt != null) setState(() => _tickerEnd = dt);
                    },
                    icon: const Icon(Icons.calendar_month, size: 18),
                    label: _btnText(
                      _tickerEnd == null ? 'نهاية الظهور' : _dtStr(_tickerEnd!),
                      color: Colors.black87,
                      size: 11.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 38,
                  child: OutlinedButton(
                    onPressed: () => setState(() => _tickerStart = null),
                    child: Text('مسح البداية',
                        style: GoogleFonts.cairo(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 120,
                  height: 38,
                  child: OutlinedButton(
                    onPressed: () => setState(() => _tickerEnd = null),
                    child: Text('مسح النهاية',
                        style: GoogleFonts.cairo(fontSize: 12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _centerBtn(
              onPressed: _addTickerItem,
              bg: AppColors.primaryDeepTeal,
              child: _btnText("إضافة الخبر", size: 12.5),
            ),
            const SizedBox(height: 14),
            Text('الأخبار الحالية',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                // ✅ FIX: remove orderBy(createdAt) to avoid transient null freeze/index issues
                stream: FirebaseFirestore.instance
                    .collection(_tickerCol)
                    .orderBy('priority', descending: true)
                    .snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // ✅ Stable client-side sorting: priority desc, updatedAt desc, docId desc
                  final docs = [...snap.data!.docs];
                  docs.sort((a, b) {
                    final da = a.data();
                    final db = b.data();

                    final int pa =
                        (da['priority'] is int) ? da['priority'] as int : 0;
                    final int pb =
                        (db['priority'] is int) ? db['priority'] as int : 0;
                    if (pa != pb) return pb.compareTo(pa);

                    final Timestamp? ua = da['updatedAt'] as Timestamp?;
                    final Timestamp? ub = db['updatedAt'] as Timestamp?;
                    final int ta = ua?.millisecondsSinceEpoch ?? 0;
                    final int tb = ub?.millisecondsSinceEpoch ?? 0;
                    if (ta != tb) return tb.compareTo(ta);

                    return b.id.compareTo(a.id);
                  });

                  if (docs.isEmpty) {
                    return Center(
                      child: Text('لا توجد أخبار بعد.',
                          style: GoogleFonts.cairo()),
                    );
                  }

                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final doc = docs[i];
                      final d = doc.data();

                      final text = (d['text_ar'] ?? '').toString();
                      final isActive = d['isActive'] == true;
                      final pr = (d['priority'] ?? 0).toString();

                      DateTime? start = d['startDate'] is Timestamp
                          ? (d['startDate'] as Timestamp).toDate()
                          : null;
                      DateTime? end = d['endDate'] is Timestamp
                          ? (d['endDate'] as Timestamp).toDate()
                          : null;

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: Colors.black.withValues(alpha: 0.08)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? Colors.green.withOpacity(0.15)
                                        : Colors.red.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    isActive ? 'ظاهر' : 'مخفي',
                                    style: GoogleFonts.cairo(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                      color: isActive
                                          ? Colors.green[800]
                                          : Colors.red[800],
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text('الأولوية: $pr',
                                    style: GoogleFonts.cairo(
                                        fontWeight: FontWeight.w900)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(text,
                                style: GoogleFonts.cairo(
                                    fontSize: 13, height: 1.5)),
                            const SizedBox(height: 8),
                            Text(
                              'بداية: ${start != null ? _dtStr(start) : "—"}   |   نهاية: ${end != null ? _dtStr(end) : "—"}',
                              style: GoogleFonts.cairo(
                                  fontSize: 11, color: Colors.grey[700]),
                              textAlign: TextAlign.right,
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 110,
                                  height: 38,
                                  child: ElevatedButton.icon(
                                    onPressed: () =>
                                        _toggleTickerActive(doc.id, isActive),
                                    icon: Icon(
                                        isActive
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        size: 18),
                                    label: _btnText(
                                        isActive ? 'إخفاء' : 'إظهار',
                                        size: 12),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                SizedBox(
                                  width: 110,
                                  height: 38,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _openEditTickerSheet(
                                        docId: doc.id, data: d),
                                    icon: const Icon(Icons.edit, size: 18),
                                    label: _btnText('تعديل', size: 12),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                SizedBox(
                                  width: 44,
                                  height: 38,
                                  child: IconButton(
                                    onPressed: () => _deleteTicker(doc.id),
                                    icon: const Icon(
                                        Icons.delete_forever_rounded),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKycTab() {
    return const Center(child: Text("تبويب اعرف عميلك - جاهز للربط"));
  }
}

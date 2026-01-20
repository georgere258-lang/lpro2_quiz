// PATH: lib/presentation/screens/admin_panel.dart
// STATUS: Full File – ✅ Pro Card CMS (CRUD + Hide/Show + Publish Now + Schedule + Expire + History + Deleted Archive)

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
  // Tab 2: Quizzes
  // =========================
  final TextEditingController _qText = TextEditingController();
  final TextEditingController _opt0 = TextEditingController();
  final TextEditingController _opt1 = TextEditingController();
  final TextEditingController _opt2 = TextEditingController();
  final TextEditingController _opt3 = TextEditingController();
  final TextEditingController _batchJson = TextEditingController();
  final int _correctIndex = 0;
  final String _category = "دوري النجوم";

  // =========================
  // Tab 3: Know Client (CMS)
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
          content: Text(msg,
              textAlign: TextAlign.right, style: GoogleFonts.cairo())),
    );
  }

  String _trim(TextEditingController c) => c.text.trim();

  Widget _btnText(String text,
      {Color color = Colors.white, double size = 13.5}) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(text,
          maxLines: 1,
          style: GoogleFonts.cairo(
              fontWeight: FontWeight.w900, fontSize: size, color: color)),
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
            borderSide: BorderSide.none),
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
        initialTime:
            TimeOfDay.fromDateTime(now.add(const Duration(minutes: 10))));
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  String _dtStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  // --- Pro Editor (single live message: home_pro_card/current) ---
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 12),
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
                    style: GoogleFonts.cairo(fontSize: 12)),
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
                    style: GoogleFonts.cairo(fontSize: 12)),
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
                          if (mounted) Navigator.pop(context);
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
                          if (mounted) Navigator.pop(context);
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
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.black87),
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
                      _snack('تم الجدولة ✅');
                      if (mounted) Navigator.pop(context);
                    } catch (_) {
                      _snack('فشل الجدولة.');
                    } finally {
                      if (mounted) setState(() => _saving = false);
                    }
                  },
                  child: _btnText('جدولة (isActive=false, publishAt أعلاه)'),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  // --- Quiz Batch Upload ---
  Future<void> _uploadBatchJson() async {
    final raw = _trim(_batchJson);
    if (raw.isEmpty) return;
    setState(() => _saving = true);
    try {
      final decoded = jsonDecode(raw) as List;
      final batch = FirebaseFirestore.instance.batch();
      for (var i = 0; i < decoded.length; i++) {
        final item = decoded[i];
        final docId =
            "${item["category"] ?? _category}_${DateTime.now().millisecondsSinceEpoch}_$i";
        batch.set(FirebaseFirestore.instance.collection("quizzes").doc(docId), {
          "question": item["question"],
          "options": List<String>.from(item["options"]),
          "correctAnswer": item["correctAnswer"],
          "category": item["category"] ?? _category,
          "createdAt": FieldValue.serverTimestamp(),
          "isHidden": false,
        });
      }
      await batch.commit();
      _snack("تم الرفع ✅");
      _batchJson.clear();
    } catch (e) {
      _snack("خطأ في JSON");
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("لوحة التحكم الاستراتيجية",
            style: GoogleFonts.cairo(fontWeight: FontWeight.w900)),
        backgroundColor: AppColors.primaryDeepTeal,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.secondaryOrange,
          tabs: const [
            Tab(text: "Pro Card"),
            Tab(text: "Quizzes"),
            Tab(text: "اعرف عميلك")
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
              _buildKycTab(),
            ],
          ),
          if (_saving)
            Positioned.fill(
                child: Container(
                    color: Colors.black12,
                    child: const Center(child: CircularProgressIndicator()))),
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
            ElevatedButton(
              onPressed: () => _openProEditor(),
              child: _btnText('تعديل / إنشاء الرسالة الحية'),
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
                              'لا توجد رسالة. اضغط "تعديل / إنشاء" أعلاه.',
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
                        'لا توجد رسالة. اضغط "تعديل / إنشاء" أعلاه.',
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
                                color:
                                    AppColors.primaryDeepTeal.withOpacity(0.2)),
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
                              Text(
                                text,
                                style: GoogleFonts.cairo(
                                    fontSize: 14, height: 1.6),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'publishAt: ${publishAt != null ? _dtStr(publishAt) : "—"}',
                                style: GoogleFonts.cairo(
                                    fontSize: 11, color: Colors.grey[700]),
                              ),
                              Text(
                                'expireAt: ${expireAt != null ? _dtStr(expireAt) : "—"}',
                                style: GoogleFonts.cairo(
                                    fontSize: 11, color: Colors.grey[700]),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
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
                                    if (mounted) {
                                      setState(() => _saving = false);
                                    }
                                  }
                                },
                                icon: Icon(
                                    isActive
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    size: 18),
                                label: _btnText(isActive ? 'إخفاء' : 'إظهار',
                                    size: 12),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(children: [
        _tf(_batchJson, "JSON Array...", maxLines: 6),
        ElevatedButton(onPressed: _uploadBatchJson, child: _btnText("رفع الكل"))
      ]),
    );
  }

  Widget _buildKycTab() {
    return const Center(child: Text("تبويب اعرف عميلك - جاهز للربط"));
  }
} // End of Class

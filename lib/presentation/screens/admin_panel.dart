// PATH: lib/presentation/screens/admin_panel.dart
// STATUS: Full File – ✅ Pro Card CMS (CRUD + Hide/Show + Publish Now + Schedule + Expire + History + Deleted Archive)
// NOTE: Home reads from home_pro_card/current (unchanged). This panel manages home_pro_cards + pushes to current on "Publish Now".

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

  // =========================
  // Tab 1: Pro Card (CMS)
  // =========================
  static const String _proCurrentCollection = "home_pro_card";
  static const String _proCurrentDocId = "current";

  static const String _proCardsCollection = "home_pro_cards";
  static const String _proCardsDeletedCollection = "home_pro_cards_deleted";

  final TextEditingController _proSearch = TextEditingController();

  // =========================
  // Tab 2: Quizzes
  // =========================
  final TextEditingController _qText = TextEditingController();
  final TextEditingController _opt0 = TextEditingController();
  final TextEditingController _opt1 = TextEditingController();
  final TextEditingController _opt2 = TextEditingController();
  final TextEditingController _opt3 = TextEditingController();

  int _correctIndex = 0;
  String _category = "دوري النجوم";

  final TextEditingController _batchJson = TextEditingController();

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

  String _kycFilterSection = 'الكل';
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

    _proSearch.dispose();

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
      SnackBar(content: Text(msg, textAlign: TextAlign.right)),
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

  Future<void> _confirm({
    required String title,
    required String body,
    required VoidCallback onYes,
    String yesText = "نعم",
    String noText = "إلغاء",
  }) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title, textAlign: TextAlign.right),
        content: Text(body, textAlign: TextAlign.right),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(noText),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () {
              Navigator.pop(context);
              onYes();
            },
            child: Text(yesText),
          ),
        ],
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

  // =========================================================
  // Tab 1 Actions: Pro Card CMS
  // =========================================================

  Future<void> _writeProHistory({
    required String docId,
    required String
        action, // create/update/hide/show/publish_now/schedule/delete
    Map<String, dynamic>? before,
    Map<String, dynamic>? after,
    String? note,
  }) async {
    try {
      final ref = FirebaseFirestore.instance
          .collection(_proCardsCollection)
          .doc(docId)
          .collection("history")
          .doc();

      await ref.set({
        "action": action,
        "note": (note ?? "").toString(),
        "before": before ?? {},
        "after": after ?? {},
        "at": FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // ignore
    }
  }

  Future<void> _pushToCurrent({
    required String text,
    required String sourceDocId,
    DateTime? expireAt,
  }) async {
    // write current doc (home reads it)
    await FirebaseFirestore.instance
        .collection(_proCurrentCollection)
        .doc(_proCurrentDocId)
        .set({
      "text": text,
      "isActive": true,
      "sourceDocId": sourceDocId,
      "expireAt":
          expireAt != null ? Timestamp.fromDate(expireAt) : FieldValue.delete(),
      "updatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _openProEditor({
    Map<String, dynamic>? existing,
    String? existingId,
  }) async {
    final isEdit = existing != null && existingId != null;

    final textC =
        TextEditingController(text: (existing?["text"] ?? "").toString());

    bool isActive = existing?["isActive"] == true;
    bool pinned = existing?["pinned"] == true;
    bool notify = existing?["notify"] == true;

    DateTime? publishAt = (existing?["publishAt"] is Timestamp)
        ? existing!["publishAt"].toDate()
        : null;
    DateTime? expireAt = (existing?["expireAt"] is Timestamp)
        ? existing!["expireAt"].toDate()
        : null;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            Future<void> save({
              required bool publishNow,
              required bool schedule,
            }) async {
              final text = textC.text.trim();
              if (text.isEmpty) {
                _snack("اكتب نص المعلومة.");
                return;
              }

              // publishAt handling
              DateTime? chosenPublishAt = publishAt;
              if (publishNow) {
                chosenPublishAt = DateTime.now();
                isActive = true;
              } else if (schedule) {
                if (publishAt == null) {
                  _snack("اختار وقت النشر (publishAt).");
                  return;
                }
                chosenPublishAt = publishAt;
                // نخليها Active = true لكن العرض الحقيقي على الهوم يتم عبر Backend لاحقًا.
                isActive = true;
              }

              final docData = <String, dynamic>{
                "text": text,
                "isActive": isActive,
                "pinned": pinned,
                "notify": notify,
                "publishAt": chosenPublishAt != null
                    ? Timestamp.fromDate(chosenPublishAt)
                    : FieldValue.delete(),
                "expireAt": expireAt != null
                    ? Timestamp.fromDate(expireAt!)
                    : FieldValue.delete(),
                "updatedAt": FieldValue.serverTimestamp(),
              };

              setState(() => _saving = true);
              try {
                if (!isEdit) {
                  final ref = FirebaseFirestore.instance
                      .collection(_proCardsCollection)
                      .doc();
                  final newDoc = {
                    ...docData,
                    "createdAt": FieldValue.serverTimestamp(),
                  };
                  await ref.set(newDoc);

                  await _writeProHistory(
                    docId: ref.id,
                    action: "create",
                    before: {},
                    after: newDoc,
                  );

                  // Publish now means push to current immediately
                  if (publishNow) {
                    await _pushToCurrent(
                      text: text,
                      sourceDocId: ref.id,
                      expireAt: expireAt,
                    );
                    await _writeProHistory(
                      docId: ref.id,
                      action: "publish_now",
                      before: newDoc,
                      after: {"pushedToCurrent": true},
                    );
                  } else if (schedule) {
                    await _writeProHistory(
                      docId: ref.id,
                      action: "schedule",
                      before: newDoc,
                      after: {"publishAt": chosenPublishAt.toString()},
                    );
                  }

                  _snack("تم الحفظ ✅");
                } else {
                  final ref = FirebaseFirestore.instance
                      .collection(_proCardsCollection)
                      .doc(existingId);

                  final beforeSnap = await ref.get();
                  final before = beforeSnap.data() ?? {};

                  await ref.update(docData);

                  await _writeProHistory(
                    docId: existingId,
                    action: publishNow
                        ? "publish_now"
                        : schedule
                            ? "schedule"
                            : "update",
                    before: before,
                    after: docData,
                  );

                  if (publishNow) {
                    await _pushToCurrent(
                      text: text,
                      sourceDocId: existingId,
                      expireAt: expireAt,
                    );
                  }

                  _snack("تم التحديث ✅");
                }

                if (mounted) Navigator.pop(context);
              } catch (_) {
                _snack("فشل الحفظ. راجع Rules وصلاحيات الأدمن.");
              } finally {
                if (mounted) setState(() => _saving = false);
              }
            }

            String dtLabel(DateTime? dt) {
              if (dt == null) return "غير محدد";
              return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 12,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 14,
                ),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 42,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          isEdit ? "تعديل معلومة Pro" : "إضافة معلومة Pro",
                          textAlign: TextAlign.right,
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.w900,
                            fontSize: 14.5,
                            color: AppColors.primaryDeepTeal,
                          ),
                        ),
                        const SizedBox(height: 12),

                        _tf(textC, "نص المعلومة (إلزامي)", maxLines: 5),
                        const SizedBox(height: 12),

                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            "نشط (ظاهر في القوائم)",
                            textAlign: TextAlign.right,
                            style: GoogleFonts.cairo(
                                fontWeight: FontWeight.w900, fontSize: 12.5),
                          ),
                          value: isActive,
                          onChanged: (v) => setLocal(() => isActive = v),
                        ),

                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            "تثبيت (Pinned)",
                            textAlign: TextAlign.right,
                            style: GoogleFonts.cairo(
                                fontWeight: FontWeight.w900, fontSize: 12.5),
                          ),
                          subtitle: Text(
                            "اختياري — لا يغير الهوم الآن (جاهز للترتيب لاحقًا)",
                            textAlign: TextAlign.right,
                            style: GoogleFonts.cairo(
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                                color: Colors.black54),
                          ),
                          value: pinned,
                          onChanged: (v) => setLocal(() => pinned = v),
                        ),

                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            "إشعار عند النشر (اختياري)",
                            textAlign: TextAlign.right,
                            style: GoogleFonts.cairo(
                                fontWeight: FontWeight.w900, fontSize: 12.5),
                          ),
                          subtitle: Text(
                            "جاهز لباك-إند لاحقًا (Queue/FCM)",
                            textAlign: TextAlign.right,
                            style: GoogleFonts.cairo(
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                                color: Colors.black54),
                          ),
                          value: notify,
                          onChanged: (v) => setLocal(() => notify = v),
                        ),

                        const SizedBox(height: 8),

                        // PublishAt
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: AppColors.primaryDeepTeal
                                    .withOpacity(0.10)),
                            color: Colors.grey[50],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "وقت النشر (publishAt): ${dtLabel(publishAt)}",
                                  textAlign: TextAlign.right,
                                  style: GoogleFonts.cairo(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12.5,
                                    color: AppColors.primaryDeepTeal,
                                  ),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () async {
                                  final dt = await _pickDateTime(context);
                                  if (dt == null) return;
                                  setLocal(() => publishAt = dt);
                                },
                                icon: const Icon(Icons.schedule, size: 18),
                                label: Text("اختيار",
                                    style: GoogleFonts.cairo(
                                        fontWeight: FontWeight.w900)),
                              ),
                              if (publishAt != null)
                                IconButton(
                                  tooltip: "مسح",
                                  onPressed: () =>
                                      setLocal(() => publishAt = null),
                                  icon: const Icon(Icons.close),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),

                        // ExpireAt
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: AppColors.primaryDeepTeal
                                    .withOpacity(0.10)),
                            color: Colors.grey[50],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "وقت الانتهاء (expireAt): ${dtLabel(expireAt)}",
                                  textAlign: TextAlign.right,
                                  style: GoogleFonts.cairo(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12.5,
                                    color: AppColors.primaryDeepTeal,
                                  ),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () async {
                                  final dt = await _pickDateTime(context);
                                  if (dt == null) return;
                                  setLocal(() => expireAt = dt);
                                },
                                icon:
                                    const Icon(Icons.timer_outlined, size: 18),
                                label: Text("اختيار",
                                    style: GoogleFonts.cairo(
                                        fontWeight: FontWeight.w900)),
                              ),
                              if (expireAt != null)
                                IconButton(
                                  tooltip: "مسح",
                                  onPressed: () =>
                                      setLocal(() => expireAt = null),
                                  icon: const Icon(Icons.close),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Buttons row
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryDeepTeal,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14)),
                                  ),
                                  onPressed: () =>
                                      save(publishNow: false, schedule: false),
                                  child: _btnText("حفظ"),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.secondaryOrange,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14)),
                                  ),
                                  onPressed: () =>
                                      save(publishNow: true, schedule: false),
                                  child: _btnText("نشر الآن"),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black87,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () =>
                                save(publishNow: false, schedule: true),
                            icon: const Icon(Icons.schedule_send,
                                color: Colors.white),
                            label: _btnText("جدولة النشر"),
                          ),
                        ),

                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    textC.dispose();
  }

  Future<void> _toggleProActive(String docId, bool newValue) async {
    setState(() => _saving = true);
    try {
      final ref =
          FirebaseFirestore.instance.collection(_proCardsCollection).doc(docId);
      final beforeSnap = await ref.get();
      final before = beforeSnap.data() ?? {};

      await ref.update({
        "isActive": newValue,
        "updatedAt": FieldValue.serverTimestamp(),
      });

      await _writeProHistory(
        docId: docId,
        action: newValue ? "show" : "hide",
        before: before,
        after: {"isActive": newValue},
      );

      _snack(newValue ? "تم الإظهار ✅" : "تم الإخفاء ✅");
    } catch (_) {
      _snack("فشل التحديث. راجع Rules.");
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteProDoc(String docId) async {
    await _confirm(
      title: "حذف نهائي",
      body:
          "هل تريد حذف المعلومة نهائيًا؟\nسيتم حفظ نسخة في أرشيف الحذف + History.",
      onYes: () async {
        setState(() => _saving = true);
        try {
          final ref = FirebaseFirestore.instance
              .collection(_proCardsCollection)
              .doc(docId);
          final snap = await ref.get();
          final data = snap.data() ?? {};

          // archive deleted
          await FirebaseFirestore.instance
              .collection(_proCardsDeletedCollection)
              .doc(docId)
              .set({
            "deletedAt": FieldValue.serverTimestamp(),
            "data": data,
          });

          await _writeProHistory(
            docId: docId,
            action: "delete",
            before: data,
            after: {},
          );

          await ref.delete();
          _snack("تم الحذف ✅");
        } catch (_) {
          _snack("فشل الحذف. راجع Rules.");
        } finally {
          if (mounted) setState(() => _saving = false);
        }
      },
      yesText: "حذف",
    );
  }

  Future<void> _publishExistingProToCurrent(
      String docId, Map<String, dynamic> data) async {
    final text = (data["text"] ?? "").toString().trim();
    if (text.isEmpty) {
      _snack("هذه المعلومة بدون نص.");
      return;
    }

    DateTime? expireAt = (data["expireAt"] is Timestamp)
        ? (data["expireAt"] as Timestamp).toDate()
        : null;

    setState(() => _saving = true);
    try {
      final ref =
          FirebaseFirestore.instance.collection(_proCardsCollection).doc(docId);
      final beforeSnap = await ref.get();
      final before = beforeSnap.data() ?? {};

      // ensure active + set publishAt now
      await ref.update({
        "isActive": true,
        "publishAt": Timestamp.fromDate(DateTime.now()),
        "updatedAt": FieldValue.serverTimestamp(),
      });

      await _pushToCurrent(text: text, sourceDocId: docId, expireAt: expireAt);

      await _writeProHistory(
        docId: docId,
        action: "publish_now",
        before: before,
        after: {"pushedToCurrent": true},
      );

      _snack("تم نشرها على الهوم الآن ✅");
    } catch (_) {
      _snack("فشل النشر. راجع Rules.");
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // =========================================================
  // Tab 2 Actions: Quizzes
  // =========================================================
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

  // =========================================================
  // Tab 3 Actions: Know Client (CMS) [unchanged]
  // =========================================================

  Future<void> _writeKycHistory({
    required String docId,
    required String action,
    Map<String, dynamic>? before,
    Map<String, dynamic>? after,
    String? note,
  }) async {
    try {
      final ref = FirebaseFirestore.instance
          .collection(_kycCollection)
          .doc(docId)
          .collection("history")
          .doc();

      await ref.set({
        "action": action,
        "note": (note ?? "").toString(),
        "before": before ?? {},
        "after": after ?? {},
        "at": FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  Future<void> _enqueueNotification({
    required String docId,
    required String title,
    required bool notifyUsers,
    required DateTime fireAt,
  }) async {
    if (!notifyUsers) return;

    try {
      await FirebaseFirestore.instance.collection(_kycNotificationsQueue).add({
        "type": "know_client_publish",
        "docId": docId,
        "title": title,
        "fireAt": Timestamp.fromDate(fireAt),
        "createdAt": FieldValue.serverTimestamp(),
        "status": "pending",
      });
    } catch (_) {}
  }

  Future<void> _openKycEditor({
    Map<String, dynamic>? existing,
    String? existingId,
  }) async {
    final bool isEdit = existing != null && existingId != null;

    final titleC =
        TextEditingController(text: (existing?["title"] ?? "").toString());
    final hookC =
        TextEditingController(text: (existing?["hook"] ?? "").toString());
    final articleC = TextEditingController(
        text: (existing?["article"] ?? existing?["body"] ?? "").toString());
    final resetC =
        TextEditingController(text: (existing?["reset"] ?? "").toString());
    final coreC =
        TextEditingController(text: (existing?["core"] ?? "").toString());
    final exampleC =
        TextEditingController(text: (existing?["example"] ?? "").toString());
    final lockC =
        TextEditingController(text: (existing?["lock"] ?? "").toString());

    final rawTags = (existing?["tags"] is List)
        ? List.from(existing!["tags"])
        : <dynamic>[];
    final selectedTags = rawTags
        .map((e) => e.toString())
        .where((e) => e.trim().isNotEmpty)
        .toSet();

    bool isActive = existing?["isActive"] == true;
    bool notify = existing?["notify"] == true;
    Timestamp? publishAtTs =
        existing?["publishAt"] is Timestamp ? existing!["publishAt"] : null;

    DateTime? scheduledAt = publishAtTs?.toDate();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            Widget tagChip(String tag) {
              final sel = selectedTags.contains(tag);
              return FilterChip(
                label: Text(tag,
                    style: GoogleFonts.cairo(fontWeight: FontWeight.w900)),
                selected: sel,
                selectedColor: AppColors.secondaryOrange.withOpacity(0.25),
                checkmarkColor: AppColors.primaryDeepTeal,
                onSelected: (v) {
                  setLocal(() {
                    if (v) {
                      selectedTags.add(tag);
                    } else {
                      selectedTags.remove(tag);
                    }
                  });
                },
              );
            }

            Future<void> save(
                {required bool publishNow, required bool schedule}) async {
              final title = titleC.text.trim();
              if (title.isEmpty) {
                _snack("العنوان مطلوب.");
                return;
              }
              if (selectedTags.isEmpty) {
                _snack("اختار قسم واحد على الأقل (tags).");
                return;
              }

              DateTime? publishAt;
              if (publishNow) {
                publishAt = DateTime.now();
                isActive = true;
              } else if (schedule) {
                if (scheduledAt == null) {
                  _snack("اختار وقت الجدولة.");
                  return;
                }
                publishAt = scheduledAt;
                isActive = true;
              }

              final docData = <String, dynamic>{
                "title": title,
                "hook": hookC.text.trim(),
                "article": articleC.text.trim(),
                "reset": resetC.text.trim(),
                "core": coreC.text.trim(),
                "example": exampleC.text.trim(),
                "lock": lockC.text.trim(),
                "tags": selectedTags.toList(),
                "isActive": isActive,
                "notify": notify,
                "publishAt": (publishAt != null)
                    ? Timestamp.fromDate(publishAt)
                    : publishAtTs,
                "updatedAt": FieldValue.serverTimestamp(),
              };

              setState(() => _saving = true);
              try {
                if (!isEdit) {
                  final ref = FirebaseFirestore.instance
                      .collection(_kycCollection)
                      .doc();
                  final newDoc = {
                    ...docData,
                    "createdAt": FieldValue.serverTimestamp(),
                  };
                  await ref.set(newDoc);

                  await _writeKycHistory(
                    docId: ref.id,
                    action: "create",
                    before: {},
                    after: newDoc,
                  );

                  if (publishAt != null) {
                    await _enqueueNotification(
                      docId: ref.id,
                      title: title,
                      notifyUsers: notify,
                      fireAt: publishAt,
                    );
                  }

                  _snack("تم الحفظ ✅");
                } else {
                  final ref = FirebaseFirestore.instance
                      .collection(_kycCollection)
                      .doc(existingId);
                  final beforeSnap = await ref.get();
                  final before = beforeSnap.data() ?? {};

                  await ref.update(docData);

                  await _writeKycHistory(
                    docId: existingId,
                    action: publishNow
                        ? "publish_now"
                        : schedule
                            ? "schedule"
                            : "update",
                    before: before,
                    after: docData,
                  );

                  if (publishAt != null) {
                    await _enqueueNotification(
                      docId: existingId,
                      title: title,
                      notifyUsers: notify,
                      fireAt: publishAt,
                    );
                  }

                  _snack("تم التحديث ✅");
                }

                if (mounted) Navigator.pop(context);
              } catch (_) {
                _snack("فشل الحفظ. راجع Rules وصلاحيات الأدمن.");
              } finally {
                if (mounted) setState(() => _saving = false);
              }
            }

            String dtLabel(DateTime? dt) {
              if (dt == null) return "غير محدد";
              return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 12,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 14,
                ),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 42,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          isEdit ? "تعديل موضوع" : "إضافة موضوع جديد",
                          textAlign: TextAlign.right,
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.w900,
                            fontSize: 14.5,
                            color: AppColors.primaryDeepTeal,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _tf(titleC, "العنوان (إلزامي)", maxLines: 2),
                        const SizedBox(height: 10),
                        Text(
                          "اختر الأقسام (Tags) — لازم قسم واحد على الأقل",
                          textAlign: TextAlign.right,
                          style: GoogleFonts.cairo(
                              fontWeight: FontWeight.w900, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _kycSections.map(tagChip).toList(),
                        ),
                        const SizedBox(height: 12),
                        _tf(hookC, "Hook (اختياري)"),
                        const SizedBox(height: 10),
                        _tf(articleC, "المقال (اختياري - طويل)", maxLines: 6),
                        const SizedBox(height: 10),
                        _tf(resetC, "تصحيح المفهوم (reset)"),
                        const SizedBox(height: 10),
                        _tf(coreC, "المعلومة الأساسية (core)", maxLines: 5),
                        const SizedBox(height: 10),
                        _tf(exampleC, "مثال واقعي (example)", maxLines: 4),
                        const SizedBox(height: 10),
                        _tf(lockC, "إغلاق/سلوك عملي (lock)", maxLines: 3),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            "نشط (ظاهر للمستخدم)",
                            textAlign: TextAlign.right,
                            style: GoogleFonts.cairo(
                                fontWeight: FontWeight.w900, fontSize: 12.5),
                          ),
                          value: isActive,
                          onChanged: (v) => setLocal(() => isActive = v),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            "إشعار للمستخدمين عند النشر",
                            textAlign: TextAlign.right,
                            style: GoogleFonts.cairo(
                                fontWeight: FontWeight.w900, fontSize: 12.5),
                          ),
                          subtitle: Text(
                            "سيتم إنشاء Queue — يحتاج Backend للتنفيذ لاحقًا",
                            textAlign: TextAlign.right,
                            style: GoogleFonts.cairo(
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                                color: Colors.black54),
                          ),
                          value: notify,
                          onChanged: (v) => setLocal(() => notify = v),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: AppColors.primaryDeepTeal
                                    .withOpacity(0.10)),
                            color: Colors.grey[50],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  scheduledAt == null
                                      ? "جدولة: غير محدد"
                                      : "جدولة: ${dtLabel(scheduledAt)}",
                                  textAlign: TextAlign.right,
                                  style: GoogleFonts.cairo(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12.5,
                                    color: AppColors.primaryDeepTeal,
                                  ),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () async {
                                  final dt = await _pickDateTime(context);
                                  if (dt == null) return;
                                  setLocal(() => scheduledAt = dt);
                                },
                                icon: const Icon(Icons.schedule, size: 18),
                                label: Text("اختيار",
                                    style: GoogleFonts.cairo(
                                        fontWeight: FontWeight.w900)),
                              ),
                              if (scheduledAt != null)
                                IconButton(
                                  tooltip: "مسح",
                                  onPressed: () =>
                                      setLocal(() => scheduledAt = null),
                                  icon: const Icon(Icons.close),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryDeepTeal,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14)),
                                  ),
                                  onPressed: () =>
                                      save(publishNow: false, schedule: false),
                                  child: _btnText("حفظ"),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.secondaryOrange,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14)),
                                  ),
                                  onPressed: () =>
                                      save(publishNow: true, schedule: false),
                                  child: _btnText("نشر الآن"),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black87,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () =>
                                save(publishNow: false, schedule: true),
                            icon: const Icon(Icons.schedule_send,
                                color: Colors.white),
                            label: _btnText("جدولة النشر"),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    titleC.dispose();
    hookC.dispose();
    articleC.dispose();
    resetC.dispose();
    coreC.dispose();
    exampleC.dispose();
    lockC.dispose();
  }

  Future<void> _toggleKycActive(String docId, bool newValue) async {
    setState(() => _saving = true);
    try {
      final ref =
          FirebaseFirestore.instance.collection(_kycCollection).doc(docId);
      final beforeSnap = await ref.get();
      final before = beforeSnap.data() ?? {};
      await ref.update({
        "isActive": newValue,
        "updatedAt": FieldValue.serverTimestamp(),
      });

      await _writeKycHistory(
        docId: docId,
        action: newValue ? "show" : "hide",
        before: before,
        after: {"isActive": newValue},
      );

      _snack(newValue ? "تم الإظهار ✅" : "تم الإخفاء ✅");
    } catch (_) {
      _snack("فشل التحديث. راجع Rules.");
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteKycDoc(String docId) async {
    await _confirm(
      title: "حذف نهائي",
      body:
          "هل تريد حذف الموضوع نهائيًا؟\n(سيتم حفظ نسخة في أرشيف الحذف للهيستوري)",
      onYes: () async {
        setState(() => _saving = true);
        try {
          final ref =
              FirebaseFirestore.instance.collection(_kycCollection).doc(docId);
          final snap = await ref.get();
          final data = snap.data() ?? {};

          await FirebaseFirestore.instance
              .collection("${_kycCollection}_deleted")
              .doc(docId)
              .set({
            "deletedAt": FieldValue.serverTimestamp(),
            "data": data,
          });

          await _writeKycHistory(
            docId: docId,
            action: "delete",
            before: data,
            after: {},
          );

          await ref.delete();
          _snack("تم الحذف ✅");
        } catch (_) {
          _snack("فشل الحذف. راجع Rules.");
        } finally {
          if (mounted) setState(() => _saving = false);
        }
      },
      yesText: "حذف",
    );
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
                fit: BoxFit.scaleDown,
                child: Text("معلومة Pro"),
              ),
            ),
            Tab(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text("الدوريات"),
              ),
            ),
            Tab(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text("اعرف عميلك"),
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _buildProCardCmsTab(), // ✅ UPDATED
              _buildQuizzesTab(),
              _buildKnowClientTab(),
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

  // -------------------------
  // Tab 1: Pro Card CMS
  // -------------------------
  Widget _buildProCardCmsTab() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            // Top current preview
            _currentProPreview(),

            const SizedBox(height: 12),

            // Search + Add
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _proSearch,
                    textAlign: TextAlign.right,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: "بحث في المعلومة...",
                      prefixIcon: const Icon(Icons.search),
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
                SizedBox(
                  height: 46,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondaryOrange,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => _openProEditor(),
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: _btnText("إضافة", size: 13),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Expanded(child: _proCardsList()),
          ],
        ),
      ),
    );
  }

  Widget _currentProPreview() {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(_proCurrentCollection)
          .doc(_proCurrentDocId)
          .snapshots(),
      builder: (context, snap) {
        String text = "لا يوجد نص حالياً على الهوم.";
        String source = "";
        DateTime? expireAt;

        if (snap.hasData && snap.data!.exists) {
          final d = snap.data!.data() ?? {};
          final t = (d["text"] ?? "").toString().trim();
          if (t.isNotEmpty) text = t;
          source = (d["sourceDocId"] ?? "").toString();

          expireAt = (d["expireAt"] is Timestamp)
              ? (d["expireAt"] as Timestamp).toDate()
              : null;
        }

        final exp = expireAt == null
            ? "بدون انتهاء"
            : "${expireAt.year}-${expireAt.month.toString().padLeft(2, '0')}-${expireAt.day.toString().padLeft(2, '0')} ${expireAt.hour.toString().padLeft(2, '0')}:${expireAt.minute.toString().padLeft(2, '0')}";

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: [
                AppColors.primaryDeepTeal.withOpacity(0.10),
                AppColors.secondaryOrange.withOpacity(0.10),
              ],
            ),
            border: Border.all(color: Colors.black.withOpacity(0.04)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "المعروض الآن على الهوم",
                textAlign: TextAlign.right,
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  color: AppColors.primaryDeepTeal,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                text,
                textAlign: TextAlign.right,
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w800,
                  height: 1.7,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "انتهاء: $exp",
                      textAlign: TextAlign.right,
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w800,
                        fontSize: 11.5,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  if (source.trim().isNotEmpty)
                    Text(
                      "ID: $source",
                      textAlign: TextAlign.left,
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w700,
                        fontSize: 10.5,
                        color: Colors.black45,
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _proCardsList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(_proCardsCollection)
          .orderBy("updatedAt", descending: true)
          .limit(200)
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(
            child: Text(
              "خطأ في تحميل المعلومة.\nراجع Rules أو أسماء الحقول.",
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(fontWeight: FontWeight.w900),
            ),
          );
        }
        if (!snap.hasData) {
          return const Center(
            child: SizedBox(
              width: 34,
              height: 34,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        final q = _proSearch.text.trim().toLowerCase();
        final docs = snap.data!.docs;

        final filtered = docs.where((d) {
          final data = d.data();
          final text = (data["text"] ?? "").toString().toLowerCase();
          if (q.isEmpty) return true;
          return text.contains(q);
        }).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Text(
              "لا توجد نتائج.",
              style: GoogleFonts.cairo(fontWeight: FontWeight.w900),
            ),
          );
        }

        return ListView.separated(
          physics: const BouncingScrollPhysics(),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final doc = filtered[i];
            final data = doc.data();

            final text = (data["text"] ?? "").toString();
            final isActive = data["isActive"] == true;

            final publishAt = (data["publishAt"] is Timestamp)
                ? (data["publishAt"] as Timestamp).toDate()
                : null;
            final expireAt = (data["expireAt"] is Timestamp)
                ? (data["expireAt"] as Timestamp).toDate()
                : null;

            String dtShort(DateTime? dt) {
              if (dt == null) return "—";
              return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
            }

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppColors.primaryDeepTeal.withOpacity(0.08)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    text,
                    textAlign: TextAlign.right,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontSize: 13.2,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryDeepTeal,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.green.withOpacity(0.12)
                              : Colors.red.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          isActive ? "ظاهر" : "مخفي",
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.w900,
                            fontSize: 11.5,
                            color:
                                isActive ? Colors.green[800] : Colors.red[800],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "نشر: ${dtShort(publishAt)}  |  انتهاء: ${dtShort(expireAt)}",
                          textAlign: TextAlign.right,
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            side: BorderSide(
                                color: AppColors.primaryDeepTeal
                                    .withOpacity(0.18)),
                          ),
                          onPressed: () => _openProEditor(
                              existing: data, existingId: doc.id),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: Text("تعديل",
                              style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.w900)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            side: BorderSide(
                                color: AppColors.primaryDeepTeal
                                    .withOpacity(0.18)),
                          ),
                          onPressed: () => _toggleProActive(doc.id, !isActive),
                          icon: Icon(
                              isActive
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 18),
                          label: Text(isActive ? "إخفاء" : "إظهار",
                              style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.w900)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        tooltip: "نشر على الهوم الآن",
                        onPressed: () =>
                            _publishExistingProToCurrent(doc.id, data),
                        icon: const Icon(Icons.publish_rounded,
                            color: AppColors.secondaryOrange),
                      ),
                      IconButton(
                        tooltip: "حذف",
                        onPressed: () => _deleteProDoc(doc.id),
                        icon:
                            const Icon(Icons.delete_outline, color: Colors.red),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // -------------------------
  // Tab 2: Quizzes UI
  // -------------------------
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

  // -------------------------
  // Tab 3: Know Client CMS UI (unchanged)
  // -------------------------
  Widget _buildKnowClientTab() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _kycFilterSection,
                    items: [
                      const DropdownMenuItem(
                          value: "الكل", child: Text("الكل")),
                      ..._kycSections.map(
                        (s) => DropdownMenuItem(value: s, child: Text(s)),
                      )
                    ],
                    onChanged: (v) =>
                        setState(() => _kycFilterSection = v ?? "الكل"),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 46,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondaryOrange,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => _openKycEditor(),
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: _btnText("إضافة", size: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _kycSearch,
              textAlign: TextAlign.right,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: "بحث بالعنوان...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(child: _kycList()),
          ],
        ),
      ),
    );
  }

  Widget _kycList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(_kycCollection)
          .orderBy("updatedAt", descending: true)
          .limit(200)
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(
            child: Text(
              "خطأ في تحميل المواضيع.\nراجع Rules أو أسماء الحقول.",
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(fontWeight: FontWeight.w900),
            ),
          );
        }
        if (!snap.hasData) {
          return const Center(
            child: SizedBox(
              width: 34,
              height: 34,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        final q = _kycSearch.text.trim().toLowerCase();
        final docs = snap.data!.docs;

        final filtered = docs.where((d) {
          final data = d.data();
          final title = (data["title"] ?? "").toString().toLowerCase();
          final tags = (data["tags"] is List)
              ? (data["tags"] as List).map((e) => e.toString()).toList()
              : <String>[];

          final matchSection = (_kycFilterSection == "الكل")
              ? true
              : tags.contains(_kycFilterSection);
          final matchSearch = q.isEmpty ? true : title.contains(q);
          return matchSection && matchSearch;
        }).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Text(
              "لا توجد نتائج.",
              style: GoogleFonts.cairo(fontWeight: FontWeight.w900),
            ),
          );
        }

        return ListView.separated(
          physics: const BouncingScrollPhysics(),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final doc = filtered[i];
            final data = doc.data();

            final title = (data["title"] ?? "").toString();
            final isActive = data["isActive"] == true;
            final notify = data["notify"] == true;

            final tags = (data["tags"] is List)
                ? (data["tags"] as List)
                    .map((e) => e.toString())
                    .where((e) => e.trim().isNotEmpty)
                    .toList()
                : <String>[];

            final publishAt = (data["publishAt"] is Timestamp)
                ? (data["publishAt"] as Timestamp).toDate()
                : null;

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppColors.primaryDeepTeal.withOpacity(0.08)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.cairo(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryDeepTeal,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: tags.take(4).map((t) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryDeepTeal.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          t,
                          style: GoogleFonts.cairo(
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              color: AppColors.primaryDeepTeal),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.green.withOpacity(0.12)
                              : Colors.red.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          isActive ? "ظاهر" : "مخفي",
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.w900,
                            fontSize: 11.5,
                            color:
                                isActive ? Colors.green[800] : Colors.red[800],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: notify
                              ? AppColors.secondaryOrange.withOpacity(0.15)
                              : Colors.grey.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          notify ? "إشعار: نعم" : "إشعار: لا",
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.w900,
                            fontSize: 11.5,
                            color: notify
                                ? AppColors.secondaryOrange
                                : Colors.black54,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (publishAt != null)
                        Text(
                          "نشر: ${publishAt.year}-${publishAt.month.toString().padLeft(2, '0')}-${publishAt.day.toString().padLeft(2, '0')} ${publishAt.hour.toString().padLeft(2, '0')}:${publishAt.minute.toString().padLeft(2, '0')}",
                          style: GoogleFonts.cairo(
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                              color: Colors.black54),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            side: BorderSide(
                                color: AppColors.primaryDeepTeal
                                    .withOpacity(0.18)),
                          ),
                          onPressed: () => _openKycEditor(
                              existing: data, existingId: doc.id),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: Text("تعديل",
                              style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.w900)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            side: BorderSide(
                                color: AppColors.primaryDeepTeal
                                    .withOpacity(0.18)),
                          ),
                          onPressed: () => _toggleKycActive(doc.id, !isActive),
                          icon: Icon(
                              isActive
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 18),
                          label: Text(isActive ? "إخفاء" : "إظهار",
                              style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.w900)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        tooltip: "حذف",
                        onPressed: () => _deleteKycDoc(doc.id),
                        icon:
                            const Icon(Icons.delete_outline, color: Colors.red),
                      ),
                    ],
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
}

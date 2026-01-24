// PATH: lib/presentation/screens/fact_articles_screen.dart
// STATUS: Full File – Stable Navigation + Share + Favorites + Last seen
//         + ✅ Admin Tools (role-based)
//         + ✅ Improved Admin UI (compact chips, readable text)
//         + ✅ Featured control: isFeatured + featuredOrder + featuredUntil
//         + ✅ Section control: sectionKey + orderInSection (with dropdown + arrows)
//         + ✅ FIX: bottom favorite now clickable

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/firestore_paths.dart';
import '../../features/pro_insight/repositories/pro_insight_repository.dart';

class FactArticlesScreen extends StatefulWidget {
  final String title; // ✅ Protocol: title only
  const FactArticlesScreen({super.key, required this.title});

  @override
  State<FactArticlesScreen> createState() => _FactArticlesScreenState();
}

class _FactArticlesScreenState extends State<FactArticlesScreen> {
  static const String _collectionName = FirestorePaths.proInsight;

  static const String _prefsFavKey = 'pro_insight_fav_titles';
  static const String _prefsLastSeenKey = 'pro_insight_last_seen_title';

  final ProInsightRepository _proInsightRepo = ProInsightRepository();

  bool _isFavorite = false;

  // ✅ Admin state (role from users/{uid}.role)
  String _role = 'user'; // user / moderator / admin
  bool get _canAdmin => _role == 'admin' || _role == 'moderator';

  // Navigation (local sort)
  List<_NavItem> _nav = [];
  int _currentIndex = -1;

  // Article payload
  bool _loadingArticle = true;
  String _hook = '';
  String _reset = '';
  String _core = '';
  String _example = '';
  String _lock = '';
  bool _articleExists = true;

  // ✅ keep docId (needed for admin actions)
  String _docId = '';

  // ✅ Control fields (stored in Firestore)
  bool _isActive = true;
  bool _isFeatured = false; // مختارات اليوم
  int _featuredOrder = 0; // ترتيب داخل مختارات اليوم
  DateTime? _featuredUntil; // انتهاء التثبيت (اختياري)
  String _sectionKey = ''; // داخل "المعلومة بتفرق"
  int _orderInSection = 0; // ترتيب داخل القسم
  List<String> _tags = []; // ✅ Tags (read-only here, not modified by admin)

  // ✅ Known section keys with Arabic labels
  static const Map<String, String> _sectionLabels = {
    'start': 'البداية الصح',
    'language': 'لغة العقارات',
    'market_system': 'سيستم السوق',
    'company_system': 'سيستم الشركات',
    'projects': 'دراسة المشاريع',
    'contracts': 'التعاقدات والإجراءات',
    'broker': 'البروكر',
  };
  static List<String> get _sectionKeys => _sectionLabels.keys.toList();

  String get _rawTitle => widget.title;
  String get _normTitle => _norm(widget.title);

  bool get _hasPrev => _currentIndex > 0;
  bool get _hasNext => _currentIndex >= 0 && _currentIndex < _nav.length - 1;

  @override
  void initState() {
    super.initState();
    _markLastSeen();
    _loadFavoriteState();
    _loadRole(); // ✅ admin tools
    _loadNavOrderLocal();
    _loadArticleOnceWithFallback();
  }

  // =========================
  // Helpers
  // =========================
  String _norm(String s) => s.replaceAll(RegExp(r'\s+'), ' ').trim();

  String _fmtDt(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return "$y-$m-$d  $hh:$mm";
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // =========================
  // Role (Admin / Moderator)
  // =========================
  Future<void> _loadRole() async {
    try {
      final u = FirebaseAuth.instance.currentUser;
      if (u == null) return;

      final snap =
          await FirebaseFirestore.instance.collection(FirestorePaths.users).doc(u.uid).get();
      final data = snap.data() ?? {};
      final r = (data['role'] ?? 'user').toString().trim().toLowerCase();

      if (!mounted) return;
      setState(() => _role = r.isEmpty ? 'user' : r);
    } catch (_) {}
  }

  // =========================
  // Prefs
  // =========================
  Future<void> _markLastSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsLastSeenKey, _normTitle);
    } catch (_) {}
  }

  Future<void> _loadFavoriteState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fav = prefs.getStringList(_prefsFavKey) ?? <String>[];
      if (!mounted) return;
      setState(() => _isFavorite = fav.contains(_normTitle));
    } catch (_) {}
  }

  Future<void> _toggleFavorite() async {
    if (_normTitle.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final fav = (prefs.getStringList(_prefsFavKey) ?? <String>[]).toList();

      if (fav.contains(_normTitle)) {
        fav.remove(_normTitle);
        if (!mounted) return;
        setState(() => _isFavorite = false);
      } else {
        fav.add(_normTitle);
        if (!mounted) return;
        setState(() => _isFavorite = true);
      }

      await prefs.setStringList(_prefsFavKey, fav);
    } catch (_) {}
  }

  // =========================
  // Firestore load (stable)
  // =========================
  Future<void> _loadArticleOnceWithFallback() async {
    setState(() {
      _loadingArticle = true;
      _articleExists = true;
      _docId = '';
    });

    try {
      // 1) direct by raw title
      final direct = await FirebaseFirestore.instance
          .collection(_collectionName)
          .where('title', isEqualTo: _rawTitle.trim())
          .limit(1)
          .get();

      if (direct.docs.isNotEmpty) {
        final doc = direct.docs.first;
        _docId = doc.id;
        _applyArticleFromMap(doc.data());
        return;
      }

      // 2) fallback: scan active and match normalized title
      final snap = await FirebaseFirestore.instance
          .collection(_collectionName)
          .where('isActive', isEqualTo: true)
          .limit(5000)
          .get();

      QueryDocumentSnapshot<Map<String, dynamic>>? found;

      for (final d in snap.docs) {
        final t = _norm((d.data()['title'] ?? '').toString());
        if (t == _normTitle) {
          found = d;
          break;
        }
      }

      if (found == null) {
        if (!mounted) return;
        setState(() {
          _articleExists = false;
          _loadingArticle = false;
        });
        return;
      }

      _docId = found.id;
      _applyArticleFromMap(found.data());
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _articleExists = false;
        _loadingArticle = false;
      });
    }
  }

  void _applyArticleFromMap(Map<String, dynamic> data) {
    if (!mounted) return;

    final isActive = (data['isActive'] != false);
    final isFeatured = (data['isFeatured'] == true);

    final featuredOrderRaw = data['featuredOrder'];
    final featuredOrder = (featuredOrderRaw is int)
        ? featuredOrderRaw
        : int.tryParse((featuredOrderRaw ?? '0').toString()) ?? 0;

    DateTime? featuredUntil;
    final fu = data['featuredUntil'];
    if (fu is Timestamp) featuredUntil = fu.toDate();

    final sectionKey = (data['sectionKey'] ?? '').toString();

    final orderRaw = data['orderInSection'];
    final orderInSection = (orderRaw is int)
        ? orderRaw
        : int.tryParse((orderRaw ?? '0').toString()) ?? 0;

    // ✅ Read tags (for display only, not modified by admin tools)
    List<String> tags = [];
    final tagsRaw = data['tags'];
    if (tagsRaw is List) {
      tags = tagsRaw.map((e) => e.toString().trim()).where((t) => t.isNotEmpty).toList();
    }

    setState(() {
      _hook = (data['hook'] ?? '').toString();
      _reset = (data['reset'] ?? '').toString();
      _core = (data['core'] ?? '').toString();
      _example = (data['example'] ?? '').toString();
      _lock = (data['lock'] ?? '').toString();

      _isActive = isActive;
      _isFeatured = isFeatured;
      _featuredOrder = featuredOrder;
      _featuredUntil = featuredUntil;
      _sectionKey = sectionKey;
      _orderInSection = orderInSection;
      _tags = tags;

      _loadingArticle = false;
      _articleExists = true;
    });
  }

  Future<void> _loadNavOrderLocal() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection(_collectionName)
          .where('isActive', isEqualTo: true)
          .limit(5000)
          .get();

      final list = <_NavItem>[];
      for (final d in snap.docs) {
        final data = d.data();
        final title = _norm((data['title'] ?? '').toString());
        if (title.isEmpty) continue;

        int createdAtMs = 0;
        final ts = data['createdAt'];
        if (ts is Timestamp) createdAtMs = ts.millisecondsSinceEpoch;

        list.add(_NavItem(
          titleNorm: title,
          titleRaw: (data['title'] ?? '').toString(),
          createdAtMs: createdAtMs,
        ));
      }

      list.sort((a, b) => b.createdAtMs.compareTo(a.createdAtMs));
      final idx = list.indexWhere((e) => e.titleNorm == _normTitle);

      if (!mounted) return;
      setState(() {
        _nav = list;
        _currentIndex = idx;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _nav = [];
        _currentIndex = -1;
      });
    }
  }

  Future<void> _goToTitleRaw(String titleRaw) async {
    if (!mounted) return;
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => FactArticlesScreen(title: titleRaw),
      ),
    );
  }

  void _shareTopic() {
    final title = _normTitle;
    final h = _hook.trim().isEmpty ? "موضوع من L Pro" : _hook.trim();
    final shareText = "$title\n\n$h\n\n#LPro #المعلومة_بتفرق";
    Share.share(shareText);
  }

  // =========================
  // ✅ Admin Tools
  // =========================
  DocumentReference<Map<String, dynamic>> get _docRef =>
      FirebaseFirestore.instance.collection(_collectionName).doc(_docId);

  Future<DateTime?> _pickDateTime({DateTime? initial}) async {
    final now = DateTime.now();
    final init = initial ?? now;

    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 3),
      initialDate: DateTime(init.year, init.month, init.day),
    );
    if (date == null) return null;
    if (!mounted) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(init),
    );
    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("حذف الموضوع", textAlign: TextAlign.right),
        content: const Text(
          "هل تريد حذف هذا الموضوع نهائيًا؟",
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("إلغاء"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("حذف"),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      if (_docId.isEmpty) {
        _snack("لا يوجد docId للموضوع.");
        return;
      }

      await _proInsightRepo.delete(_docId);
      if (!mounted) return;
      _snack("تم الحذف ✅");
      Navigator.pop(context);
    } catch (_) {
      _snack("فشل الحذف. راجع Rules.");
    }
  }

  Future<void> _toggleActive(bool value) async {
    try {
      if (_docId.isEmpty) {
        _snack("لا يوجد docId للموضوع.");
        return;
      }

      await _proInsightRepo.update(_docId, {
        'isActive': value,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      setState(() => _isActive = value);

      _snack(value ? "تم الإظهار ✅" : "تم الإخفاء ✅");
    } catch (_) {
      _snack("فشل التحديث. راجع Rules.");
    }
  }

  Future<void> _publishNow() async {
    try {
      if (_docId.isEmpty) {
        _snack("لا يوجد docId للموضوع.");
        return;
      }

      await _proInsightRepo.update(_docId, {
        'isActive': true,
        'publishAt': DateTime.now(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      setState(() => _isActive = true);

      _snack("تم النشر الآن ✅");
    } catch (_) {
      _snack("فشل النشر. راجع Rules.");
    }
  }

  Future<void> _schedulePublishAt() async {
    final dt = await _pickDateTime(
      initial: DateTime.now().add(const Duration(minutes: 10)),
    );
    if (dt == null) return;

    try {
      if (_docId.isEmpty) {
        _snack("لا يوجد docId للموضوع.");
        return;
      }

      await _proInsightRepo.update(_docId, {
        'publishAt': dt,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _snack("تمت جدولة وقت النشر ✅");
    } catch (_) {
      _snack("فشل الجدولة. راجع Rules.");
    }
  }

  // ✅ Featured + Ordering + Section control (compact + no red screen)
  Future<void> _openFeaturedControl() async {
    if (_docId.isEmpty) {
      _snack("لا يوجد docId للموضوع.");
      return;
    }

    bool isFeaturedLocal = _isFeatured;
    int featuredOrderLocal = _featuredOrder;
    DateTime? untilLocal = _featuredUntil;

    String sectionKeyLocal = _sectionKey.isEmpty
        ? (_sectionKeys.isNotEmpty ? _sectionKeys.first : '')
        : _sectionKey;

    // لو sectionKey غير موجود في القائمة (لسبب ما)، نخليه موجود كـ custom
    final sectionOptions = <String>{
      ..._sectionKeys,
      if (_sectionKey.isNotEmpty) _sectionKey,
    }.toList();

    int orderInSectionLocal = _orderInSection;

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
            Widget stepperRow({
              required String label,
              required int value,
              required VoidCallback onDown,
              required VoidCallback onUp,
              String? hint,
            }) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        hint == null
                            ? "$label: $value"
                            : "$label: $value\n$hint",
                        textAlign: TextAlign.right,
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.w900,
                          fontSize: 12.5,
                          height: 1.4,
                          color: AppColors.primaryDeepTeal,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: "تقليل",
                      onPressed: onDown,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    ),
                    IconButton(
                      tooltip: "زيادة",
                      onPressed: onUp,
                      icon: const Icon(Icons.keyboard_arrow_up_rounded),
                    ),
                  ],
                ),
              );
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
                          "تحكم التثبيت والترتيب",
                          textAlign: TextAlign.right,
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.w900,
                            fontSize: 14.5,
                            color: AppColors.primaryDeepTeal,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Featured toggle
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "مختارات اليوم (Featured)",
                                  textAlign: TextAlign.right,
                                  style: GoogleFonts.cairo(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12.8,
                                    color: AppColors.primaryDeepTeal,
                                  ),
                                ),
                              ),
                              Switch(
                                value: isFeaturedLocal,
                                onChanged: (v) =>
                                    setLocal(() => isFeaturedLocal = v),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Featured order stepper
                        stepperRow(
                          label: "ترتيب داخل المختارات",
                          value: featuredOrderLocal,
                          hint: "استخدم الأسهم ↑ ↓ بدل كتابة رقم",
                          onDown: () => setLocal(() {
                            if (featuredOrderLocal > 0) featuredOrderLocal--;
                          }),
                          onUp: () => setLocal(() => featuredOrderLocal++),
                        ),
                        const SizedBox(height: 10),

                        // Featured until
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  untilLocal == null
                                      ? "انتهاء التثبيت: غير محدد (اختياري)"
                                      : "انتهاء التثبيت: ${_fmtDt(untilLocal!)}",
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
                                  final picked = await _pickDateTime(
                                    initial: untilLocal ??
                                        DateTime.now()
                                            .add(const Duration(days: 1)),
                                  );
                                  if (picked == null) return;
                                  setLocal(() => untilLocal = picked);
                                },
                                icon:
                                    const Icon(Icons.timer_outlined, size: 18),
                                label: Text(
                                  "تحديد",
                                  style: GoogleFonts.cairo(
                                      fontWeight: FontWeight.w900),
                                ),
                              ),
                              if (untilLocal != null)
                                IconButton(
                                  tooltip: "مسح",
                                  onPressed: () =>
                                      setLocal(() => untilLocal = null),
                                  icon: const Icon(Icons.close_rounded),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),
                        Text(
                          "نقل/ترتيب داخل الأقسام",
                          textAlign: TextAlign.right,
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.w900,
                            fontSize: 12.5,
                            color: AppColors.secondaryOrange,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // section dropdown with Arabic labels
                        DropdownButtonFormField<String>(
                          value: sectionOptions.contains(sectionKeyLocal)
                              ? sectionKeyLocal
                              : null,
                          items: sectionOptions
                              .map((k) => DropdownMenuItem(
                                    value: k,
                                    child: Text(
                                      _sectionLabels[k] ?? k,
                                      style: GoogleFonts.cairo(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13),
                                    ),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setLocal(() => sectionKeyLocal = v ?? ''),
                          decoration: InputDecoration(
                            hintText: "اختر القسم",
                            hintStyle: GoogleFonts.cairo(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // orderInSection stepper
                        stepperRow(
                          label: "ترتيب داخل القسم",
                          value: orderInSectionLocal,
                          hint: "استخدم الأسهم ↑ ↓ لترتيبه داخل نفس القسم",
                          onDown: () => setLocal(() {
                            if (orderInSectionLocal > 0) orderInSectionLocal--;
                          }),
                          onUp: () => setLocal(() => orderInSectionLocal++),
                        ),

                        const SizedBox(height: 14),
                        // ✅ Save button: not full-width, clear font, height 46
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 46,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.secondaryOrange,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 32, vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: () async {
                                  final nav = Navigator.of(context);
                                  try {
                                    // ✅ Only update sectionKey/orderInSection, DO NOT touch tags
                                    await _proInsightRepo.update(_docId, {
                                      'isFeatured': isFeaturedLocal,
                                      'featuredOrder': featuredOrderLocal,
                                      'featuredUntil': untilLocal == null
                                          ? FieldValue.delete()
                                          : untilLocal,
                                      'sectionKey': sectionKeyLocal.trim(),
                                      'orderInSection': orderInSectionLocal,
                                      'updatedAt': FieldValue.serverTimestamp(),
                                    });

                                    if (!mounted) return;
                                    setState(() {
                                      _isFeatured = isFeaturedLocal;
                                      _featuredOrder = featuredOrderLocal;
                                      _featuredUntil = untilLocal;
                                      _sectionKey = sectionKeyLocal.trim();
                                      _orderInSection = orderInSectionLocal;
                                    });

                                    nav.pop();
                                    _snack("تم حفظ التحكم ✅");
                                  } catch (_) {
                                    _snack("فشل الحفظ. راجع Rules.");
                                  }
                                },
                                child: Text(
                                  "حفظ التحكم",
                                  style: GoogleFonts.cairo(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
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
  }

  Future<void> _openEditor() async {
    if (_docId.isEmpty) {
      _snack("لا يوجد docId للموضوع.");
      return;
    }

    final titleC = TextEditingController(text: _rawTitle);
    final hookC = TextEditingController(text: _hook);
    final resetC = TextEditingController(text: _reset);
    final coreC = TextEditingController(text: _core);
    final exampleC = TextEditingController(text: _example);
    final lockC = TextEditingController(text: _lock);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) {
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
                      "تعديل الموضوع",
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
                    _tf(hookC, "Hook", maxLines: 3),
                    const SizedBox(height: 10),
                    _tf(resetC, "تصحيح المفهوم (reset)", maxLines: 5),
                    const SizedBox(height: 10),
                    _tf(coreC, "المعلومة الأساسية (core)", maxLines: 6),
                    const SizedBox(height: 10),
                    _tf(exampleC, "مثال واقعي (example)", maxLines: 5),
                    const SizedBox(height: 10),
                    _tf(lockC, "إغلاق/سلوك عملي (lock)", maxLines: 4),
                    const SizedBox(height: 12),
                    // ✅ Save button: not full-width, clear font, height 46
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 46,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondaryOrange,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () async {
                              final t = titleC.text.trim();
                              if (t.isEmpty) {
                                _snack("العنوان مطلوب.");
                                return;
                              }

                              try {
                                await _proInsightRepo.update(_docId, {
                                  'title': t,
                                  'hook': hookC.text.trim(),
                                  'reset': resetC.text.trim(),
                                  'core': coreC.text.trim(),
                                  'example': exampleC.text.trim(),
                                  'lock': lockC.text.trim(),
                                  'updatedAt': FieldValue.serverTimestamp(),
                                });

                                if (!mounted) return;
                                setState(() {
                                  _hook = hookC.text.trim();
                                  _reset = resetC.text.trim();
                                  _core = coreC.text.trim();
                                  _example = exampleC.text.trim();
                                  _lock = lockC.text.trim();
                                });

                                Navigator.pop(context);

                                if (t != widget.title.trim()) {
                                  if (!mounted) return;
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          FactArticlesScreen(title: t),
                                    ),
                                  );
                                } else {
                                  _snack("تم التحديث ✅");
                                }
                              } catch (_) {
                                _snack("فشل التحديث. راجع Rules.");
                              }
                            },
                            child: Text(
                              "حفظ التعديل",
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
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

    titleC.dispose();
    hookC.dispose();
    resetC.dispose();
    coreC.dispose();
    exampleC.dispose();
    lockC.dispose();
  }

  void _openAdminToolsSheet() {
    if (!_canAdmin) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) {
        Widget chip({
          required IconData icon,
          required String text,
          required VoidCallback onTap,
          required Color color,
        }) {
          return ActionChip(
            onPressed: onTap,
            avatar: Icon(icon, size: 18, color: color),
            label: Text(
              text,
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.w900,
                fontSize: 12.5,
                color: color,
              ),
            ),
            backgroundColor: color.withValues(alpha: 0.08),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          );
        }

        return SafeArea(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "أدوات الأدمن",
                    textAlign: TextAlign.right,
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w900,
                      fontSize: 14.5,
                      color: AppColors.primaryDeepTeal,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      chip(
                        icon: Icons.star_outline_rounded,
                        text: "تثبيت/ترتيب/نقل",
                        color: AppColors.secondaryOrange,
                        onTap: () {
                          Navigator.pop(context);
                          _openFeaturedControl();
                        },
                      ),
                      chip(
                        icon: Icons.edit_outlined,
                        text: "تعديل",
                        color: AppColors.primaryDeepTeal,
                        onTap: () {
                          Navigator.pop(context);
                          _openEditor();
                        },
                      ),
                      chip(
                        icon: _isActive
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        text: _isActive ? "إخفاء" : "إظهار",
                        color: _isActive ? Colors.redAccent : Colors.green,
                        onTap: () {
                          Navigator.pop(context);
                          _toggleActive(!_isActive);
                        },
                      ),
                      chip(
                        icon: Icons.publish_rounded,
                        text: "نشر الآن",
                        color: AppColors.secondaryOrange,
                        onTap: () {
                          Navigator.pop(context);
                          _publishNow();
                        },
                      ),
                      chip(
                        icon: Icons.schedule_send,
                        text: "جدولة نشر",
                        color: Colors.black87,
                        onTap: () {
                          Navigator.pop(context);
                          _schedulePublishAt();
                        },
                      ),
                      chip(
                        icon: Icons.delete_outline,
                        text: "حذف نهائي",
                        color: Colors.red,
                        onTap: () {
                          Navigator.pop(context);
                          _confirmDelete();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        backgroundColor: AppColors.primaryDeepTeal,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: SizedBox(
          height: 28,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Text(
              _rawTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.cairo(fontWeight: FontWeight.w900),
            ),
          ),
        ),
        actions: [
          if (_canAdmin)
            IconButton(
              tooltip: 'أدوات الأدمن',
              onPressed: _openAdminToolsSheet,
              icon: const Icon(Icons.admin_panel_settings_rounded,
                  color: Colors.white),
            ),
          IconButton(
            tooltip: _isFavorite ? 'إزالة من المفضلة' : 'إضافة للمفضلة',
            onPressed: _toggleFavorite,
            icon: Icon(
              _isFavorite
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: _loadingArticle
            ? const Center(
                child: SizedBox(
                  width: 34,
                  height: 34,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : (!_articleExists
                ? _centerMsg("الموضوع غير موجود أو اتغير عنوانه.")
                : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _infoBox(_hook.isEmpty ? "—" : _hook),
                        const SizedBox(height: 14),
                        _sectionBox(title: 'تصحيح المفهوم', body: _reset),
                        const SizedBox(height: 14),
                        _sectionBox(title: 'المعلومة اللي بتفرق', body: _core),
                        const SizedBox(height: 14),
                        _sectionBox(title: 'مثال واقعي', body: _example),
                        const SizedBox(height: 16),
                        _lockBox(_lock),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            _pillAction(
                              icon: Icons.share_outlined,
                              label: "مشاركة",
                              color: AppColors.secondaryOrange,
                              onTap: _shareTopic,
                            ),
                            const SizedBox(width: 10),

                            // ✅ FIX: make bottom favorite clickable
                            Expanded(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: _toggleFavorite,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: AppColors.primaryDeepTeal
                                          .withValues(alpha: 0.10),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _isFavorite
                                            ? Icons.bookmark_rounded
                                            : Icons.bookmark_border_rounded,
                                        size: 18,
                                        color: AppColors.primaryDeepTeal,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _isFavorite
                                            ? "في المفضلة"
                                            : "أضف للمفضلة",
                                        style: GoogleFonts.cairo(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 12.5,
                                          color: AppColors.primaryDeepTeal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _navCircle(
                              enabled: _hasPrev,
                              icon: Icons.arrow_back_ios_new,
                              color: AppColors.primaryDeepTeal,
                              onTap: _hasPrev
                                  ? () => _goToTitleRaw(
                                      _nav[_currentIndex - 1].titleRaw)
                                  : null,
                            ),
                            IconButton(
                              icon: const Icon(Icons.grid_view_rounded),
                              color: AppColors.primaryDeepTeal,
                              iconSize: 26,
                              onPressed: () => Navigator.pop(context),
                            ),
                            _navCircle(
                              enabled: _hasNext,
                              icon: Icons.arrow_forward_ios,
                              color: AppColors.secondaryOrange,
                              onTap: _hasNext
                                  ? () => _goToTitleRaw(
                                      _nav[_currentIndex + 1].titleRaw)
                                  : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                  )),
      ),
    );
  }

  Widget _pillAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.w900,
                fontSize: 12.5,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navCircle({
    required bool enabled,
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return Opacity(
      opacity: enabled ? 1 : 0.30,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: IconButton(
          icon: Icon(icon, color: Colors.white, size: 20),
          onPressed: enabled ? onTap : null,
        ),
      ),
    );
  }

  Widget _centerMsg(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(
            fontSize: 13,
            height: 1.7,
            fontWeight: FontWeight.w900,
            color: AppColors.primaryDeepTeal,
          ),
        ),
      ),
    );
  }

  Widget _infoBox(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            AppColors.primaryDeepTeal.withValues(alpha: 0.10),
            AppColors.secondaryOrange.withValues(alpha: 0.10),
          ],
        ),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.cairo(
          fontSize: 13,
          height: 1.7,
          fontWeight: FontWeight.w900,
          color: AppColors.primaryDeepTeal,
        ),
      ),
    );
  }

  Widget _sectionBox({required String title, required String body}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primaryDeepTeal.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
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
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
              color: AppColors.secondaryOrange,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body.isEmpty ? "—" : body,
            textAlign: TextAlign.right,
            style: GoogleFonts.cairo(
              fontSize: 13.5,
              height: 1.9,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2D3142),
            ),
          ),
        ],
      ),
    );
  }

  Widget _lockBox(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            AppColors.primaryDeepTeal.withValues(alpha: 0.10),
            AppColors.secondaryOrange.withValues(alpha: 0.10),
          ],
        ),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
      ),
      child: Text(
        text.isEmpty ? "—" : text,
        textAlign: TextAlign.center,
        style: GoogleFonts.cairo(
          fontSize: 13,
          height: 1.7,
          fontWeight: FontWeight.w900,
          color: AppColors.primaryDeepTeal,
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

class _NavItem {
  final String titleNorm;
  final String titleRaw;
  final int createdAtMs;

  _NavItem({
    required this.titleNorm,
    required this.titleRaw,
    required this.createdAtMs,
  });
}

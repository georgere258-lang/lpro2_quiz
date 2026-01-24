// PATH: lib/presentation/screens/know_client_articles_screen.dart
// STATUS: Full File – ✅ Firestore Reader by docId (safe) + fallback by title + compact actions + prev/next by docIds
// + BottomNav added (aligned with Fact architecture)
// + ✅ Admin Tools (role-based) identical to FactArticlesScreen

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_colors.dart';
import '../widgets/lpro_bottom_nav_bar.dart';
import 'main_wrapper.dart';

class KnowClientArticlesScreen extends StatefulWidget {
  // ✅ docId is preferred
  final String? docId;

  // ✅ optional fallback (legacy)
  final String? title;

  const KnowClientArticlesScreen({
    super.key,
    this.docId,
    this.title,
  });

  @override
  State<KnowClientArticlesScreen> createState() =>
      _KnowClientArticlesScreenState();
}

class _KnowClientArticlesScreenState extends State<KnowClientArticlesScreen> {
  static const String _collectionName = 'know_your_client';
  static const String _prefsFavKey = 'kyc_fav_titles';

  bool _loading = true;
  bool _isFavorite = false;

  // ✅ Admin state (role from users/{uid}.role)
  String _role = 'user';
  bool get _canAdmin => _role == 'admin' || _role == 'moderator';
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _roleSubscription;

  // doc
  String _docId = '';
  String _title = '';
  String _hook = '';
  String _article = '';
  String _reset = '';
  String _core = '';
  String _example = '';
  String _lock = '';

  // ✅ Control fields (stored in Firestore)
  bool _isActive = true;
  bool _isFeatured = false;
  int _featuredOrder = 0;
  DateTime? _featuredUntil;

  // navigation list
  List<_NavItem> _nav = [];
  int _navIndex = -1;

  @override
  void initState() {
    super.initState();
    _listenRole();
    _loadArticleAndNav();
  }

  @override
  void dispose() {
    _roleSubscription?.cancel();
    super.dispose();
  }

  // =========================
  // Helpers
  // =========================
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
  void _listenRole() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _roleSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen(
      (doc) {
        final data = doc.data();
        final r = (data?['role'] ?? 'user').toString().trim().toLowerCase();
        if (mounted) {
          setState(() => _role = r.isEmpty ? 'user' : r);
        }
      },
      onError: (_) {},
    );
  }

  Future<void> _loadArticleAndNav() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      DocumentSnapshot<Map<String, dynamic>>? docSnap;

      final incomingDocId = (widget.docId ?? '').trim();
      final incomingTitle = (widget.title ?? '').trim();

      // =========================
      // 1) Load Article (Prefer docId)
      // =========================
      if (incomingDocId.isNotEmpty) {
        final d = await FirebaseFirestore.instance
            .collection(_collectionName)
            .doc(incomingDocId)
            .get();

        if (d.exists) {
          docSnap = d;
        }
      }

      // Fallback by title (legacy)
      if (docSnap == null && incomingTitle.isNotEmpty) {
        final snap = await FirebaseFirestore.instance
            .collection(_collectionName)
            .where('title', isEqualTo: incomingTitle)
            .limit(1)
            .get();

        if (snap.docs.isNotEmpty) {
          docSnap = snap.docs.first;
        }
      }

      if (docSnap == null || !docSnap.exists) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _title = incomingTitle.isNotEmpty ? incomingTitle : 'موضوع';
        });
        return;
      }

      final data = docSnap.data() ?? {};

      _docId = docSnap.id;
      _title = (data['title'] ?? incomingTitle).toString();
      _hook = (data['hook'] ?? '').toString();
      _article = (data['article'] ?? data['body'] ?? '').toString();
      _reset = (data['reset'] ?? '').toString();
      _core = (data['core'] ?? '').toString();
      _example = (data['example'] ?? '').toString();
      _lock = (data['lock'] ?? '').toString();

      // ✅ Control fields
      _isActive = data['isActive'] == true;
      _isFeatured = data['isFeatured'] == true;

      final foRaw = data['featuredOrder'];
      _featuredOrder =
          (foRaw is int) ? foRaw : int.tryParse((foRaw ?? '0').toString()) ?? 0;

      final fu = data['featuredUntil'];
      _featuredUntil = (fu is Timestamp) ? fu.toDate() : null;

      // =========================
      // 2) Build navigation list (active only, ordered by createdAt desc)
      // =========================
      final all = await FirebaseFirestore.instance
          .collection(_collectionName)
          .where('isActive', isEqualTo: true)
          .limit(900)
          .get();

      final items = <_NavItem>[];
      final seenIds = <String>{};

      for (final d in all.docs) {
        final raw = d.data();

        final title = (raw['title'] ?? '').toString().trim();
        if (title.isEmpty) continue;

        // no duplicates by docId
        if (seenIds.contains(d.id)) continue;
        seenIds.add(d.id);

        final ts = raw['createdAt'];
        final ms = (ts is Timestamp) ? ts.millisecondsSinceEpoch : 0;

        items.add(_NavItem(id: d.id, title: title, ms: ms));
      }

      items.sort((a, b) => b.ms.compareTo(a.ms));
      _nav = items;

      _navIndex = _nav.indexWhere((e) => e.id == _docId);

      // Load favorite state
      await _loadFavoriteState();

      if (!mounted) return;
      setState(() => _loading = false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _loadFavoriteState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fav = prefs.getStringList(_prefsFavKey) ?? <String>[];
      final normTitle = _title.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (!mounted) return;
      setState(() => _isFavorite = fav.contains(normTitle));
    } catch (_) {}
  }

  Future<void> _toggleFavorite() async {
    final normTitle = _title.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normTitle.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final fav = (prefs.getStringList(_prefsFavKey) ?? <String>[]).toList();

      if (fav.contains(normTitle)) {
        fav.remove(normTitle);
        if (!mounted) return;
        setState(() => _isFavorite = false);
      } else {
        fav.add(normTitle);
        if (!mounted) return;
        setState(() => _isFavorite = true);
      }

      await prefs.setStringList(_prefsFavKey, fav);
    } catch (_) {}
  }

  void _shareTopic() {
    final title = _title.trim();
    final h = _hook.trim().isEmpty ? "موضوع من L Pro" : _hook.trim();
    final shareText = "$title\n\n$h\n\n#LPro #اعرف_عميلك";
    Share.share(shareText);
  }

  bool get _hasPrev => _navIndex > 0;
  bool get _hasNext => _navIndex >= 0 && _navIndex < _nav.length - 1;

  void _goToIndex(int newIndex) {
    if (newIndex < 0 || newIndex >= _nav.length) return;
    final item = _nav[newIndex];

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => KnowClientArticlesScreen(
          docId: item.id,
          title: item.title,
        ),
      ),
    );
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

      await _docRef.delete();
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

      await _docRef.update({
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

      await _docRef.update({
        'isActive': true,
        'publishAt': Timestamp.fromDate(DateTime.now()),
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

      await _docRef.update({
        'publishAt': Timestamp.fromDate(dt),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _snack("تمت جدولة وقت النشر ✅");
    } catch (_) {
      _snack("فشل الجدولة. راجع Rules.");
    }
  }

  // ✅ Featured control (no section control for KYC)
  Future<void> _openFeaturedControl() async {
    if (_docId.isEmpty) {
      _snack("لا يوجد docId للموضوع.");
      return;
    }

    bool isFeaturedLocal = _isFeatured;
    int featuredOrderLocal = _featuredOrder;
    DateTime? untilLocal = _featuredUntil;

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
                          "ترشيحات Pro",
                          textAlign: TextAlign.right,
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.w900,
                            fontSize: 14.5,
                            color: AppColors.primaryDeepTeal,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "• ترتيب المختارات = ترتيب داخل \"ترشيحات Pro\"",
                          textAlign: TextAlign.right,
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 10),

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
                                      ? "انتهاء التثبيت: غير محدد"
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
                        // ✅ Save button: adaptive height, no clipping
                        Align(
                          alignment: Alignment.center,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 48),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.secondaryOrange,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14, horizontal: 28),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: () async {
                                final nav = Navigator.of(context);
                                try {
                                  await _docRef.update({
                                    'isFeatured': isFeaturedLocal,
                                    'featuredOrder': featuredOrderLocal,
                                    'featuredUntil': untilLocal == null
                                        ? FieldValue.delete()
                                        : Timestamp.fromDate(untilLocal!),
                                    'updatedAt': FieldValue.serverTimestamp(),
                                  });

                                  if (!mounted) return;
                                  setState(() {
                                    _isFeatured = isFeaturedLocal;
                                    _featuredOrder = featuredOrderLocal;
                                    _featuredUntil = untilLocal;
                                  });

                                  nav.pop();
                                  _snack("تم حفظ التحكم ✅");
                                } catch (_) {
                                  _snack("فشل الحفظ. راجع Rules.");
                                }
                              },
                              child: Text(
                                "حفظ التحكم",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
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
          required String tooltip,
          required VoidCallback onTap,
          required Color color,
        }) {
          return Tooltip(
            message: tooltip,
            child: ActionChip(
              onPressed: onTap,
              avatar: Icon(icon, size: 18, color: color),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              labelPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              label: Text(
                text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  height: 1.3,
                  color: color,
                ),
              ),
              backgroundColor: color.withValues(alpha: 0.08),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
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
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      chip(
                        icon: Icons.star_outline_rounded,
                        text: "ترشيحات\n+ ترتيب",
                        tooltip: "ترشيحات Pro + ترتيب",
                        color: AppColors.secondaryOrange,
                        onTap: () {
                          Navigator.pop(context);
                          _openFeaturedControl();
                        },
                      ),
                      chip(
                        icon: _isActive
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        text: _isActive ? "إخفاء" : "إظهار",
                        tooltip: "إخفاء/إظهار",
                        color: _isActive ? Colors.redAccent : Colors.green,
                        onTap: () {
                          Navigator.pop(context);
                          _toggleActive(!_isActive);
                        },
                      ),
                      chip(
                        icon: Icons.publish_rounded,
                        text: "نشر الآن",
                        tooltip: "نشر الآن",
                        color: AppColors.secondaryOrange,
                        onTap: () {
                          Navigator.pop(context);
                          _publishNow();
                        },
                      ),
                      chip(
                        icon: Icons.schedule_send,
                        text: "جدولة\nنشر",
                        tooltip: "جدولة نشر",
                        color: Colors.black87,
                        onTap: () {
                          Navigator.pop(context);
                          _schedulePublishAt();
                        },
                      ),
                      chip(
                        icon: Icons.delete_outline,
                        text: "حذف",
                        tooltip: "حذف نهائي",
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

  @override
  Widget build(BuildContext context) {
    final safeTitle = (_title.trim().isEmpty)
        ? ((widget.title ?? '').trim().isEmpty ? 'موضوع' : widget.title!)
        : _title;

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
              safeTitle,
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
          const SizedBox(width: 4),
        ],
      ),
      bottomNavigationBar: LProBottomNavBar(
        activeIndex: 0,
        onTap: (index) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => MainWrapper(initialIndex: index),
            ),
            (route) => false,
          );
        },
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: _loading
            ? const Center(
                child: SizedBox(
                  width: 34,
                  height: 34,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : SafeArea(
                top: false,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_hook.trim().isNotEmpty) ...[
                        _infoBox(_hook),
                        const SizedBox(height: 14),
                      ],
                      if (_article.trim().isNotEmpty) ...[
                        _articleBox(_article),
                        const SizedBox(height: 14),
                      ],
                      if (_reset.trim().isNotEmpty) ...[
                        _sectionBox(title: 'تصحيح المفهوم', body: _reset),
                        const SizedBox(height: 14),
                      ],
                      if (_core.trim().isNotEmpty) ...[
                        _sectionBox(title: 'المعلومة اللي بتفرق', body: _core),
                        const SizedBox(height: 14),
                      ],
                      if (_example.trim().isNotEmpty) ...[
                        _sectionBox(title: 'مثال واقعي', body: _example),
                        const SizedBox(height: 14),
                      ],
                      if (_lock.trim().isNotEmpty) ...[
                        _lockBox(_lock),
                        const SizedBox(height: 16),
                      ],
                      _actionsRow(
                        onBackToList: () => Navigator.pop(context),
                        onPrev:
                            _hasPrev ? () => _goToIndex(_navIndex - 1) : null,
                        onNext:
                            _hasNext ? () => _goToIndex(_navIndex + 1) : null,
                        onFav: _toggleFavorite,
                        onShare: _shareTopic,
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // ============ UI Blocks ============

  Widget _infoBox(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFFEFF4F3), Color(0xFFFFF1E2)],
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.cairo(
          fontSize: 13.5,
          height: 1.7,
          fontWeight: FontWeight.w900,
          color: AppColors.primaryDeepTeal,
        ),
      ),
    );
  }

  Widget _articleBox(String body) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
        border:
            Border.all(color: AppColors.primaryDeepTeal.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'المقال',
            style: GoogleFonts.cairo(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: AppColors.primaryDeepTeal,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: GoogleFonts.cairo(
              fontSize: 14.5,
              height: 1.95,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2D3142),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionBox({required String title, required String body}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
        border:
            Border.all(color: AppColors.primaryDeepTeal.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: AppColors.secondaryOrange,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: GoogleFonts.cairo(
              fontSize: 14,
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
        gradient: const LinearGradient(
          colors: [Color(0xFFEFF4F3), Color(0xFFFFF1E2)],
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.cairo(
          fontSize: 13.5,
          height: 1.7,
          fontWeight: FontWeight.w900,
          color: AppColors.primaryDeepTeal,
        ),
      ),
    );
  }

  Widget _actionsRow({
    required VoidCallback onBackToList,
    required VoidCallback? onPrev,
    required VoidCallback? onNext,
    required VoidCallback onFav,
    required VoidCallback onShare,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _circleNavButton(
            icon: Icons.arrow_back_ios_new,
            color: AppColors.primaryDeepTeal,
            onTap: onPrev,
            disabled: onPrev == null,
          ),
          Row(
            children: [
              IconButton(
                tooltip: _isFavorite ? 'إزالة من المفضلة' : 'إضافة للمفضلة',
                onPressed: onFav,
                icon: Icon(
                  _isFavorite
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                ),
                color: AppColors.primaryDeepTeal,
              ),
              IconButton(
                tooltip: 'مشاركة',
                onPressed: onShare,
                icon: const Icon(Icons.ios_share_rounded),
                color: AppColors.secondaryOrange,
              ),
              IconButton(
                tooltip: 'رجوع للقائمة',
                onPressed: onBackToList,
                icon: const Icon(Icons.grid_view_rounded),
                color: AppColors.primaryDeepTeal,
              ),
            ],
          ),
          _circleNavButton(
            icon: Icons.arrow_forward_ios,
            color: AppColors.secondaryOrange,
            onTap: onNext,
            disabled: onNext == null,
          ),
        ],
      ),
    );
  }

  Widget _circleNavButton({
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
    required bool disabled,
  }) {
    return Opacity(
      opacity: disabled ? 0.35 : 1,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: IconButton(
          icon: Icon(icon, color: Colors.white, size: 20),
          onPressed: disabled ? null : onTap,
        ),
      ),
    );
  }
}

class _NavItem {
  final String id;
  final String title;
  final int ms;
  _NavItem({required this.id, required this.title, required this.ms});
}

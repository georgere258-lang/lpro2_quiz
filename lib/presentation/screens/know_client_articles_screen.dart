// PATH: lib/presentation/screens/know_client_articles_screen.dart
// STATUS: FINAL SHARE LOGIC + STICKY FOOTER ✅

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_colors.dart';

class KnowClientArticlesScreen extends StatefulWidget {
  final String? docId;
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
  static const String _prefsLastSeenKey = 'kyc_last_seen_title';

  // ✅ روابط المتجر (سيتم تفعيلها تلقائياً عند وضع الرابط الحقيقي)
  static const String _androidStoreUrl = 'PUT_PLAY_STORE_LINK_HERE';
  static const String _iosStoreUrl = 'PUT_APP_STORE_LINK_HERE';

  bool _loading = true;
  bool _isFavorite = false;

  String _role = 'user';
  bool get _canAdmin => _role == 'admin' || _role == 'moderator';
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _roleSubscription;

  String _docId = '';
  String _title = '';
  String _hook = '';
  String _article = '';
  String _reset = '';
  String _core = '';
  String _example = '';
  String _lock = '';

  bool _isActive = true;
  int _publishAtMs = 0;

  bool _isFeatured = false;
  int _featuredOrder = 0;
  DateTime? _featuredUntil;

  String _sectionKey = '';
  int _orderInSection = 0;
  int _createdAtMs = 0;

  List<_NavItem> _nav = [];
  int _navIndex = -1;

  bool get _hasPrev => _navIndex > 0;
  bool get _hasNext => _navIndex >= 0 && _navIndex < _nav.length - 1;

  String get _sectionDisplayName {
    switch (_sectionKey) {
      case 'client_basics':
        return 'أساسيات العميل';
      case 'personality_types':
        return 'أنماط الشخصيات';
      case 'motives_needs':
        return 'الدوافع والاحتياجات';
      case 'objections_responses':
        return 'الاعتراضات والردود';
      case 'negotiation':
        return 'التفاوض';
      case 'closing':
        return 'إغلاق الصفقة';
      case 'after_sale':
        return 'متابعة وما بعد البيع';
      default:
        return 'اعرف عميلك';
    }
  }

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
        if (mounted) setState(() => _role = r.isEmpty ? 'user' : r);
      },
      onError: (_) {},
    );
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  int _tsToMs(dynamic v) {
    if (v is Timestamp) return v.millisecondsSinceEpoch;
    if (v is int) return v;
    return DateTime.now().millisecondsSinceEpoch;
  }

  Future<void> _loadArticleAndNav() async {
    setState(() => _loading = true);

    try {
      DocumentSnapshot<Map<String, dynamic>>? docSnap;

      final incomingDocId = (widget.docId ?? '').trim();
      final incomingTitle = (widget.title ?? '').trim();

      if (incomingDocId.isNotEmpty) {
        final d = await FirebaseFirestore.instance
            .collection(_collectionName)
            .doc(incomingDocId)
            .get();
        if (d.exists) docSnap = d;
      }

      if (docSnap == null && incomingTitle.isNotEmpty) {
        final snap = await FirebaseFirestore.instance
            .collection(_collectionName)
            .where('title', isEqualTo: incomingTitle)
            .limit(1)
            .get();
        if (snap.docs.isNotEmpty) docSnap = snap.docs.first;
      }

      if (docSnap == null || !docSnap.exists) {
        setState(() => _loading = false);
        return;
      }

      final data = docSnap.data()!;
      _docId = docSnap.id;

      _title = (data['title'] ?? '').toString();
      _hook = (data['hook'] ?? '').toString();
      _article = (data['article'] ?? data['body'] ?? '').toString();
      _reset = (data['reset'] ?? '').toString();
      _core = (data['core'] ?? '').toString();
      _example = (data['example'] ?? '').toString();
      _lock = (data['lock'] ?? '').toString();

      _isActive = (data['isActive'] != false);

      _publishAtMs = _tsToMs(data['publishAt']);
      _createdAtMs = _tsToMs(data['createdAt']);

      _isFeatured = (data['isFeatured'] == true);

      final fo = data['featuredOrder'];
      _featuredOrder =
          (fo is int) ? fo : int.tryParse((fo ?? '0').toString()) ?? 0;

      final fu = data['featuredUntil'];
      _featuredUntil = fu is Timestamp ? fu.toDate() : null;

      _sectionKey = (data['sectionKey'] ?? '').toString().trim();

      final ois = data['orderInSection'];
      _orderInSection =
          (ois is int) ? ois : int.tryParse((ois ?? '0').toString()) ?? 0;

      await _markLastSeen(_title, _docId);
      await _loadFavoriteState();

      await _buildSectionNav();

      setState(() => _loading = false);
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _buildSectionNav() async {
    if (_sectionKey.isEmpty) {
      _nav = [];
      _navIndex = -1;
      return;
    }

    final snap = await FirebaseFirestore.instance
        .collection(_collectionName)
        .where('sectionKey', isEqualTo: _sectionKey)
        .where('isActive', isEqualTo: true)
        .get();

    final list = <_NavItem>[];

    for (final d in snap.docs) {
      final m = d.data();
      final t = (m['title'] ?? '').toString().trim();
      if (t.isEmpty) continue;

      final orderRaw = m['orderInSection'];
      final order = (orderRaw is int)
          ? orderRaw
          : int.tryParse((orderRaw ?? '0').toString()) ?? 0;

      final createdMs = _tsToMs(m['createdAt']);

      list.add(_NavItem(
        id: d.id,
        title: t,
        orderInSection: order,
        createdAtMs: createdMs,
      ));
    }

    list.sort((a, b) {
      final byOrder = a.orderInSection.compareTo(b.orderInSection);
      if (byOrder != 0) return byOrder;
      return a.createdAtMs.compareTo(b.createdAtMs);
    });

    if (mounted) {
      setState(() {
        _nav = list;
        _navIndex = _nav.indexWhere((e) => e.id == _docId);
      });
    }
  }

  Future<void> _markLastSeen(String title, String docId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsLastSeenKey, title.trim());
      await prefs.setString('${_prefsLastSeenKey}_docid', docId.trim());
    } catch (_) {}
  }

  Future<void> _loadFavoriteState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fav = prefs.getStringList(_prefsFavKey) ?? [];
      if (!mounted) return;
      setState(() => _isFavorite = fav.contains(_title.trim()));
    } catch (_) {}
  }

  void _toggleFavorite() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fav = (prefs.getStringList(_prefsFavKey) ?? []).toList();

      if (fav.contains(_title.trim())) {
        fav.remove(_title.trim());
        _isFavorite = false;
      } else {
        fav.add(_title.trim());
        _isFavorite = true;
      }

      await prefs.setStringList(_prefsFavKey, fav);
      setState(() {});
    } catch (_) {}
  }

  // ✅ تحديث دالة الشير (Logic Only Update)
  void _shareTopic() {
    final sb = StringBuffer();
    sb.writeln(_title);
    if (_hook.isNotEmpty) sb.writeln("\n$_hook");
    sb.writeln("\n#LPro #اعرف_عميلك");

    // إضافة الروابط فقط إذا كانت صحيحة (تبدأ بـ http)
    if (_androidStoreUrl.startsWith('http')) {
      sb.writeln("\nAndroid: $_androidStoreUrl");
    }
    if (_iosStoreUrl.startsWith('http')) {
      sb.writeln("iOS: $_iosStoreUrl");
    }

    Share.share(sb.toString());
  }

  Future<void> _goToDoc(String docId, String title) async {
    if (!mounted) return;
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => KnowClientArticlesScreen(docId: docId, title: title),
      ),
    );
  }

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

  // =========================
  // ADMIN TOOLS
  // =========================

  Future<void> _toggleActive(bool value) async {
    try {
      if (_docId.isEmpty) return;
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
      if (_docId.isEmpty) return;
      await _docRef.update({
        'isActive': true,
        'publishAt': DateTime.now(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      setState(() {
        _isActive = true;
        _publishAtMs = DateTime.now().millisecondsSinceEpoch;
      });
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
      if (_docId.isEmpty) return;
      await _docRef.update({
        'publishAt': dt,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      setState(() => _publishAtMs = dt.millisecondsSinceEpoch);
      _snack("تمت جدولة وقت النشر ✅");
    } catch (_) {
      _snack("فشل الجدولة. راجع Rules.");
    }
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
      if (_docId.isEmpty) return;
      await _docRef.delete();
      if (!mounted) return;
      _snack("تم الحذف ✅");
      Navigator.pop(context);
    } catch (_) {
      _snack("فشل الحذف. راجع Rules.");
    }
  }

  Future<void> _openEditor() async {
    if (_docId.isEmpty) return;

    final titleC = TextEditingController(text: _title);
    final hookC = TextEditingController(text: _hook);
    final articleC = TextEditingController(text: _article);
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
                      "تعديل محتوى الموضوع",
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
                    _tf(articleC, "الشرح ببساطة", maxLines: 6),
                    const SizedBox(height: 10),
                    _tf(resetC, "تصحيح زاوية النظر (reset)", maxLines: 5),
                    const SizedBox(height: 10),
                    _tf(coreC, "الخلاصة المفيدة (core)", maxLines: 6),
                    const SizedBox(height: 10),
                    _tf(exampleC, "مثال من الواقع (example)", maxLines: 5),
                    const SizedBox(height: 10),
                    _tf(lockC, "إغلاق عملي (lock)", maxLines: 4),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondaryOrange,
                        padding: const EdgeInsets.symmetric(vertical: 14),
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
                          await _docRef.update({
                            'title': t,
                            'hook': hookC.text.trim(),
                            'article': articleC.text.trim(),
                            'reset': resetC.text.trim(),
                            'core': coreC.text.trim(),
                            'example': exampleC.text.trim(),
                            'lock': lockC.text.trim(),
                            'updatedAt': FieldValue.serverTimestamp(),
                          });

                          if (!mounted) return;
                          setState(() {
                            _title = t;
                            _hook = hookC.text.trim();
                            _article = articleC.text.trim();
                            _reset = resetC.text.trim();
                            _core = coreC.text.trim();
                            _example = exampleC.text.trim();
                            _lock = lockC.text.trim();
                          });

                          Navigator.pop(context);
                          _snack("تم التحديث ✅");
                        } catch (_) {
                          _snack("فشل التحديث. راجع Rules.");
                        }
                      },
                      child: Text(
                        "حفظ التعديل",
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
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
  }

  Future<void> _openControlSheet() async {
    if (_docId.isEmpty) return;

    bool isFeaturedLocal = _isFeatured;
    int featuredOrderLocal = _featuredOrder;
    DateTime? untilLocal = _featuredUntil;

    String sectionKeyLocal = _sectionKey;
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
                        "$label: $value",
                        textAlign: TextAlign.right,
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.w900,
                          fontSize: 12.5,
                          color: AppColors.primaryDeepTeal,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      onPressed: onDown,
                    ),
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_up_rounded),
                      onPressed: onUp,
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
                          "تحكم الموضوع والترتيب",
                          textAlign: TextAlign.right,
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.w900,
                            fontSize: 14.5,
                            color: AppColors.primaryDeepTeal,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SwitchListTile(
                          title: Text("ترشيح في الرئيسية (Featured)",
                              style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.w900, fontSize: 12.8)),
                          value: isFeaturedLocal,
                          onChanged: (v) => setLocal(() => isFeaturedLocal = v),
                        ),
                        stepperRow(
                          label: "ترتيب الترشيح",
                          value: featuredOrderLocal,
                          onDown: () => setLocal(() {
                            if (featuredOrderLocal > 0) featuredOrderLocal--;
                          }),
                          onUp: () => setLocal(() => featuredOrderLocal++),
                        ),
                        const SizedBox(height: 10),
                        stepperRow(
                          label: "ترتيب داخل القسم",
                          value: orderInSectionLocal,
                          onDown: () => setLocal(() {
                            if (orderInSectionLocal > 0) orderInSectionLocal--;
                          }),
                          onUp: () => setLocal(() => orderInSectionLocal++),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          decoration: const InputDecoration(
                            labelText: "مفتاح القسم (sectionKey)",
                            border: OutlineInputBorder(),
                          ),
                          controller:
                              TextEditingController(text: sectionKeyLocal),
                          onChanged: (v) => sectionKeyLocal = v.trim(),
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondaryOrange,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () async {
                            try {
                              await _docRef.update({
                                'isFeatured': isFeaturedLocal,
                                'featuredOrder': featuredOrderLocal,
                                'featuredUntil':
                                    untilLocal ?? FieldValue.delete(),
                                'sectionKey': sectionKeyLocal,
                                'orderInSection': orderInSectionLocal,
                                'updatedAt': FieldValue.serverTimestamp(),
                              });
                              if (!mounted) return;
                              setState(() {
                                _isFeatured = isFeaturedLocal;
                                _featuredOrder = featuredOrderLocal;
                                _orderInSection = orderInSectionLocal;
                                _sectionKey = sectionKeyLocal;
                              });
                              Navigator.pop(context);
                              await _buildSectionNav();
                              _snack("تم الحفظ ✅");
                            } catch (_) {
                              _snack("فشل الحفظ.");
                            }
                          },
                          child: const Text("تحديث البيانات",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
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
        Widget chip(
            {required IconData icon,
            required String text,
            required Color color,
            required VoidCallback onTap}) {
          return ActionChip(
            onPressed: onTap,
            avatar: Icon(icon, size: 18, color: color),
            label: Text(
              text,
              style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w900, fontSize: 12, color: color),
            ),
            backgroundColor: color.withOpacity(0.08),
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
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      chip(
                          icon: Icons.tune_rounded,
                          text: "تحكم الترتيب",
                          color: AppColors.secondaryOrange,
                          onTap: () {
                            Navigator.pop(context);
                            _openControlSheet();
                          }),
                      chip(
                          icon: Icons.edit_outlined,
                          text: "تعديل المحتوى",
                          color: AppColors.primaryDeepTeal,
                          onTap: () {
                            Navigator.pop(context);
                            _openEditor();
                          }),
                      chip(
                          icon: _isActive
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          text: _isActive ? "إخفاء" : "إظهار",
                          color: _isActive ? Colors.redAccent : Colors.green,
                          onTap: () {
                            Navigator.pop(context);
                            _toggleActive(!_isActive);
                          }),
                      chip(
                          icon: Icons.publish_rounded,
                          text: "نشر الآن",
                          color: AppColors.secondaryOrange,
                          onTap: () {
                            Navigator.pop(context);
                            _publishNow();
                          }),
                      chip(
                          icon: Icons.schedule_send,
                          text: "جدولة نشر",
                          color: Colors.black87,
                          onTap: () {
                            Navigator.pop(context);
                            _schedulePublishAt();
                          }),
                      chip(
                          icon: Icons.delete_outline,
                          text: "حذف نهائي",
                          color: Colors.red,
                          onTap: () {
                            Navigator.pop(context);
                            _confirmDelete();
                          }),
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

  // ================= UI (PREMIUM LAYOUT) =================

  Widget _premiumCard(
          {required String title,
          required String body,
          required Color color}) =>
      Container(
        margin: const EdgeInsets.only(top: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 15,
                offset: const Offset(0, 6))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
                height: 3.5,
                decoration: BoxDecoration(
                    color: color.withOpacity(0.45),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(18)))),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.cairo(
                          fontWeight: FontWeight.w900,
                          color: color,
                          fontSize: 14)),
                  const SizedBox(height: 8),
                  Text(body,
                      style: GoogleFonts.cairo(
                          fontSize: 14,
                          height: 1.95,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87)),
                ],
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        backgroundColor: AppColors.primaryDeepTeal,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Text(_sectionDisplayName,
            style:
                GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 16)),
        actions: [
          if (_canAdmin)
            IconButton(
                icon: const Icon(Icons.admin_panel_settings_rounded),
                onPressed: _openAdminToolsSheet),
          IconButton(
            icon: Icon(_isFavorite
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      // ✅ Same layout structure as before (Sticky Footer)
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _infoBox(_hook.isEmpty ? "—" : _hook),
                        const SizedBox(height: 14),
                        if (_article.isNotEmpty)
                          _premiumCard(
                              title: 'الشرح ببساطة',
                              body: _article,
                              color: AppColors.primaryDeepTeal),
                        if (_reset.isNotEmpty)
                          _premiumCard(
                              title: 'تصحيح زاوية النظر',
                              body: _reset,
                              color: AppColors.secondaryOrange),
                        if (_core.isNotEmpty)
                          _premiumCard(
                              title: 'الخلاصة المفيدة',
                              body: _core,
                              color: AppColors.primaryDeepTeal),
                        if (_example.isNotEmpty)
                          _premiumCard(
                              title: 'مثال من الواقع',
                              body: _example,
                              color: AppColors.secondaryOrange),
                        if (_lock.isNotEmpty) _lockBox(_lock),
                        const SizedBox(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _actionIconCircle(
                              icon: Icons.ios_share_rounded,
                              onTap: _shareTopic,
                              color: AppColors.secondaryOrange,
                            ),
                            const SizedBox(width: 25),
                            _actionIconCircle(
                              icon: _isFavorite
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_outline_rounded,
                              onTap: _toggleFavorite,
                              color: AppColors.primaryDeepTeal,
                            ),
                            const SizedBox(width: 25),
                            _actionIconCircle(
                              icon: Icons.grid_view_rounded,
                              onTap: () => Navigator.pop(context),
                              color: AppColors.primaryDeepTeal,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _navCircle(
                          enabled: _hasPrev,
                          icon: Icons.arrow_back_ios_new,
                          color: AppColors.primaryDeepTeal,
                          onTap: _hasPrev
                              ? () => _goToDoc(_nav[_navIndex - 1].id,
                                  _nav[_navIndex - 1].title)
                              : null,
                        ),
                        Text(
                          "${_navIndex + 1} / ${_nav.length}",
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                        _navCircle(
                          enabled: _hasNext,
                          icon: Icons.arrow_forward_ios,
                          color: AppColors.secondaryOrange,
                          onTap: _hasNext
                              ? () => _goToDoc(_nav[_navIndex + 1].id,
                                  _nav[_navIndex + 1].title)
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _actionIconCircle(
      {required IconData icon,
      required VoidCallback onTap,
      required Color color}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Icon(icon, color: color, size: 26),
      ),
    );
  }

  Widget _infoBox(String text) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFFEFF4F3), Color(0xFFFFF1E2)]),
            borderRadius: BorderRadius.circular(18)),
        child: Text(text,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
                fontWeight: FontWeight.w900,
                height: 1.7,
                color: AppColors.primaryDeepTeal)),
      );

  Widget _lockBox(String text) => Container(
        margin: const EdgeInsets.only(top: 14),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: AppColors.primaryDeepTeal.withOpacity(0.05),
            borderRadius: BorderRadius.circular(18),
            border:
                Border.all(color: AppColors.primaryDeepTeal.withOpacity(0.1))),
        child: Text(text,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
                fontWeight: FontWeight.w900,
                height: 1.7,
                color: AppColors.primaryDeepTeal)),
      );

  Widget _navCircle(
      {required bool enabled,
      required IconData icon,
      required Color color,
      required VoidCallback? onTap}) {
    return Opacity(
        opacity: enabled ? 1 : 0.3,
        child: CircleAvatar(
            backgroundColor: color,
            radius: 24,
            child: IconButton(
                icon: Icon(icon, color: Colors.white, size: 20),
                onPressed: onTap)));
  }

  Widget _tf(TextEditingController c, String hint,
          {int maxLines = 1}) =>
      TextField(
          controller: c,
          maxLines: maxLines,
          textAlign: TextAlign.right,
          decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none)));
}

class _NavItem {
  final String id, title;
  final int orderInSection, createdAtMs;
  _NavItem(
      {required this.id,
      required this.title,
      required this.orderInSection,
      required this.createdAtMs});
}

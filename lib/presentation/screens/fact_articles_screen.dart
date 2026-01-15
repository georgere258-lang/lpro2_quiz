// PATH: lib/presentation/screens/fact_articles_screen.dart
// STATUS: Full File – Stable Navigation (normalize titles) + Small Share Button + AppBar long title fit
//         + Firestore fetch by title with fallback + Favorites + Last seen

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_colors.dart';

class FactArticlesScreen extends StatefulWidget {
  final String title; // ✅ Protocol: title only
  const FactArticlesScreen({super.key, required this.title});

  @override
  State<FactArticlesScreen> createState() => _FactArticlesScreenState();
}

class _FactArticlesScreenState extends State<FactArticlesScreen> {
  static const String _collectionName = 'pro_insight';

  static const String _prefsFavKey = 'pro_insight_fav_titles';
  static const String _prefsLastSeenKey = 'pro_insight_last_seen_title';

  bool _isFavorite = false;

  // Navigation (local sort)
  List<_NavItem> _nav = [];
  int _currentIndex = -1;

  // Article payload (loaded once with stream fallback)
  bool _loadingArticle = true;
  String _hook = '';
  String _reset = '';
  String _core = '';
  String _example = '';
  String _lock = '';
  bool _articleExists = true;

  String get _rawTitle => widget.title;
  String get _normTitle => _norm(widget.title);

  bool get _hasPrev => _currentIndex > 0;
  bool get _hasNext => _currentIndex >= 0 && _currentIndex < _nav.length - 1;

  @override
  void initState() {
    super.initState();
    _markLastSeen();
    _loadFavoriteState();
    _loadNavOrderLocal(); // ✅ بدون orderBy (مستقر)
    _loadArticleOnceWithFallback(); // ✅ حل قوي لمشكلة التطابق
  }

  // =========================
  // Normalization (critical)
  // =========================
  String _norm(String s) {
    // trim + collapse spaces + remove extra newlines/tabs
    final x = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return x;
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
        setState(() => _isFavorite = false);
      } else {
        fav.add(_normTitle);
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
    });

    try {
      // محاولة مباشرة بـ where title == rawTitle
      final direct = await FirebaseFirestore.instance
          .collection(_collectionName)
          .where('title', isEqualTo: _rawTitle.trim())
          .limit(1)
          .get();

      if (direct.docs.isNotEmpty) {
        _applyArticleFromMap(direct.docs.first.data());
        return;
      }

      // fallback: نقرأ مجموعة كبيرة ونطابق بالـ normalize (عشان اختلاف مسافات)
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
    setState(() {
      _hook = (data['hook'] ?? '').toString();
      _reset = (data['reset'] ?? '').toString();
      _core = (data['core'] ?? '').toString();
      _example = (data['example'] ?? '').toString();
      _lock = (data['lock'] ?? '').toString();
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
            createdAtMs: createdAtMs));
      }

      // ✅ ترتيب محلي (الأحدث أولاً)
      list.sort((a, b) => b.createdAtMs.compareTo(a.createdAtMs));

      final idx = list.indexWhere((e) => e.titleNorm == _normTitle);

      if (!mounted) return;
      setState(() {
        _nav = list;
        _currentIndex = idx; // الآن هيتظبط حتى لو العنوان فيه اختلاف مسافات
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

                        // ✅ small actions row (no big orange full width)
                        Row(
                          children: [
                            _pillAction(
                              icon: Icons.share_outlined,
                              label: "مشاركة",
                              color: AppColors.secondaryOrange,
                              onTap: _shareTopic,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: AppColors.primaryDeepTeal
                                        .withOpacity(0.10),
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
                          ],
                        ),

                        const SizedBox(height: 16),

                        // ✅ Navigation row (always visible)
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
            AppColors.primaryDeepTeal.withOpacity(0.10),
            AppColors.secondaryOrange.withOpacity(0.10),
          ],
        ),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
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
        border: Border.all(color: AppColors.primaryDeepTeal.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
            AppColors.primaryDeepTeal.withOpacity(0.10),
            AppColors.secondaryOrange.withOpacity(0.10),
          ],
        ),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
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

// PATH: lib/presentation/screens/know_client_articles_screen.dart
// STATUS: Full File – ✅ Firestore Reader by docId (safe) + fallback by title + compact actions + prev/next by docIds
// NOTE: UI unchanged. Only safety/logic hardening.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';

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

  bool _loading = true;

  // doc
  String _docId = '';
  String _title = '';
  String _hook = '';
  String _article = '';
  String _reset = '';
  String _core = '';
  String _example = '';
  String _lock = '';

  // navigation list
  List<_NavItem> _nav = [];
  int _navIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadArticleAndNav();
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

        // ✅ Enforce active flag when reading by docId
        if (d.exists) {
          final data = d.data() ?? {};
          final isActive = data['isActive'] == true;
          if (isActive) docSnap = d;
        }
      }

      // Fallback by title (legacy)
      if (docSnap == null && incomingTitle.isNotEmpty) {
        final snap = await FirebaseFirestore.instance
            .collection(_collectionName)
            .where('title', isEqualTo: incomingTitle)
            .where('isActive', isEqualTo: true)
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

      if (!mounted) return;
      setState(() => _loading = false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
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
          title: item.title, // display fallback only
        ),
      ),
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
        title: Text(
          safeTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 16),
        ),
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
                        onFav: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('قريبًا: المفضلة')),
                          );
                        },
                        onShare: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('قريبًا: الشير')),
                          );
                        },
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
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: AppColors.primaryDeepTeal.withOpacity(0.06)),
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
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: AppColors.primaryDeepTeal.withOpacity(0.06)),
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
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
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
                tooltip: 'مفضلة',
                onPressed: onFav,
                icon: const Icon(Icons.bookmark_border_rounded),
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

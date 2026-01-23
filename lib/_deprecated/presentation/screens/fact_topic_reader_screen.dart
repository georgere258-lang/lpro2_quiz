// PATH: lib/presentation/screens/fact_topic_reader_screen.dart
// STATUS: Full File – Reader (Share + Favorite + Next/Prev) + stable navigation list

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_colors.dart';
import 'fact_articles_screen.dart';

class FactTopicReaderScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;

  const FactTopicReaderScreen({
    super.key,
    required this.docId,
    required this.data,
  });

  @override
  State<FactTopicReaderScreen> createState() => _FactTopicReaderScreenState();
}

class _FactTopicReaderScreenState extends State<FactTopicReaderScreen> {
  static const String _collectionName = 'pro_insight';
  static const String _prefsFavKey = 'pro_insight_favorites';

  bool _isFav = false;
  List<Map<String, dynamic>> _allActive = [];
  int _currentIndex = -1;

  String get _title => (widget.data['title'] ?? '').toString();
  String get _hook => (widget.data['hook'] ?? '').toString();
  String get _reset => (widget.data['reset'] ?? '').toString();
  String get _core => (widget.data['core'] ?? '').toString();
  String get _example => (widget.data['example'] ?? '').toString();
  String get _lock => (widget.data['lock'] ?? '').toString();

  @override
  void initState() {
    super.initState();
    _loadFav();
    _loadAllForNavigation();
  }

  Future<void> _loadFav() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_prefsFavKey) ?? <String>[];
      if (!mounted) return;
      setState(() => _isFav = list.contains(_title));
    } catch (_) {}
  }

  Future<void> _toggleFav() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_prefsFavKey) ?? <String>[];
      final next = List<String>.from(list);

      if (next.contains(_title)) {
        next.remove(_title);
      } else {
        next.add(_title);
      }

      await prefs.setStringList(_prefsFavKey, next);
      if (!mounted) return;
      setState(() => _isFav = next.contains(_title));
    } catch (_) {}
  }

  Future<void> _loadAllForNavigation() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection(_collectionName)
          .where('isActive', isEqualTo: true)
          .limit(1000)
          .get();

      final items = snap.docs.map((d) {
        final data = d.data();
        int ms = 0;
        final ts = data['createdAt'];
        if (ts is Timestamp) ms = ts.millisecondsSinceEpoch;

        return {
          'title': (data['title'] ?? '').toString(),
          'createdAtMs': ms,
        };
      }).where((e) => (e['title'] as String).trim().isNotEmpty).toList();

      items.sort((a, b) =>
          (b['createdAtMs'] as int).compareTo(a['createdAtMs'] as int));

      final idx = items.indexWhere((e) => e['title'] == _title);

      if (!mounted) return;
      setState(() {
        _allActive = items;
        _currentIndex = idx;
      });
    } catch (_) {}
  }

  bool get _hasPrev => _currentIndex > 0;
  bool get _hasNext =>
      _currentIndex >= 0 && _currentIndex < _allActive.length - 1;

  void _goPrev() {
    if (!_hasPrev) return;
    final prevTitle = _allActive[_currentIndex - 1]['title'] as String;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => FactArticlesScreen(title: prevTitle)),
    );
  }

  void _goNext() {
    if (!_hasNext) return;
    final nextTitle = _allActive[_currentIndex + 1]['title'] as String;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => FactArticlesScreen(title: nextTitle)),
    );
  }

  void _share() {
    final text = [
      _title,
      if (_hook.trim().isNotEmpty) "— $_hook",
      "",
      "L Pro | المعلومة بتفرق",
    ].join("\n");
    Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        backgroundColor: AppColors.primaryDeepTeal,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          _title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.cairo(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.share_outlined), onPressed: _share),
          IconButton(
            icon: Icon(_isFav ? Icons.bookmark : Icons.bookmark_border),
            onPressed: _toggleFav,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_hook.trim().isNotEmpty) ...[
                        _infoBox(_hook),
                        const SizedBox(height: 16),
                      ],
                      if (_reset.trim().isNotEmpty) ...[
                        _sectionBox(title: 'تصحيح المفهوم', body: _reset),
                        const SizedBox(height: 16),
                      ],
                      if (_core.trim().isNotEmpty) ...[
                        _sectionBox(title: 'المعلومة اللي بتفرق', body: _core),
                        const SizedBox(height: 16),
                      ],
                      if (_example.trim().isNotEmpty) ...[
                        _sectionBox(title: 'مثال واقعي', body: _example),
                        const SizedBox(height: 18),
                      ],
                      if (_lock.trim().isNotEmpty) _lockBox(_lock),

                      const Spacer(),

                      // ===== Navigation buttons (restored) =====
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _hasPrev
                              ? _arrowButton(
                                  icon: Icons.arrow_back_ios_new,
                                  color: AppColors.primaryDeepTeal,
                                  onTap: _goPrev,
                                )
                              : const SizedBox(width: 48),
                          IconButton(
                            icon: const Icon(Icons.grid_view_rounded),
                            color: AppColors.primaryDeepTeal,
                            iconSize: 26,
                            onPressed: () => Navigator.pop(context),
                          ),
                          _hasNext
                              ? _arrowButton(
                                  icon: Icons.arrow_forward_ios,
                                  color: AppColors.secondaryOrange,
                                  onTap: _goNext,
                                )
                              : const SizedBox(width: 48),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _infoBox(String text) {
    return Container(
      padding: const EdgeInsets.all(18),
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
          fontSize: 14,
          fontWeight: FontWeight.w900,
          color: AppColors.primaryDeepTeal,
        ),
      ),
    );
  }

  Widget _sectionBox({required String title, required String body}) {
    return Container(
      padding: const EdgeInsets.all(18),
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
      padding: const EdgeInsets.all(18),
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
          fontSize: 14,
          fontWeight: FontWeight.w900,
          color: AppColors.primaryDeepTeal,
        ),
      ),
    );
  }

  Widget _arrowButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 20),
        onPressed: onTap,
      ),
    );
  }
}
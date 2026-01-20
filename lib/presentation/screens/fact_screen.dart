// PATH: lib/presentation/screens/fact_screen.dart
// STATUS: Full File – Firestore Topics (pro_insight) + Fixed Sections Plan
//         + Favorites (SharedPreferences) + Last Seen Badge
//         + Tag Normalization (fix: "سيستم الشركة" => "سيستم الشركات")
//         + ✅ NEW: Top Blocks (Zero Cost): Featured "مختارات اليوم" + Recent "حديثًا"

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_colors.dart';
import 'fact_articles_screen.dart';

class FactScreen extends StatefulWidget {
  const FactScreen({super.key});

  @override
  State<FactScreen> createState() => _FactScreenState();
}

class _FactScreenState extends State<FactScreen> {
  static const String _collectionName = 'pro_insight';

  static const List<String> _sectionsPlan = [
    'كل المواضيع',
    'المفضلة',
    'البداية الصح',
    'لغة العقارات',
    'سيستم السوق',
    'سيستم الشركات',
    'التعاقدات والإجراءات',
    'دراسة المشاريع',
  ];

  static const String _prefsFavKey = 'pro_insight_fav_titles';
  static const String _prefsLastSeenKey = 'pro_insight_last_seen_title';

  // ✅ Recent window (feel free to change later)
  static const int _recentDaysWindow = 7;

  String _selectedSection = 'كل المواضيع';
  Set<String> _favoriteTitles = {};
  String _lastSeenTitle = '';

  @override
  void initState() {
    super.initState();
    _loadLocalState();
  }

  // ✅ Normalize tags to match the content plan sections
  String _normalizeTag(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return t;

    // أهم تصحيح عندك:
    if (t == 'سيستم الشركة') return 'سيستم الشركات';

    // ممكن توسّع هنا لاحقًا لو ظهر اختلافات كتابة
    return t;
  }

  Future<void> _loadLocalState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fav = prefs.getStringList(_prefsFavKey) ?? <String>[];
      final last = prefs.getString(_prefsLastSeenKey) ?? '';
      if (!mounted) return;
      setState(() {
        _favoriteTitles =
            fav.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();
        _lastSeenTitle = last.trim();
      });
    } catch (_) {}
  }

  Future<void> _setLastSeen(String title) async {
    final t = title.trim();
    if (t.isEmpty) return;
    _lastSeenTitle = t;
    if (mounted) setState(() {});
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsLastSeenKey, t);
    } catch (_) {}
  }

  Future<void> _toggleFavorite(String title) async {
    final t = title.trim();
    if (t.isEmpty) return;

    final next = Set<String>.from(_favoriteTitles);
    if (next.contains(t)) {
      next.remove(t);
    } else {
      next.add(t);
    }

    setState(() => _favoriteTitles = next);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefsFavKey, _favoriteTitles.toList());
    } catch (_) {}
  }

  bool _isFavorite(String title) => _favoriteTitles.contains(title.trim());

  Future<void> _openTopic(String title) async {
    await _setLastSeen(title);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FactArticlesScreen(title: title),
      ),
    );
    await _loadLocalState();
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
          'المعلومة بتفرق',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 18),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            const SizedBox(height: 12),

            // ===== Header Row =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _PillButton(
                    icon: Icons.category_outlined,
                    label: 'الأقسام',
                    onTap: () => _openSectionsSheet(context),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primaryDeepTeal.withValues(alpha: 0.10),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Text(
                        _selectedSection,
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryDeepTeal,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _PillButton(
                    icon: Icons.search,
                    label: 'بحث',
                    onTap: () async {
                      final items = await _fetchOnceItems();
                      if (!mounted) return;
                      showSearch(
                        context: context,
                        delegate: _FactSearchDelegate(
                          items: items,
                          onOpen: (title) async => _openTopic(title),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // ===== Intro Card =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _introCard(),
            ),

            const SizedBox(height: 8),

            Expanded(child: _topicsList()),
          ],
        ),
      ),
    );
  }

  Widget _introCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "بوابة المعلومة اللي بتفرق",
            textAlign: TextAlign.right,
            style: GoogleFonts.cairo(
              fontSize: 13,
              height: 1.5,
              fontWeight: FontWeight.w900,
              color: AppColors.primaryDeepTeal,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "مواضيع قصيرة، مركزة، وفي نهايتها سلوك عملي.",
            textAlign: TextAlign.right,
            style: GoogleFonts.cairo(
              fontSize: 12,
              height: 1.6,
              fontWeight: FontWeight.w700,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _topicsList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream:
          FirebaseFirestore.instance.collection(_collectionName).snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return _centerMsg(
              "حصل خطأ في تحميل المواضيع.\nراجع Rules أو ترتيب الحقول.");
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

        final docs = snap.data!.docs;

        final allItems = docs
            .map((d) => _FactTopicItem.fromDoc(
                  d.id,
                  d.data(),
                  normalizeTag: _normalizeTag,
                ))
            .where((e) => e.isActive == true && e.title.trim().isNotEmpty)
            .toList();

        // ✅ Base ordering for normal list
        allItems.sort((a, b) => b.createdAtMs.compareTo(a.createdAtMs));

        // ✅ Featured (مختارات اليوم) – always show on top (from ANY section)
        final now = DateTime.now();
        final featured = allItems
            .where((e) => e.isFeatured == true && e.isFeaturedValid(now))
            .toList();
        featured.sort((a, b) {
          final byOrder = a.featuredOrder.compareTo(b.featuredOrder);
          if (byOrder != 0) return byOrder;
          return b.createdAtMs.compareTo(a.createdAtMs);
        });

        // ✅ Recent (حديثًا) – always show on top (from ANY section)
        final recentCutoff =
            now.subtract(const Duration(days: _recentDaysWindow));
        final recent = allItems
            .where((e) =>
                e.createdAtMs > 0 &&
                DateTime.fromMillisecondsSinceEpoch(e.createdAtMs)
                    .isAfter(recentCutoff))
            .take(12)
            .toList();

        // ✅ Filter list by selected section (but keep top blocks independent)
        List<_FactTopicItem> filtered;
        if (_selectedSection == 'كل المواضيع') {
          filtered = allItems;
        } else if (_selectedSection == 'المفضلة') {
          filtered = allItems.where((e) => _isFavorite(e.title)).toList();
        } else {
          filtered = allItems
              .where((e) => e.tags.contains(_normalizeTag(_selectedSection)))
              .toList();
        }

        if (filtered.isEmpty) {
          return _centerMsg(
            _selectedSection == 'المفضلة'
                ? "لا توجد مواضيع في المفضلة الآن."
                : "لا توجد مواضيع في هذا القسم الآن.",
          );
        }

        return Column(
          children: [
            // ✅ تابع من حيث توقفت
            if (_lastSeenTitle.trim().isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                child: _blockHeader(
                  title: "تابع من حيث توقفت",
                  subtitle: "آخر موضوع فتحته",
                  icon: Icons.history_rounded,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: GestureDetector(
                  onTap: () => _openTopic(_lastSeenTitle),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.primaryDeepTeal.withValues(alpha: 0.10)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      _lastSeenTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDeepTeal,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
            ],
            if (featured.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                child: _blockHeader(
                  title: "ترشيحات Pro",
                  subtitle: "مواضيع مثبتة من أقسام مختلفة",
                  icon: Icons.star_rounded,
                ),
              ),
              SizedBox(
                height: 108,
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                  itemCount: featured.length > 5 ? 5 : featured.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final item = featured[i];
                    return _miniTopicCard(
                      item: item,
                      isFavorite: _isFavorite(item.title),
                      onToggleFavorite: () => _toggleFavorite(item.title),
                      onTap: () => _openTopic(item.title),
                      badgeText: item.firstTagOrEmpty,
                    );
                  },
                ),
              ),
              const SizedBox(height: 4),
            ],
            if (recent.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                child: _blockHeader(
                  title: "جديد Pro",
                  subtitle: "آخر ما تم إضافته",
                  icon: Icons.new_releases_rounded,
                ),
              ),
              SizedBox(
                height: 108,
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                  itemCount: recent.length > 5 ? 5 : recent.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final item = recent[i];
                    return _miniTopicCard(
                      item: item,
                      isFavorite: _isFavorite(item.title),
                      onToggleFavorite: () => _toggleFavorite(item.title),
                      onTap: () => _openTopic(item.title),
                      badgeText: item.firstTagOrEmpty,
                    );
                  },
                ),
              ),
              const SizedBox(height: 4),
            ],

            // ✅ Main filtered list
            Expanded(
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = filtered[index];
                  final isLastSeen = item.title.trim() == _lastSeenTitle.trim();
                  final isFav = _isFavorite(item.title);

                  return GestureDetector(
                    onTap: () => _openTopic(item.title),
                    child: _topicCard(
                      item: item,
                      index: index,
                      isLastSeen: isLastSeen,
                      isFavorite: isFav,
                      onToggleFavorite: () => _toggleFavorite(item.title),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _blockHeader({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
      child: Row(
        children: [
          Icon(icon, color: AppColors.secondaryOrange, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryDeepTeal,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniTopicCard({
    required _FactTopicItem item,
    required bool isFavorite,
    required VoidCallback onToggleFavorite,
    required VoidCallback onTap,
    required String badgeText,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border:
              Border.all(color: AppColors.primaryDeepTeal.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondaryOrange.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            InkWell(
              onTap: onToggleFavorite,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  isFavorite
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  color: isFavorite
                      ? AppColors.secondaryOrange
                      : AppColors.primaryDeepTeal,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (badgeText.trim().isNotEmpty)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primaryDeepTeal.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primaryDeepTeal.withValues(alpha: 0.12),
                          ),
                        ),
                        child: Text(
                          badgeText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(
                            fontSize: 10.8,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primaryDeepTeal,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    item.title,
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryDeepTeal,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_ios,
                size: 16, color: AppColors.secondaryOrange),
          ],
        ),
      ),
    );
  }

  Widget _topicCard({
    required _FactTopicItem item,
    required int index,
    required bool isLastSeen,
    required bool isFavorite,
    required VoidCallback onToggleFavorite,
  }) {
    final shadowTint = index.isEven
        ? AppColors.primaryDeepTeal.withValues(alpha: 0.08)
        : AppColors.secondaryOrange.withValues(alpha: 0.08);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primaryDeepTeal.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: shadowTint,
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          InkWell(
            onTap: onToggleFavorite,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                isFavorite
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                color: isFavorite
                    ? AppColors.secondaryOrange
                    : AppColors.primaryDeepTeal,
              ),
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.arrow_forward_ios,
              size: 16, color: AppColors.secondaryOrange),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isLastSeen) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryOrange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.secondaryOrange.withValues(alpha: 0.22),
                        ),
                      ),
                      child: Text(
                        "آخر مرة كنت هنا",
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: AppColors.secondaryOrange,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  item.title,
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryDeepTeal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openSectionsSheet(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => _SectionsSheet(
        sections: _sectionsPlan,
        selected: _selectedSection,
        onSelect: (s) {
          Navigator.pop(context);
          setState(() => _selectedSection = s);
        },
      ),
    );
  }

  Future<List<_FactTopicItem>> _fetchOnceItems() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection(_collectionName)
          .where('isActive', isEqualTo: true)
          .limit(900)
          .get();

      final items = snap.docs
          .map((d) => _FactTopicItem.fromDoc(
                d.id,
                d.data(),
                normalizeTag: _normalizeTag,
              ))
          .where((e) => e.title.trim().isNotEmpty)
          .toList();

      items.sort((a, b) => b.createdAtMs.compareTo(a.createdAtMs));
      return items;
    } catch (_) {
      return [];
    }
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
}

class _PillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PillButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: AppColors.primaryDeepTeal.withValues(alpha: 0.10)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primaryDeepTeal),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: AppColors.primaryDeepTeal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionsSheet extends StatelessWidget {
  final List<String> sections;
  final String selected;
  final ValueChanged<String> onSelect;

  const _SectionsSheet({
    required this.sections,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'اختر القسم',
              textAlign: TextAlign.right,
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: AppColors.primaryDeepTeal,
              ),
            ),
            const SizedBox(height: 10),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: sections.length,
                itemBuilder: (_, i) {
                  final s = sections[i];
                  final isSel = s == selected;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      s,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color:
                            isSel ? AppColors.secondaryOrange : Colors.black87,
                      ),
                    ),
                    trailing: isSel
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                    onTap: () => onSelect(s),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FactSearchDelegate extends SearchDelegate {
  final List<_FactTopicItem> items;
  final Future<void> Function(String title) onOpen;

  _FactSearchDelegate({required this.items, required this.onOpen});

  @override
  String? get searchFieldLabel => 'ابحث عن موضوع…';

  @override
  TextStyle? get searchFieldStyle =>
      GoogleFonts.cairo(fontWeight: FontWeight.w900);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(icon: const Icon(Icons.close), onPressed: () => query = ''),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final q = query.trim().toLowerCase();
    final results = items.where((e) {
      return e.title.toLowerCase().contains(q) ||
          e.tags.join(' ').toLowerCase().contains(q);
    }).toList();

    if (results.isEmpty) {
      return Center(
        child: Text("لا نتائج.",
            style: GoogleFonts.cairo(fontWeight: FontWeight.w900)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final item = results[i];
        return ListTile(
          title: Text(
            item.title,
            textAlign: TextAlign.right,
            style: GoogleFonts.cairo(fontWeight: FontWeight.w900),
          ),
          onTap: () async {
            close(context, null);
            await onOpen(item.title);
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) => buildResults(context);
}

class _FactTopicItem {
  final String id;
  final String title;
  final int createdAtMs;
  final List<String> tags;
  final bool isActive;

  // ✅ Featured controls (from Firestore)
  final bool isFeatured;
  final int featuredOrder;
  final DateTime? featuredUntil;

  _FactTopicItem({
    required this.id,
    required this.title,
    required this.createdAtMs,
    required this.tags,
    required this.isActive,
    required this.isFeatured,
    required this.featuredOrder,
    required this.featuredUntil,
  });

  String get firstTagOrEmpty => tags.isEmpty ? '' : tags.first.trim();

  bool isFeaturedValid(DateTime now) {
    if (!isFeatured) return false;
    if (featuredUntil == null) return true;
    return featuredUntil!.isAfter(now);
  }

  factory _FactTopicItem.fromDoc(
    String id,
    Map<String, dynamic> data, {
    required String Function(String raw) normalizeTag,
  }) {
    final rawTags = data['tags'];
    final tags = <String>[];
    if (rawTags is List) {
      for (final t in rawTags) {
        final s = normalizeTag(t.toString());
        if (s.trim().isNotEmpty) tags.add(s.trim());
      }
    }

    int createdAtMs = 0;
    final ts = data['createdAt'];
    if (ts is Timestamp) createdAtMs = ts.millisecondsSinceEpoch;

    final isFeatured = data['isFeatured'] == true;

    final foRaw = data['featuredOrder'];
    final featuredOrder =
        (foRaw is int) ? foRaw : int.tryParse((foRaw ?? '0').toString()) ?? 0;

    DateTime? featuredUntil;
    final fu = data['featuredUntil'];
    if (fu is Timestamp) featuredUntil = fu.toDate();

    return _FactTopicItem(
      id: id,
      title: (data['title'] ?? '').toString(),
      createdAtMs: createdAtMs,
      tags: tags,
      isActive: data['isActive'] == true,
      isFeatured: isFeatured,
      featuredOrder: featuredOrder,
      featuredUntil: featuredUntil,
    );
  }
}

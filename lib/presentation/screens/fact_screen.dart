// PATH: lib/presentation/screens/fact_screen.dart
// STATUS: Landing Page Gateway + Favorites BottomSheet
// ORDER: Intro → Sections → Last Seen → Favorites → Recent → Featured

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_colors.dart';
import 'fact_articles_screen.dart';
import 'fact_sections_screen.dart';
import '../widgets/lpro_bottom_nav_bar.dart';
import 'main_wrapper.dart';

class FactScreen extends StatefulWidget {
  const FactScreen({super.key});

  @override
  State<FactScreen> createState() => _FactScreenState();
}

class _FactScreenState extends State<FactScreen> {
  static const String _collectionName = 'pro_insight';
  static const String _prefsFavKey = 'pro_insight_fav_titles';
  static const String _prefsLastSeenKey = 'pro_insight_last_seen_title';

  // ✅ Recent window
  static const int _recentDaysWindow = 7;

  String _lastSeenTitle = '';
  Set<String> _favoriteTitles = {};

  @override
  void initState() {
    super.initState();
    _loadLocalState();
  }

  // ✅ Normalize tags to match the content plan sections
  String _normalizeTag(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return t;
    if (t == 'سيستم الشركة') return 'سيستم الشركات';
    return t;
  }

  Future<void> _loadLocalState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final last = prefs.getString(_prefsLastSeenKey) ?? '';
      final favList = prefs.getStringList(_prefsFavKey) ?? <String>[];
      if (!mounted) return;
      setState(() {
        _lastSeenTitle = last.trim();
        _favoriteTitles =
            favList.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();
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

  Future<void> _removeFavoriteLocal(String title) async {
    final t = title.trim();
    if (t.isEmpty) return;

    final next = Set<String>.from(_favoriteTitles);
    next.remove(t);

    setState(() => _favoriteTitles = next);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefsFavKey, next.toList());
    } catch (_) {}
  }

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

  Future<void> _openSearch() async {
    final items = await _fetchOnceItems();
    if (!mounted) return;
    if (!context.mounted) return;
    showSearch(
      context: context,
      delegate: _FactSearchDelegate(
        items: items,
        onOpen: (title) async => _openTopic(title),
      ),
    );
  }

  // ✅ Favorites BottomSheet
  Future<void> _openFavoritesSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final favList = _favoriteTitles.toList();

            return SafeArea(
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Handle
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
                      const SizedBox(height: 14),

                      // Title
                      Row(
                        children: [
                          const Icon(Icons.bookmark_rounded,
                              size: 22, color: AppColors.secondaryOrange),
                          const SizedBox(width: 8),
                          Text(
                            "المفضلة",
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: AppColors.primaryDeepTeal,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            "${favList.length} موضوع",
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Content
                      if (favList.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Column(
                            children: [
                              Icon(Icons.bookmark_border_rounded,
                                  size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 12),
                              Text(
                                "لا توجد مواضيع في المفضلة الآن.",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "أضف مواضيع للمفضلة من داخل أي موضوع.",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11.5,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.5,
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const BouncingScrollPhysics(),
                            itemCount: favList.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final title = favList[index];
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: AppColors.primaryDeepTeal
                                        .withValues(alpha: 0.10),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  title: Text(
                                    title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.cairo(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      color: AppColors.primaryDeepTeal,
                                    ),
                                  ),
                                  trailing: IconButton(
                                    tooltip: "إزالة من المفضلة",
                                    icon: const Icon(
                                      Icons.bookmark_remove_rounded,
                                      color: AppColors.secondaryOrange,
                                      size: 22,
                                    ),
                                    onPressed: () async {
                                      await _removeFavoriteLocal(title);
                                      setSheetState(() {});
                                    },
                                  ),
                                  onTap: () async {
                                    Navigator.pop(context);
                                    await _openTopic(title);
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    // Refresh state after sheet closes
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
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _openSearch,
          ),
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
        child: _landingContent(),
      ),
    );
  }

  Widget _landingContent() {
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

        // ✅ Featured (ترشيحات L Pro)
        final now = DateTime.now();
        final featured = allItems
            .where((e) => e.isFeatured == true && e.isFeaturedValid(now))
            .toList();
        featured.sort((a, b) {
          final byOrder = a.featuredOrder.compareTo(b.featuredOrder);
          if (byOrder != 0) return byOrder;
          return b.createdAtMs.compareTo(a.createdAtMs);
        });

        // ✅ Recent (جديد L Pro)
        final recentCutoff =
            now.subtract(const Duration(days: _recentDaysWindow));
        final recent = allItems
            .where((e) =>
                e.createdAtMs > 0 &&
                DateTime.fromMillisecondsSinceEpoch(e.createdAtMs)
                    .isAfter(recentCutoff))
            .take(5)
            .toList();

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1️⃣ Intro Card (compact)
              _introCard(),

              const SizedBox(height: 14),

              // 2️⃣ Sections Button (Full width + prominent)
              _fullWidthButton(
                icon: Icons.category_outlined,
                label: 'تصفّح كل الأقسام',
                isPrimary: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FactSectionsScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 10),

              // 3️⃣ تابع من حيث توقفت (compact - same height as buttons)
              if (_lastSeenTitle.trim().isNotEmpty) ...[
                _lastSeenButton(),
                const SizedBox(height: 10),
              ],

              // 4️⃣ Favorites Button (Working!)
              _fullWidthButton(
                icon: Icons.bookmark_rounded,
                label: 'المفضلة',
                badge: _favoriteTitles.isNotEmpty
                    ? '${_favoriteTitles.length}'
                    : null,
                onTap: _openFavoritesSheet,
              ),

              const SizedBox(height: 16),

              // 5️⃣ جديد L Pro (last 5)
              if (recent.isNotEmpty) ...[
                _topicsCard(
                  title: 'جديد L Pro',
                  icon: Icons.new_releases_rounded,
                  items: recent.take(5).toList(),
                ),
                const SizedBox(height: 12),
              ],

              // 6️⃣ ترشيحات L Pro (last 5)
              if (featured.isNotEmpty) ...[
                _topicsCard(
                  title: 'ترشيحات L Pro',
                  icon: Icons.star_rounded,
                  items: featured.take(5).toList(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // ✅ Compact Intro Card
  Widget _introCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.primaryDeepTeal.withValues(alpha: 0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDeepTeal.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "بوابة المعلومة اللي بتفرق",
                  textAlign: TextAlign.right,
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    height: 1.3,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryDeepTeal,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "مواضيع قصيرة ومركزة، كل موضوع فيه معلومة عملية تقدر تطبقها فوراً.",
                  textAlign: TextAlign.right,
                  style: GoogleFonts.cairo(
                    fontSize: 11.5,
                    height: 1.6,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.secondaryOrange.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome,
                color: AppColors.secondaryOrange, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _fullWidthButton({
    required IconData icon,
    required String label,
    String? badge,
    bool isPrimary = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isPrimary
              ? AppColors.primaryDeepTeal.withValues(alpha: 0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isPrimary
                ? AppColors.primaryDeepTeal.withValues(alpha: 0.18)
                : AppColors.primaryDeepTeal.withValues(alpha: 0.10),
            width: isPrimary ? 1.2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isPrimary
                  ? AppColors.primaryDeepTeal.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primaryDeepTeal),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryDeepTeal,
                ),
              ),
            ),
            if (badge != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.secondaryOrange,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.cairo(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_ios,
                size: 14, color: AppColors.secondaryOrange),
          ],
        ),
      ),
    );
  }

  // ✅ Compact "تابع" button - same height as other buttons
  Widget _lastSeenButton() {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _openTopic(_lastSeenTitle),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppColors.secondaryOrange.withValues(alpha: 0.20)),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondaryOrange.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.history_rounded,
                size: 20, color: AppColors.secondaryOrange),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "تابع: $_lastSeenTitle",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDeepTeal,
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_ios,
                size: 14, color: AppColors.secondaryOrange),
          ],
        ),
      ),
    );
  }

  Widget _topicsCard({
    required String title,
    required IconData icon,
    required List<_FactTopicItem> items,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.primaryDeepTeal.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.secondaryOrange),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryDeepTeal,
                ),
              ),
            ],
          ),
          const Divider(height: 16, thickness: 0.5),
          ...items.map((item) => _verticalTopicRow(item)),
        ],
      ),
    );
  }

  Widget _verticalTopicRow(_FactTopicItem item) {
    return GestureDetector(
      onTap: () => _openTopic(item.title),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDeepTeal,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 11,
              color: Colors.black26,
            ),
          ],
        ),
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

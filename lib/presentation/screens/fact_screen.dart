// PATH: lib/presentation/screens/fact_screen.dart
// STATUS: Full File – Firestore Topics (pro_insight) + Fixed Sections Plan
//         + Favorites (SharedPreferences) + Last Seen Badge
//         + Tag Normalization (fix: "سيستم الشركة" => "سيستم الشركات")
//         + ✅ NEW: Top Blocks (Zero Cost): Featured "مختارات اليوم" + Recent "حديثًا"
//         + ✅ ADDED: Bottom Navigation Bar ONLY

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
  static const String _prefsLastSeenKey = 'pro_insight_last_seen_title';

  // ✅ Recent window (feel free to change later)
  static const int _recentDaysWindow = 7;

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
      final last = prefs.getString(_prefsLastSeenKey) ?? '';
      if (!mounted) return;
      setState(() {
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
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FactSectionsScreen(),
                        ),
                      );
                    },
                  ),
                  const Spacer(),
                  _PillButton(
                    icon: Icons.search,
                    label: 'بحث',
                    onTap: () async {
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.primaryDeepTeal.withValues(alpha: 0.12),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
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
                    fontSize: 14.5,
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
                    fontSize: 12.5,
                    height: 1.6,
                    fontWeight: FontWeight.w700,
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
              color: AppColors.secondaryOrange.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome,
                color: AppColors.secondaryOrange, size: 22),
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

        // ✅ Featured (ترشيحات Pro)
        final now = DateTime.now();
        final featured = allItems
            .where((e) => e.isFeatured == true && e.isFeaturedValid(now))
            .toList();
        featured.sort((a, b) {
          final byOrder = a.featuredOrder.compareTo(b.featuredOrder);
          if (byOrder != 0) return byOrder;
          return b.createdAtMs.compareTo(a.createdAtMs);
        });

        // ✅ Recent (جديد Pro)
        final recentCutoff =
            now.subtract(const Duration(days: _recentDaysWindow));
        final recent = allItems
            .where((e) =>
                e.createdAtMs > 0 &&
                DateTime.fromMillisecondsSinceEpoch(e.createdAtMs)
                    .isAfter(recentCutoff))
            .take(12)
            .toList();

        // Section preview lookup
        const String previewSectionName = 'البداية الصح';
        final previewItems = allItems
            .where((e) => e.tags.contains(_normalizeTag(previewSectionName)))
            .take(3)
            .toList();

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            children: [
              // ✅ تابع من حيث توقفت (single card)
              if (_lastSeenTitle.trim().isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                  child: GestureDetector(
                    onTap: () => _openTopic(_lastSeenTitle),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: AppColors.primaryDeepTeal
                                .withValues(alpha: 0.10)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.history_rounded,
                                  size: 16, color: AppColors.secondaryOrange),
                              const SizedBox(width: 6),
                              Text(
                                "تابع من حيث توقفت",
                                style: GoogleFonts.cairo(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _lastSeenTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryDeepTeal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
              ],

              // ✅ ترشيحات Pro
              if (featured.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color:
                              AppColors.primaryDeepTeal.withValues(alpha: 0.10)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                size: 18, color: AppColors.secondaryOrange),
                            const SizedBox(width: 8),
                            Text(
                              "ترشيحات Pro",
                              style: GoogleFonts.cairo(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primaryDeepTeal,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 16, thickness: 0.5),
                        const SizedBox(height: 4),
                        ...featured
                            .take(5)
                            .map((item) => _verticalTopicRow(item)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
              ],

              // ✅ جديد Pro
              if (recent.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color:
                              AppColors.primaryDeepTeal.withValues(alpha: 0.10)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.new_releases_rounded,
                                size: 18, color: AppColors.secondaryOrange),
                            const SizedBox(width: 8),
                            Text(
                              "جديد Pro",
                              style: GoogleFonts.cairo(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primaryDeepTeal,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 16, thickness: 0.5),
                        const SizedBox(height: 4),
                        ...recent.take(5).map((item) => _verticalTopicRow(item)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
              ],

              // ✅ Section preview (البداية الصح) with link to sections
              if (previewItems.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color:
                              AppColors.primaryDeepTeal.withValues(alpha: 0.10)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                previewSectionName,
                                style: GoogleFonts.cairo(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primaryDeepTeal,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const FactSectionsScreen(),
                                  ),
                                );
                              },
                              child: const Icon(
                                Icons.grid_view_rounded,
                                size: 20,
                                color: AppColors.secondaryOrange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...previewItems.map((item) => _verticalTopicRow(item)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
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
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDeepTeal,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 12,
              color: Colors.black26,
            ),
          ],
        ),
      ),
    );
  }

  // دالة الشريط السفلي
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
          border: Border.all(
              color: AppColors.primaryDeepTeal.withValues(alpha: 0.10)),
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

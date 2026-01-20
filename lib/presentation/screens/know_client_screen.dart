// PATH: lib/presentation/screens/know_client_screen.dart
// STATUS: Full File – ✅ Admin can see scheduled topics before publishAt, users only see published.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ✅ NEW
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import 'know_client_articles_screen.dart';

class KnowClientScreen extends StatefulWidget {
  const KnowClientScreen({super.key});

  @override
  State<KnowClientScreen> createState() => _KnowClientScreenState();
}

class _KnowClientScreenState extends State<KnowClientScreen> {
  static const String _collectionName = 'know_your_client';

  // ✅ أقسام ثابتة (خطة القسم) - الفلترة تعتمد على tags
  static const List<String> _sectionsPlan = [
    'كل المواضيع',
    'أساسيات العميل',
    'أنماط الشخصيات',
    'الدوافع والاحتياجات',
    'الاعتراضات والردود',
    'التفاوض',
    'إغلاق الصفقة',
    'متابعة وما بعد البيع',
  ];

  String _selectedSection = 'كل المواضيع';

  // ✅ Admin flag (from users/{uid}.isAdmin)
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _listenAdminFlag();
  }

  void _listenAdminFlag() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    FirebaseFirestore.instance.collection('users').doc(uid).snapshots().listen(
      (doc) {
        final data = doc.data();
        final isAdmin = (data?['isAdmin'] == true);
        if (mounted) {
          setState(() => _isAdmin = isAdmin);
        }
      },
      onError: (_) {},
    );
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
          'سيكولوجية القرار العقاري',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.cairo(fontWeight: FontWeight.w900, fontSize: 18),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            const SizedBox(height: 14),

            // ===== Header Row (Sections + Selected + Search) =====
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
                        delegate: _KnowClientSearchDelegate(items),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ===== Intro Card =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _introCard(),
            ),

            const SizedBox(height: 10),

            // ===== Topics List =====
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
            "العميل لا يشتري عقارًا… هو يشتري أمانًا أو هروبًا أو مكانة.",
            textAlign: TextAlign.right,
            style: GoogleFonts.cairo(
              fontSize: 12.8,
              height: 1.55,
              fontWeight: FontWeight.w900,
              color: AppColors.primaryDeepTeal,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "هنا هتفهم دوافعه، قلقه، اعتراضاته… وتعرف إمتى تقفل وإمتى تسيب القرار ينضج.",
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
            "حصل خطأ في تحميل المواضيع.\nراجع Rules أو أسماء الحقول.",
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

        final nowMs = DateTime.now().millisecondsSinceEpoch;

        final items = snap.data!.docs
            .map((d) => _KycTopicItem.fromDoc(d.id, d.data()))
            .where((e) {
          if (e.isActive != true) return false;
          if (e.title.trim().isEmpty) return false;

          // ✅ scheduled logic
          final isScheduledFuture =
              (e.publishAtMs > 0 && e.publishAtMs > nowMs);

          // user: hide scheduled
          // admin: show scheduled
          if (!_isAdmin && isScheduledFuture) return false;

          return true;
        }).toList();

        // ✅ ترتيب محلي حسب createdAt (الأحدث أولاً)
        items.sort((a, b) => b.createdAtMs.compareTo(a.createdAtMs));

        final filtered = _selectedSection == 'كل المواضيع'
            ? items
            : items.where((e) => e.tags.contains(_selectedSection)).toList();

        if (filtered.isEmpty) {
          return _centerMsg("لا توجد مواضيع في هذا القسم الآن.");
        }

        return ListView.separated(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = filtered[index];

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    // ✅ safer: open by docId
                    builder: (_) => KnowClientArticlesScreen(
                      docId: item.id,
                      title: item.title,
                    ),
                  ),
                );
              },
              child: _topicCard(item: item, index: index, nowMs: nowMs),
            );
          },
        );
      },
    );
  }

  Widget _topicCard({
    required _KycTopicItem item,
    required int index,
    required int nowMs,
  }) {
    final shadowTint = index.isEven
        ? AppColors.primaryDeepTeal.withValues(alpha: 0.08)
        : AppColors.secondaryOrange.withValues(alpha: 0.08);

    final isScheduledFuture =
        (item.publishAtMs > 0 && item.publishAtMs > nowMs);

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
          const Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: AppColors.secondaryOrange,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
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

                // ✅ Admin only badge for scheduled
                if (_isAdmin && isScheduledFuture) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryOrange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.secondaryOrange.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        "مجدول",
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: AppColors.secondaryOrange,
                        ),
                      ),
                    ),
                  ),
                ],
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

  Future<List<_KycTopicItem>> _fetchOnceItems() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection(_collectionName)
          .where('isActive', isEqualTo: true)
          .limit(900)
          .get();

      final nowMs = DateTime.now().millisecondsSinceEpoch;

      final items = snap.docs
          .map((d) => _KycTopicItem.fromDoc(d.id, d.data()))
          .where((e) {
        if (e.title.trim().isEmpty) return false;

        final isScheduledFuture = (e.publishAtMs > 0 && e.publishAtMs > nowMs);

        if (!_isAdmin && isScheduledFuture) return false;

        return true;
      }).toList();

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

class _KnowClientSearchDelegate extends SearchDelegate {
  final List<_KycTopicItem> items;
  _KnowClientSearchDelegate(this.items);

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
        child: Text(
          "لا نتائج.",
          style: GoogleFonts.cairo(fontWeight: FontWeight.w900),
        ),
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
          onTap: () {
            close(context, null);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => KnowClientArticlesScreen(
                  docId: item.id,
                  title: item.title,
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) => buildResults(context);
}

class _KycTopicItem {
  final String id;
  final String title;
  final int createdAtMs;
  final int publishAtMs; // ✅ NEW
  final List<String> tags;
  final bool isActive;

  _KycTopicItem({
    required this.id,
    required this.title,
    required this.createdAtMs,
    required this.publishAtMs,
    required this.tags,
    required this.isActive,
  });

  factory _KycTopicItem.fromDoc(String id, Map<String, dynamic> data) {
    final rawTags = data['tags'];
    final tags = <String>[];
    if (rawTags is List) {
      for (final t in rawTags) {
        final s = t.toString().trim();
        if (s.isNotEmpty) tags.add(s);
      }
    }

    int createdAtMs = 0;
    final ts = data['createdAt'];
    if (ts is Timestamp) createdAtMs = ts.millisecondsSinceEpoch;

    int publishAtMs = 0;
    final pub = data['publishAt'];
    if (pub is Timestamp) publishAtMs = pub.millisecondsSinceEpoch;

    return _KycTopicItem(
      id: id,
      title: (data['title'] ?? '').toString(),
      createdAtMs: createdAtMs,
      publishAtMs: publishAtMs,
      tags: tags,
      isActive: data['isActive'] == true,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/data/fact_articles_data.dart';
import '../../core/data/models/fact_article_model.dart';
import 'fact_articles_reader_screen.dart';

class FactScreen extends StatelessWidget {
  const FactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<FactArticle> articles = factArticles;

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF003D3D),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          'المعلومة بتفرق',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            const SizedBox(height: 16),

            /// ===== الهيدر الداخلي =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  /// زر الأقسام
                  _HeaderButton(
                    icon: Icons.category_outlined,
                    label: 'الأقسام',
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.white,
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(22)),
                        ),
                        builder: (_) => const _SectionsSheet(),
                      );
                    },
                  ),

                  const Spacer(),

                  /// اللوجو + الجملة (محاذاة دقيقة)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/icon2.png',
                        height: 42,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'بوابة المعرفة العقارية',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF003D3D),
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  /// زر البحث (نفس حجم الأقسام + يعمل)
                  _HeaderButton(
                    icon: Icons.search,
                    label: 'بحث',
                    onTap: () {
                      _openSearch(context, articles);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            /// ===== قائمة المواضيع =====
            Expanded(
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                itemCount: articles.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final article = articles[index];

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FactArticlesReaderScreen(
                            article: article,
                            articles: articles,
                            index: index,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: index.isEven
                                ? const Color(0xFF4FA8A8).withOpacity(0.12)
                                : const Color(0xFFFF8C00).withOpacity(0.10),
                            blurRadius: 14,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            article.title,
                            style: GoogleFonts.cairo(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF003D3D),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            article.hook,
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              height: 1.6,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ===== بحث يعمل فعليًا =====
  void _openSearch(BuildContext context, List<FactArticle> articles) {
    showSearch(
      context: context,
      delegate: _FactSearchDelegate(articles),
    );
  }
}

/// =======================================================
/// زر موحد (بحث / أقسام)
/// =======================================================
class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HeaderButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF003D3D)),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF003D3D),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// =======================================================
/// Search Delegate (بحث بالعنوان أو الهوك)
/// =======================================================
class _FactSearchDelegate extends SearchDelegate {
  final List<FactArticle> articles;
  _FactSearchDelegate(this.articles);

  @override
  String? get searchFieldLabel => 'ابحث عن معلومة…';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => query = '',
        ),
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
    final results = articles.where((a) {
      final q = query.toLowerCase();
      return a.title.toLowerCase().contains(q) ||
          a.hook.toLowerCase().contains(q);
    }).toList();

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final article = results[index];
        return ListTile(
          title: Text(article.title,
              style: GoogleFonts.cairo(fontWeight: FontWeight.w800)),
          subtitle: Text(article.hook, style: GoogleFonts.cairo(fontSize: 12)),
          onTap: () {
            close(context, null);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FactArticlesReaderScreen(
                  article: article,
                  articles: articles,
                  index: articles.indexOf(article),
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

/// =======================================================
/// BottomSheet الأقسام
/// =======================================================
class _SectionsSheet extends StatelessWidget {
  const _SectionsSheet();

  @override
  Widget build(BuildContext context) {
    final sections = [
      'كل المواضيع',
      'البداية الصح',
      'لغة العقارات',
      'تفكير بروكر',
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(height: 20),
          Text(
            'اختر القسم',
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF003D3D),
            ),
          ),
          const SizedBox(height: 12),
          ...sections.map(
            (s) => ListTile(
              title: Text(
                s,
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onTap: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/data/models/fact_article_model.dart';

class FactArticlesReaderScreen extends StatelessWidget {
  final FactArticle article;
  final List<FactArticle> articles;
  final int index;

  const FactArticlesReaderScreen({
    super.key,
    required this.article,
    required this.articles,
    required this.index,
  });

  bool get hasPrevious => index > 0;
  bool get hasNext => index < articles.length - 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF003D3D),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          article.title,
          style: GoogleFonts.cairo(fontWeight: FontWeight.w900),
        ),
        actions: const [
          Icon(Icons.share_outlined),
          SizedBox(width: 12),
          Icon(Icons.bookmark_border),
          SizedBox(width: 12),
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
                      _infoBox(article.hook),
                      const SizedBox(height: 16),

                      _sectionBox(
                        title: 'تصحيح المفهوم',
                        body: article.reset,
                      ),
                      const SizedBox(height: 16),

                      _sectionBox(
                        title: 'المعلومة اللي بتفرق',
                        body: article.insight,
                      ),
                      const SizedBox(height: 16),

                      _sectionBox(
                        title: 'مثال واقعي',
                        body: article.example,
                      ),
                      const SizedBox(height: 18),

                      _lockBox(article.lock),

                      const Spacer(),

                      /// ===== توقيع الصفحة (بعد لمسة الاتزان) =====
                      Column(
                        children: [
                          const SizedBox(height: 12),
                          Text(
                            'من يملك المعلومة يملك القوة',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF003D3D),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'المعلومة بتفرق',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFFFF8C00),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Image.asset(
                            'assets/icon2.png',
                            width: 64,
                            height: 64,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),

                      /// ===== أزرار التنقل (مثبتة) =====
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (hasPrevious)
                            _arrowButton(
                              icon: Icons.arrow_back_ios_new,
                              color: const Color(0xFF003D3D),
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FactArticlesReaderScreen(
                                      article: articles[index - 1],
                                      articles: articles,
                                      index: index - 1,
                                    ),
                                  ),
                                );
                              },
                            )
                          else
                            const SizedBox(width: 48),
                          IconButton(
                            icon: const Icon(Icons.grid_view_rounded),
                            color: const Color(0xFF003D3D),
                            iconSize: 26,
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                          if (hasNext)
                            _arrowButton(
                              icon: Icons.arrow_forward_ios,
                              color: const Color(0xFFFF8C00),
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FactArticlesReaderScreen(
                                      article: articles[index + 1],
                                      articles: articles,
                                      index: index + 1,
                                    ),
                                  ),
                                );
                              },
                            )
                          else
                            const SizedBox(width: 48),
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
          colors: [
            Color(0xFFEFF4F3),
            Color(0xFFFFF1E2),
          ],
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.cairo(
          fontSize: 14,
          fontWeight: FontWeight.w900,
          color: const Color(0xFF003D3D),
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
            color: Colors.black.withOpacity(0.05),
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
              color: const Color(0xFFFF8C00),
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
          colors: [
            Color(0xFFEFF4F3),
            Color(0xFFFFF1E2),
          ],
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.cairo(
          fontSize: 14,
          fontWeight: FontWeight.w900,
          color: const Color(0xFF003D3D),
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
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 20),
        onPressed: onTap,
      ),
    );
  }
}

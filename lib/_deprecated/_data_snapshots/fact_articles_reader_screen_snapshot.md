# Snapshot: lib/presentation/screens/fact_articles_reader_screen.dart
# Date: 2026-01-23

```dart
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
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
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hook Section
              if (article.hook.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4E6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFF8C00).withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: const Color(0xFFFF8C00),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          article.hook,
                          style: GoogleFonts.cairo(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF8B4513),
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Reset Section
              if (article.reset.isNotEmpty) ...[
                _buildSection(
                  title: "إعادة ضبط",
                  icon: Icons.refresh_rounded,
                  color: const Color(0xFF3498DB),
                  content: article.reset,
                ),
                const SizedBox(height: 20),
              ],

              // Core Section
              if (article.core.isNotEmpty) ...[
                _buildSection(
                  title: "الأساس",
                  icon: Icons.auto_awesome,
                  color: const Color(0xFF003D3D),
                  content: article.core,
                ),
                const SizedBox(height: 20),
              ],

              // Example Section
              if (article.example.isNotEmpty) ...[
                _buildSection(
                  title: "مثال",
                  icon: Icons.article_outlined,
                  color: const Color(0xFF2ECC71),
                  content: article.example,
                ),
                const SizedBox(height: 20),
              ],

              // Lock Section
              if (article.lock.isNotEmpty) ...[
                _buildSection(
                  title: "قفل",
                  icon: Icons.lock_outline,
                  color: const Color(0xFFE74C3C),
                  content: article.lock,
                ),
                const SizedBox(height: 20),
              ],

              // Article Body (if exists)
              if (article.body.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    article.body,
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      height: 1.8,
                      color: const Color(0xFF2C3E50),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: GoogleFonts.cairo(
              fontSize: 15,
              height: 1.7,
              color: const Color(0xFF2C3E50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _arrowButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

```

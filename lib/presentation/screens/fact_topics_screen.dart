import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/data/models/fact_article_model.dart';
import '../../core/data/fact_articles_data.dart';
import 'fact_articles_reader_screen.dart';

class FactTopicsScreen extends StatelessWidget {
  const FactTopicsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<FactArticle> topics = factArticles;

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        title: Text(
          'المعلومة بتفرق',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: topics.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final article = topics[index];

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FactArticlesReaderScreen(
                      article: article,
                      articles: topics,
                      index: index,
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title,
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF003D3D),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      article.hook,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
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
    );
  }
}

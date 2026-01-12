import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProInsightTopicsScreen extends StatelessWidget {
  const ProInsightTopicsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topics = [
      'السوق العقاري',
      'الشركات العقارية',
      'القوانين والإجراءات',
      'المشروعات',
      'أخطاء شائعة في السوق',
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        title: Text(
          'المعلومة بتفرق',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1A3A57),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: topics.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: Color(0xFFFF8C42),
                  size: 28,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    topics[index],
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF122C44),
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Color(0xFF4FA8A8),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

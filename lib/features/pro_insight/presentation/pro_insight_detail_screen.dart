import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/pro_insight_model.dart';

class ProInsightDetailScreen extends StatelessWidget {
  final ProInsightModel insight;

  const ProInsightDetailScreen({
    super.key,
    required this.insight,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المعلومة بتفرق'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= Hook =================
            _sectionCard(
              title: '⚡ الفكرة السريعة',
              content: insight.hook,
              highlight: true,
            ),

            // ================= Mind Reset =================
            _sectionCard(
              title: '🧠 تصحيح المفهوم',
              content: insight.mindReset,
            ),

            // ================= Core Insight =================
            _sectionCard(
              title: '🎯 جوهر المعلومة',
              content: insight.coreInsight,
            ),

            // ================= Reality Example =================
            if (insight.realityExample != null &&
                insight.realityExample!.isNotEmpty)
              _sectionCard(
                title: '🏢 من واقع السوق',
                content: insight.realityExample!,
              ),

            // ================= Mental Lock =================
            _sectionCard(
              title: '🔒 ثبتها في دماغك',
              content: insight.mentalLock,
              accent: true,
            ),

            const SizedBox(height: 24),

            // ================= CTA =================
            Center(
              child: Text(
                'كمّل… اللي جاي أهم 👌',
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF40E0D0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= Reusable Section Card =================
  Widget _sectionCard({
    required String title,
    required String content,
    bool highlight = false,
    bool accent = false,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlight ? const Color(0xFF1A3A57) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
        border: accent
            ? Border.all(
                color: const Color(0xFF40E0D0),
                width: 1.2,
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: highlight ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: GoogleFonts.cairo(
              fontSize: 13,
              height: 1.6,
              fontWeight: FontWeight.w600,
              color: highlight ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

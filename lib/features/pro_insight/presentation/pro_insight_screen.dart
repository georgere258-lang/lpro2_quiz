import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';

class ProInsightScreen extends StatelessWidget {
  const ProInsightScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "المعلومة بتفرق",
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.w900,
            color: const Color(0xFF003D3D),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ===== Intro Card (فلسفة القسم) =====
            _IntroCard(),

            const SizedBox(height: 26),

            /// ===== Placeholder for Topics =====
            Text(
              "أحدث المواضيع",
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF003D3D),
              ),
            ),

            const SizedBox(height: 14),

            _TopicPlaceholder(),
            _TopicPlaceholder(),
            _TopicPlaceholder(),
          ],
        ),
      ),
    );
  }
}

/* =========================================================
   INTRO CARD
========================================================= */

class _IntroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "المعلومة بتفرق 👌",
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF003D3D),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "القسم ده معمول علشان يبنيك صح.\n"
            "يفهمك السوق، الشركات، المشاريع، القوانين، والتفاصيل اللي بتصنع الفرق الحقيقي مع العميل.\n\n"
            "مش معلومات للحفظ… دي خبرة جاهزة للاستخدام.",
            style: GoogleFonts.cairo(
              fontSize: 14,
              height: 1.8,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2D3142),
            ),
          ),
        ],
      ),
    );
  }
}

/* =========================================================
   TOPIC PLACEHOLDER (مؤقت)
========================================================= */

class _TopicPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [
            Color(0xFF003D3D),
            Color(0xFF005F5F),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lightbulb_outline,
            color: AppColors.secondaryOrange,
            size: 26,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              "عنوان موضوع سيُضاف من لوحة التحكم",
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: Colors.white,
              ),
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: Colors.white70,
          ),
        ],
      ),
    );
  }
}

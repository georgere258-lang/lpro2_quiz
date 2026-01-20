// PATH: lib/presentation/screens/market_radar_screen.dart
// STATUS: Full File – Market Radar (static, zero cost) + premium cards

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';

class MarketRadarScreen extends StatelessWidget {
  const MarketRadarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        backgroundColor: AppColors.primaryDeepTeal,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          'Radar',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w900),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
          children: [
            _hero(),
            const SizedBox(height: 14),
            _card(
              title: "قاموس المصطلحات السريع",
              sub: "تفسير مصطلحات السوق بلهجة مصرية بسيطة.",
              child: const Column(
                children: [
                  _TermLine("التحميل",
                      "فرق المساحة الصافية عن الإجمالي (خدمات وممرات)."),
                  _TermLine("EOI", "حجز مبدئي لتثبيت السعر/الأولوية."),
                  _TermLine("سابقات أعمال",
                      "مشاريع اتنفذت قبل كده تثبت جدية المطور."),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _card(
              title: "مقارنة مناطق (مختصر)",
              sub: "محتوى ثابت كبداية — وهنبنيه لاحقًا على بياناتك.",
              child: const Column(
                children: [
                  _AreaLine("التجمع", "سكني/إيجاري قوي + خدمات مكتملة."),
                  _AreaLine("العاصمة", "عائد رأسمالي محتمل + مراحل نمو."),
                  _AreaLine("زايد", "طلب ثابت + شرائح متنوعة."),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _card(
              title: "اختبار نية الشراء (سريع)",
              sub: "5 أسئلة تساعدك تعرف عميل جد ولا بيجرب.",
              child: const Column(
                children: [
                  _Bullet("ميزانيتك النهائية كام (مع المقدم)؟"),
                  _Bullet("التسليم مهم ولا الاستثمار؟"),
                  _Bullet("عندك قرار نهائي ولا في شريك؟"),
                  _Bullet("مقارنة بإيه شايف السعر غالي؟"),
                  _Bullet("الخطوة الجاية: زيارة ولا عرض واتساب؟"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hero() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [
            AppColors.primaryDeepTeal.withValues(alpha: 0.10),
            AppColors.secondaryOrange.withValues(alpha: 0.10),
          ],
        ),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
      ),
      child: Row(
        children: [
          const Icon(Icons.radar, color: AppColors.secondaryOrange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Radar السوق — معلومات سريعة جاهزة تستخدمها قدّام العميل.",
              textAlign: TextAlign.right,
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.w900,
                height: 1.6,
                color: AppColors.primaryDeepTeal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({
    required String title,
    required String sub,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primaryDeepTeal.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            textAlign: TextAlign.right,
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: AppColors.primaryDeepTeal,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            sub,
            textAlign: TextAlign.right,
            style: GoogleFonts.cairo(
              fontSize: 12,
              height: 1.6,
              fontWeight: FontWeight.w700,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _TermLine extends StatelessWidget {
  final String k;
  final String v;
  const _TermLine(this.k, this.v);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const Icon(Icons.label_important_outline,
              size: 18, color: AppColors.secondaryOrange),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              textDirection: TextDirection.rtl,
              text: TextSpan(
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w800,
                  height: 1.6,
                  color: const Color(0xFF2D3142),
                ),
                children: [
                  TextSpan(
                    text: "$k: ",
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryDeepTeal,
                    ),
                  ),
                  TextSpan(text: v),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AreaLine extends StatelessWidget {
  final String k;
  final String v;
  const _AreaLine(this.k, this.v);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const Icon(Icons.place_outlined,
              size: 18, color: AppColors.primaryDeepTeal),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              textDirection: TextDirection.rtl,
              text: TextSpan(
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w800,
                  height: 1.6,
                  color: const Color(0xFF2D3142),
                ),
                children: [
                  TextSpan(
                    text: "$k: ",
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w900,
                      color: AppColors.secondaryOrange,
                    ),
                  ),
                  TextSpan(text: v),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 8, color: Colors.black54),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              textAlign: TextAlign.right,
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.w800,
                height: 1.6,
                color: const Color(0xFF2D3142),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

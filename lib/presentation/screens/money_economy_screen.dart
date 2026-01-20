import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';

class MoneyEconomyScreen extends StatelessWidget {
  const MoneyEconomyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFDFBF7),
        appBar: AppBar(
          backgroundColor: AppColors.primaryDeepTeal,
          title: Text(
            "لغة المال",
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Intro Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF9B59B6).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.attach_money_rounded,
                          color: Color(0xFF9B59B6),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "لغة المال",
                          style: GoogleFonts.cairo(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF003D3D),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "اقتصاد، بنوك، بورصة، وأخبار... وكلها مترجمة مباشرة لتوقيت وقرار الشراء العقاري.",
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      height: 1.6,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Section Title
            Text(
              "المواضيع",
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF003D3D),
              ),
            ),

            const SizedBox(height: 12),

            // Placeholder Topics
            const _TopicRow(
              title: "اقتصاد كلي",
              subtitle: "كيف تقرأ المؤشرات الاقتصادية وتأثيرها على العقار",
              icon: Icons.trending_up_rounded,
            ),
            const _TopicRow(
              title: "بنوك وفوائد",
              subtitle: "فهم أسعار الفائدة والتمويل العقاري",
              icon: Icons.account_balance_rounded,
            ),
            const _TopicRow(
              title: "أخبار اقتصادية",
              subtitle: "آخر الأخبار المؤثرة على السوق العقاري",
              icon: Icons.newspaper_rounded,
            ),
            const _TopicRow(
              title: "بورصة",
              subtitle: "العلاقة بين البورصة والاستثمار العقاري",
              icon: Icons.candlestick_chart_rounded,
            ),
            const _TopicRow(
              title: "العقار والاقتصاد",
              subtitle: "كيف يؤثر كل ذلك على العقار ويؤثر العقار عليه",
              icon: Icons.home_work_rounded,
            ),
          ],
        ),
      ),
    );
  }
}

class _TopicRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _TopicRow({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF9B59B6).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF9B59B6), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF003D3D),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black45,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 16,
            color: Colors.black26,
          ),
        ],
      ),
    );
  }
}

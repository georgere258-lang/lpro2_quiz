import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/pro_insight_service.dart';

class ProInsightListScreen extends StatelessWidget {
  const ProInsightListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ProInsightService service = ProInsightService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('المعلومة بتفرق'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<ProInsightModel>>(
        future: service.getActiveInsights(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('حدث خطأ أثناء تحميل المحتوى'),
            );
          }

          final insights = snapshot.data ?? [];

          if (insights.isEmpty) {
            return const Center(
              child: Text('لا توجد معلومات متاحة حالياً'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: insights.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final insight = insights[index];

              return GestureDetector(
                onTap: () {
                  // 👈 هنا هنفتح شاشة التفاصيل بعدين (الخطوة الجاية)
                },
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF122C44), // كحلي التطبيق
                        Color(0xFF1A3A57),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        insight.hook,
                        style: GoogleFonts.cairo(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: Color(0xFF40E0D0), // فيروزي
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'افتح المعلومة',
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF40E0D0),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

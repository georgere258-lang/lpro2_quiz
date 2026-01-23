import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'fact_topics_screen.dart';

class FactStagesScreen extends StatelessWidget {
  const FactStagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stages = [
      {
        "key": "stage_1",
        "title": "البداية الصح",
        "desc": "تفهم المجال قبل ما تبيع",
      },
      {
        "key": "stage_2",
        "title": "لغة العقارات",
        "desc": "مصطلحات لازم تفهمها",
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text("خريطة الرحلة",
            style: GoogleFonts.cairo(fontWeight: FontWeight.w900)),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: stages.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final stage = stages[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FactTopicsScreen(
                    stageKey: stage["key"]!,
                    stageTitle: stage["title"]!,
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stage["title"]!,
                      style: GoogleFonts.cairo(
                          fontSize: 15, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text(stage["desc"]!,
                      style: GoogleFonts.cairo(
                          fontSize: 13, color: Colors.grey[700])),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

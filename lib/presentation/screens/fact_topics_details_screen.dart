import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FactTopicsDetailsScreen extends StatelessWidget {
  final String title;

  const FactTopicsDetailsScreen({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        title: Text(
          title,
          style: GoogleFonts.cairo(fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
      ),
      body: const Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              _HookCard(
                text:
                    "أغلب الصفقات اللي بتضيع…\nمش بسبب السعر\nلكن بسبب طريقة الكلام عنه.",
              ),
              SizedBox(height: 22),
              _InsightCard(
                title: "تصحيح المفهوم",
                content: "العميل لما يقول «غالي»\nهو مش بيرفض\nهو بيختبر فهمك.",
              ),
              _InsightCard(
                title: "المعلومة اللي بتفرق",
                content:
                    "في فرق بين اللي يقنع\nواللي يفهم.\nالبيع يبدأ بعد أول اعتراض.",
                highlight: true,
              ),
              _InsightCard(
                title: "من أرض الواقع",
                content:
                    "الهاوي يدافع عن السعر.\nالمحترف يسأل: غالي مقارنة بإيه؟",
              ),
              SizedBox(height: 24),
              _LockCard(
                text: "🔒 ثبّت في دماغك:\nالبيع مش إقناع… البيع فهم.",
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ================= Widgets ================= */

class _HookCard extends StatelessWidget {
  final String text;
  const _HookCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF003D3D).withOpacity(0.10),
            const Color(0xFFFF8C00).withOpacity(0.12),
          ],
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.cairo(
          fontSize: 15,
          fontWeight: FontWeight.w900,
          color: const Color(0xFF003D3D),
          height: 1.6,
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String title;
  final String content;
  final bool highlight;

  const _InsightCard({
    required this.title,
    required this.content,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: highlight
            ? const Color(0xFF003D3D).withOpacity(0.06)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
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
            content,
            style: GoogleFonts.cairo(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.7,
              color: const Color(0xFF003D3D),
            ),
          ),
        ],
      ),
    );
  }
}

class _LockCard extends StatelessWidget {
  final String text;
  const _LockCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFF003D3D),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.cairo(
          fontSize: 14,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          height: 1.6,
        ),
      ),
    );
  }
}

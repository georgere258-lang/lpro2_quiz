import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  final Color deepTeal = const Color(0xFF1B4D57);
  final Color safetyOrange = const Color(0xFFE67E22);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F8),
      appBar: AppBar(
        backgroundColor: deepTeal,
        elevation: 0,
        title: Text(
          "حول أبطال Pro",
          style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: Column(
            children: [
              // شعار البرنامج
              Center(
                child: Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    color: deepTeal,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: deepTeal.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10))
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Image.asset(
                      'assets/top_brand.png',
                      errorBuilder: (c, e, s) => const Icon(
                        Icons.stars_rounded,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // العنوان الرئيسي (تم استبداله بجملة المعلومة بتفرق كما طلبتي)
              Text(
                "المعلومة بتفرق",
                style: GoogleFonts.cairo(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: safetyOrange,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                "من يملك المعلومة يملك القوة",
                style: GoogleFonts.cairo(
                    fontSize: 15, fontWeight: FontWeight.bold, color: deepTeal),
              ),
              const SizedBox(height: 40),

              // رؤيتنا (تم حذف أبطال برو من العنوان)
              _buildAboutCard(
                "رؤيتنا",
                "نهدف إلى خلق مجتمع من نخبة المستشارين العقاريين (أبطال Pro). نحن نؤمن أن السوق العقاري يعتمد على المعلومة الصادقة والذكاء في التنفيذ، ودورنا هو تمكينك لتكون البطل في مجالك.",
                Icons.emoji_events_outlined,
              ),
              const SizedBox(height: 20),

              // الإصدار (تم حذف أبطال برو من العنوان)
              _buildAboutCard(
                "الإصدار",
                "نسخة بريميوم 1.0.0\nمخصص للنخبة العقارية 2026",
                Icons.verified_user_outlined,
              ),

              const SizedBox(height: 60),
              Text(
                "جميع الحقوق محفوظة لأبطال Pro © 2026",
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAboutCard(String title, String content, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: safetyOrange, size: 28),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: deepTeal,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  content,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: Colors.black87,
                    height: 1.7,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

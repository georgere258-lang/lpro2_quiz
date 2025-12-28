import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});
  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  // --- ميثاق ألوان باكدج 3 المعتمد (LPro Deep Teal) ---
  static const Color deepTeal = Color(0xFF005F6B);     // اللون القائد
  static const Color safetyOrange = Color(0xFFFF8C00); // لون الأكشن والمثلث (10%)
  static const Color iceWhite = Color(0xFFF8F9FA);     // الخلفية الأساسية (60%)
  static const Color darkTealText = Color(0xFF002D33); // نصوص العناوين

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: iceWhite,
      appBar: AppBar(
        backgroundColor: deepTeal, 
        elevation: 0, 
        centerTitle: true,
        automaticallyImplyLeading: false, // الهوم وراها فمش محتاجين سهم رجوع هنا
        title: Text(
          "دوري وحوش العقارات", 
          style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // [تثبيت]: الأيقونة باللون البرتقالي (لون المثلث الأصلي)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: safetyOrange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.psychology_outlined, size: 100, color: safetyOrange),
              ),
              
              const SizedBox(height: 35),
              
              // [المطلوب]: الجملة التحفيزية القوية
              Text(
                "جاهزة لإثبات سيطرتكِ يا مريم؟", 
                style: GoogleFonts.cairo(
                  fontSize: 24, 
                  fontWeight: FontWeight.bold, 
                  color: darkTealText,
                  height: 1.2,
                )
              ),
              
              const SizedBox(height: 15),
              
              // [المطلوب]: نص وصفي تحفيزي
              Text(
                "اختبري ذكاءكِ العقاري الآن، اجمعي النقاط وتصدري قائمة الخبراء في LPro.", 
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 15, 
                  color: const Color(0xFF4A4A4A),
                  height: 1.5,
                )
              ),
              
              const SizedBox(height: 50),
              
              // [المطلوب]: زر الأكشن الرئيسي باللون البرتقالي الصارخ
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // الانتقال لصفحة الأسئلة QuizPlayScreen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: safetyOrange, 
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    elevation: 6,
                    shadowColor: safetyOrange.withOpacity(0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                  ),
                  child: Text(
                    "ابدأ التحدي الآن", 
                    style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold)
                  ),
                ),
              ),
              
              const SizedBox(height: 25),
              
              // لمحة إحصائية بسيطة
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline, size: 16, color: deepTeal),
                  const SizedBox(width: 8),
                  Text(
                    "التحدي يحتوي على 10 أسئلة سريعة",
                    style: GoogleFonts.cairo(color: deepTeal.withOpacity(0.6), fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MasterPlanScreen extends StatefulWidget {
  const MasterPlanScreen({super.key});

  @override
  State<MasterPlanScreen> createState() => _MasterPlanScreenState();
}

class _MasterPlanScreenState extends State<MasterPlanScreen> {
  static const Color deepTeal = Color(0xFF1B4D57);
  static const Color safetyOrange = Color(0xFFE67E22);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text("تحدي الماستر بلان", style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        backgroundColor: deepTeal,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. منطقة عرض الخريطة (السؤال)
            Container(
              margin: const EdgeInsets.all(20),
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                image: const DecorationImage(
                  // هنا نضع صورة الماستر بلان (مثلاً مشروع في التجمع أو الإدارية)
                  image: AssetImage('assets/top_brand.png'), // استبدليها بصورة خريطة لاحقاً
                  fit: BoxFit.contain,
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "بناءً على المخطط الموضح، ما هو اسم هذا المشروع العقاري؟",
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: deepTeal),
              ),
            ),
            
            const SizedBox(height: 30),

            // 2. قائمة الخيارات (تحدي الماستر بلان)
            _buildOption("مشروع مدينتي - طلعت مصطفى"),
            _buildOption("ماونتن فيو iCity"),
            _buildOption("ميفيدا - إعمار مصر"),
            _buildOption("بادية - بالم هيلز"),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ودجت بناء زر الخيار
  Widget _buildOption(String text) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: deepTeal,
          padding: const EdgeInsets.symmetric(vertical: 15),
          side: const BorderSide(color: deepTeal, width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        onPressed: () {
          // منطق التحقق من الإجابة سنبرمجه لاحقاً
        },
        child: Text(text, style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
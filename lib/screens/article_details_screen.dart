import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ArticleDetailsScreen extends StatelessWidget {
  final String title;
  final String content;

  // --- ميثاق ألوان باكدج 3 المعتمد (LPro Deep Teal) ---
  static const Color deepTeal = Color(0xFF005F6B);     // اللون القائد
  static const Color iceWhite = Color(0xFFF8F9FA);     // الخلفية
  static const Color darkTealText = Color(0xFF002D33); // نصوص العناوين
  static const Color bodyGray = Color(0xFF4A4A4A);     // نصوص المحتوى الطويل

  const ArticleDetailsScreen({
    super.key, 
    required this.title, 
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: iceWhite,
      appBar: AppBar(
        title: Text(
          "المكتبة العقارية", 
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18)
        ),
        backgroundColor: deepTeal,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // العنوان الرئيسي باللون الفيروزي الداكن
            Text(
              title,
              style: GoogleFonts.cairo(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: darkTealText,
                height: 1.4,
              ),
            ),
            
            const SizedBox(height: 15),
            
            // فاصل بلمحة فيروزية خفيفة لتمييز العنوان عن المحتوى
            Divider(color: deepTeal.withOpacity(0.2), thickness: 1),
            
            const SizedBox(height: 20),
            
            // نص المقال: تم ضبط المسافات والخط لضمان أقصى درجات التركيز
            Text(
              content,
              style: GoogleFonts.cairo(
                fontSize: 17,
                height: 1.8,
                color: bodyGray,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.justify,
            ),
            
            const SizedBox(height: 60),
            
            // تذييل الهوية البصرية
            Center(
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 2,
                    color: deepTeal.withOpacity(0.1),
                  ),
                  const SizedBox(height: 10),
                  Opacity(
                    opacity: 0.3,
                    child: Text(
                      "LPro Real Estate Academy",
                      style: GoogleFonts.poppins(
                        fontSize: 10, 
                        fontWeight: FontWeight.w600, 
                        color: deepTeal,
                        letterSpacing: 1.2
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
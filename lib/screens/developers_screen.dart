import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DevelopersScreen extends StatelessWidget {
  const DevelopersScreen({super.key});

  // --- ميثاق ألوان باكدج 3 المعتمد (LPro Deep Teal) ---
  static const Color deepTeal = Color(0xFF005F6B);     // اللون القائد
  static const Color safetyOrange = Color(0xFFFF8C00); // لون الأكشن (10%)
  static const Color iceWhite = Color(0xFFF8F9FA);     // الخلفية (60%)
  static const Color darkTealText = Color(0xFF002D33); // نصوص العناوين

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: iceWhite,
      appBar: AppBar(
        title: Text(
          "المطورين العقاريين",
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: deepTeal,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
        itemCount: 8, // عدد افتراضي للشركات المطورة
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: deepTeal.withOpacity(0.06)),
              boxShadow: [
                BoxShadow(
                  color: deepTeal.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: safetyOrange.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.business_rounded, color: safetyOrange, size: 28),
              ),
              title: Text(
                "شركة العقارات المطورة ${index + 1}",
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold, 
                  color: darkTealText,
                  fontSize: 16,
                  height: 1.2,
                ),
              ),
              subtitle: Text(
                "سابقة أعمال قوية ومشاريع قائمة", 
                style: GoogleFonts.cairo(color: const Color(0xFF6C757D), fontSize: 12),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios_rounded, 
                color: deepTeal.withOpacity(0.25), 
                size: 16,
              ),
              onTap: () {
                // الانتقال إلى صفحة تفاصيل المطور ومشاريعة
              },
            ),
          );
        },
      ),
    );
  }
}
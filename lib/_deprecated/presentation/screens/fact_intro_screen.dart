import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'fact_stages_screen.dart';

class FactIntroScreen extends StatelessWidget {
  const FactIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                /// ===== Title =====
                Text(
                  "المعلومة بتفرق",
                  style: GoogleFonts.cairo(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF003D3D),
                  ),
                ),

                const SizedBox(height: 16),

                /// ===== Story Card =====
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        const Color(0xFF003D3D).withValues(alpha: 0.10),
                        const Color(0xFFFF8C00).withValues(alpha: 0.12),
                      ],
                    ),
                  ),
                  child: Text(
                    "في العقارات...\n"
                    "ناس كتير بتدخل المجال وهي فاكرة إن النجاح صدفة.\n\n"
                    "لكن الحقيقة إن أي حد نجح، كان فاهم:\n"
                    "السوق • اللغة • الشركات • القواعد • التوقيت.\n\n"
                    "الفشل مش عيب.\n"
                    "العيب إنك تفضل تايه من غير خريطة.",
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      height: 1.7,
                      color: const Color(0xFF003D3D),
                    ),
                  ),
                ),

                const Spacer(),

                /// ===== Action Button =====
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8C00),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 4,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FactStagesScreen(),
                        ),
                      );
                    },
                    child: Text(
                      "ابدأ الرحلة",
                      style: GoogleFonts.cairo(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

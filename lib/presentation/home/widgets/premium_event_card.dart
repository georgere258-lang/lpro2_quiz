import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// ✅ تم تعديل المسار لضمان اختفاء اللون الأحمر
import '../../../core/constants/app_colors.dart';

class PremiumEventCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const PremiumEventCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 65,
        decoration: BoxDecoration(
          // ✅ لون "Pearl Premium" (الأبيض اللؤلؤي) المعتمد
          gradient: const LinearGradient(
            colors: [Colors.white, Color(0xFFF9F9F9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(18),
          // ✅ الإطار الذهبي المعتمد لزيادة الفخامة
          border: Border.all(color: const Color(0xFFD4AF37), width: 1.3),
          boxShadow: [
            // ✅ الـ Glow الذهبي الخفيف المعتمد
            BoxShadow(
              color: const Color(0xFFD4AF37).withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              left: -5,
              top: -15,
              child: Icon(Icons.star_rounded,
                  size: 80, color: const Color(0xFFD4AF37).withOpacity(0.08)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Stack(
                children: [
                  // 1. النصوص في أقصى اليمين (Alignment.centerRight) لتناسق باقي الكروت
                  Align(
                    alignment: Alignment.centerRight,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: GoogleFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                // ✅ العنوان باللون البرتقالي
                                color: AppColors.secondaryOrange)),
                        Transform.translate(
                          offset: const Offset(0, -2),
                          child: Text(subtitle,
                              style: GoogleFonts.cairo(
                                  fontSize: 10,
                                  // ✅ الوصف بلون التيل
                                  color: const Color(0xFF1B4D57),
                                  fontWeight: FontWeight.w900)),
                        ),
                      ],
                    ),
                  ),
                  // 2. القفل والسلسلة في منتصف الكارت تماماً (Alignment.center)
                  Align(
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.link_rounded,
                            color: const Color(0xFFD4AF37).withOpacity(0.6),
                            size: 18),
                        const SizedBox(width: 4),
                        // ✅ القفل باللون البرتقالي للتشويق
                        Icon(Icons.enhanced_encryption_rounded,
                            color: AppColors.secondaryOrange, size: 24),
                        const SizedBox(width: 4),
                        Icon(Icons.link_rounded,
                            color: const Color(0xFFD4AF37).withOpacity(0.6),
                            size: 18),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // ✅ الحفاظ على مكان الـ Featured Badge
            Positioned(
              top: 8,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37),
                    borderRadius: BorderRadius.circular(4)),
                child: Text("FEATURED",
                    style: GoogleFonts.cairo(
                        fontSize: 7,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

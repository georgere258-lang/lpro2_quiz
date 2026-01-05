import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

class InfoCardWidget extends StatelessWidget {
  final String content;

  const InfoCardWidget({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    // نستخدم Directionality لضمان محاذاة كل شيء لليمين
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: AppColors.primaryDeepTeal.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // الهيدر العلوي - نفس روح "اعرف عميلك"
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryDeepTeal, Color(0xFF006D77)],
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.tips_and_updates_rounded,
                      color: AppColors.secondaryOrange,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "معلومة بتفرق",
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              // منطقة النص
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                color: Colors.white,
                child: Text(
                  content,
                  textAlign: TextAlign.right, // النص يبدأ دائماً من اليمين
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    height: 1.7, // مسافة بين السطور لسهولة القراءة
                    color: const Color(0xFF2D3142),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // لمسة جمالية في الأسفل (اختياري)
              Container(
                height: 4,
                width: 60,
                margin: const EdgeInsets.only(right: 20, bottom: 15),
                decoration: BoxDecoration(
                  color: AppColors.secondaryOrange,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

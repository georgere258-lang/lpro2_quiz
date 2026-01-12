import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';

class SectionIdentityCard extends StatelessWidget {
  final String sectionKey;
  final IconData icon;
  final String title;
  final String description;
  final List<String> benefits;

  const SectionIdentityCard({
    super.key,
    required this.sectionKey,
    required this.icon,
    required this.title,
    required this.description,
    required this.benefits,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryDeepTeal.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDeepTeal.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header القسم - يعبر عن الهوية البصرية للقسم
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.primaryDeepTeal.withOpacity(0.04),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.secondaryOrange, size: 26),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: AppColors.primaryDeepTeal,
                  ),
                ),
              ],
            ),
          ),

          // محتوى التعريف الثابت
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    height: 1.6,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 18),
                // قائمة الفوائد والتمكين
                ...benefits.map((benefit) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            child: const Icon(Icons.stars_rounded,
                                size: 18, color: AppColors.secondaryOrange),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              benefit,
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                color: Colors.grey[800],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

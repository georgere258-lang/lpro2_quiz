import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class InsightFooter extends StatelessWidget {
  const InsightFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primaryDeepTeal.withValues(alpha: 0.08),
            AppColors.secondaryOrange.withValues(alpha: 0.06),
          ],
        ),
      ),
      child: Text(
        'المعلومة دي مش نهاية… دي بداية وعي جديد.',
        textAlign: TextAlign.center,
        style: GoogleFonts.cairo(
          fontSize: 12.5,
          height: 1.6,
          fontWeight: FontWeight.w900,
          color: AppColors.primaryDeepTeal,
        ),
      ),
    );
  }
}

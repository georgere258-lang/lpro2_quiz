import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lpro2_quiz/core/constants/app_colors.dart';

class InfoCardWidget extends StatefulWidget {
  final String text;
  final VoidCallback? onRead;

  const InfoCardWidget({
    super.key,
    required this.text,
    this.onRead,
  });

  @override
  State<InfoCardWidget> createState() => _InfoCardWidgetState();
}

class _InfoCardWidgetState extends State<InfoCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    // إعداد أنميشن النبض (تتحرك الأيقونة وتلمع باستمرار)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF003D3D).withValues(alpha: 0.08),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF003D3D).withValues(alpha: 0.06),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ===== Slim Elegant Header with Animated Icon =====
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [Color(0xFF003D3D), Color(0xFF005F5F)],
                ),
              ),
              child: Row(
                children: [
                  // الأيقونة النابضة (Animated Pulse)
                  ScaleTransition(
                    scale: Tween(begin: 1.0, end: 1.2).animate(
                      CurvedAnimation(
                          parent: _pulseController, curve: Curves.easeInOut),
                    ),
                    child: FadeTransition(
                      opacity:
                          Tween(begin: 0.7, end: 1.0).animate(_pulseController),
                      child: const Icon(
                        Icons.tips_and_updates_rounded,
                        color: AppColors.secondaryOrange,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "معلومة Pro",
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  const Text("✨", style: TextStyle(fontSize: 12)),
                ],
              ),
            ),

            /// ===== Content Section =====
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white,
                    const Color(0xFFFDFBF7).withValues(alpha: 0.3)
                  ],
                ),
              ),
              child: Text(
                widget.text,
                textAlign: TextAlign.right,
                style: GoogleFonts.cairo(
                  fontSize: 15.5,
                  height: 1.85,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2D3142),
                ),
              ),
            ),

            /// ===== Premium Interactive Button =====
            if (widget.onRead != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onRead,
                    borderRadius: BorderRadius.circular(16),
                    child: Ink(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F4F0),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.secondaryOrange.withValues(alpha: 0.35),
                          width: 1.2,
                        ),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.verified_rounded,
                                color: AppColors.secondaryOrange, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              "استوعبت المعلومة",
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.w900,
                                color: AppColors.secondaryOrange,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

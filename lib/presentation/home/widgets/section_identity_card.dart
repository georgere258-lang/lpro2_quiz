// PATH: lib/presentation/home/widgets/section_identity_card.dart

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

  bool get _isStars =>
      sectionKey.contains("النجوم") || title.contains("النجوم");
  bool get _isPro =>
      sectionKey.contains("المحترفين") || title.contains("المحترفين");

  String get _badgeText {
    if (_isStars) return "FRESH";
    if (_isPro) return "PRO";
    return "LPRO";
  }

  String get _badgeEmoji {
    if (_isStars) return "✨";
    if (_isPro) return "🔥";
    return "⭐";
  }

  Color get _badgeColor {
    if (_isStars) return const Color(0xFF3498DB);
    if (_isPro) return AppColors.secondaryOrange;
    return const Color(0xFF4FA8A8);
  }

  String get _headline {
    if (_isStars) return "إنت لسه بتبني رجلك… متستعجلش.";
    if (_isPro) return "المحترف مش اللي بيع أكتر… اللي بيغلط أقل.";
    return "خُد خطوة ثابتة… وكمّل صح.";
  }

  String get _subLine {
    if (_isStars) return "تثبيت أساسك قبل ما السوق يكسرك.";
    if (_isPro) return "مش حفظ… ده تركيز ومسؤولية.";
    return "تعلم • تطور • نجاح";
  }

  @override
  Widget build(BuildContext context) {
    final border = AppColors.primaryDeepTeal.withOpacity(0.12);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          children: [
            // ===== Header Premium =====
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    AppColors.primaryDeepTeal.withOpacity(0.08),
                    _badgeColor.withOpacity(0.10),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child:
                        Icon(icon, color: AppColors.primaryDeepTeal, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: AppColors.primaryDeepTeal,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _subLine,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            height: 1.2,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDeepTeal.withOpacity(0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _Badge(
                    color: _badgeColor,
                    text: _badgeText,
                    emoji: _badgeEmoji,
                  ),
                ],
              ),
            ),

            // ===== Body =====
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Headline (روح الدوري)
                  Text(
                    _headline,
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      height: 1.6,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryDeepTeal,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Description (من النداء اللي بيجي من برا)
                  Text(
                    description,
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      height: 1.75,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Divider خفيف
                  Container(
                    height: 1,
                    width: double.infinity,
                    color: AppColors.primaryDeepTeal.withOpacity(0.08),
                  ),

                  const SizedBox(height: 14),

                  // Benefits
                  ...benefits.map(
                    (benefit) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 3),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: _badgeColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _badgeColor.withOpacity(0.25),
                              ),
                            ),
                            child: Icon(
                              Icons.stars_rounded,
                              size: 14,
                              color: _badgeColor,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              benefit,
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                height: 1.6,
                                color: Colors.grey[800],
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Accent line
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDeepTeal.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.primaryDeepTeal.withOpacity(0.10),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_rounded,
                            size: 18, color: AppColors.secondaryOrange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "هدفنا: تثبيت فهمك… قبل ما نحسب نقاطك.",
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              height: 1.4,
                              fontWeight: FontWeight.w800,
                              color:
                                  AppColors.primaryDeepTeal.withOpacity(0.85),
                            ),
                          ),
                        ),
                      ],
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

class _Badge extends StatelessWidget {
  final Color color;
  final String text;
  final String emoji;

  const _Badge({
    required this.color,
    required this.text,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 11)),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.cairo(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

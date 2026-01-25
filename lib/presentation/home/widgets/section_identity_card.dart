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
    if (_isStars) return "اجمع نقاطك واستعد لمفاجآت قادمة 🎯\nلكن خليك فاكر:\nالتطور الحقيقي مش بالنقاط بس…\nالتطور يبدأ بالاستمرارية، الفهم، وبناء الأساس الصح.";
    if (_isPro) return "اجمع نقاطك بقوة واستنى مفاجآت قادمة 🚀\nإنت مش جديد على السوق.\nإنت محترف… والمعلومة هي ثروتك الحقيقية.\nالاحتراف مش إنك تعرف معلومة،\nالاحتراف إن خيوط المعلومة كلها تكون في إيدك.";
    return "خُد خطوة ثابتة… وكمّل صح.";
  }

  String get _subLine {
    if (_isStars) return "بداية الطريق الصح";
    if (_isPro) return "مستوى Pro";
    return "تعلم • تطور • نجاح";
  }
  
  String get _structuredLine {
    if (_isPro) return "سوق • عميل • توقيت • قرار";
    return "";
  }
  
  String get _footerLine {
    if (_isStars) return "تعلم مستمر ◀️ تطور كبير ◀️ نجاح أكيد 💪";
    if (_isPro) return "تطوير مستمر ◀️ نجاحات أكتر ◀️ إنت قائد Pro 👑";
    return "هدفنا: تثبيت فهمك… قبل ما نحسب نقاطك.";
  }

  @override
  Widget build(BuildContext context) {
    final border = AppColors.primaryDeepTeal.withValues(alpha: 0.12);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                    AppColors.primaryDeepTeal.withValues(alpha: 0.08),
                    _badgeColor.withValues(alpha: 0.10),
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
                          color: Colors.black.withValues(alpha: 0.04),
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
                            color: AppColors.primaryDeepTeal.withValues(alpha: 0.75),
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
                  // Headline (Core message)
                  Text(
                    _headline,
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      height: 1.7,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[800],
                    ),
                  ),

                  // Structured line (Pro only)
                  if (_structuredLine.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: _badgeColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _structuredLine,
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primaryDeepTeal,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Footer motivational line
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDeepTeal.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.primaryDeepTeal.withValues(alpha: 0.10),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_rounded,
                            size: 18, color: AppColors.secondaryOrange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _footerLine,
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              height: 1.4,
                              fontWeight: FontWeight.w800,
                              color:
                                  AppColors.primaryDeepTeal.withValues(alpha: 0.85),
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
            color: Colors.black.withValues(alpha: 0.10),
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

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart'; // المكتبة الجديدة
import 'package:lpro2_quiz/core/constants/app_colors.dart';

import '../../../features/pro_card/models/pro_card_banner.dart';

class InfoCardWidget extends StatefulWidget {
  final ProCardBanner banner;
  final VoidCallback? onRead;

  const InfoCardWidget({
    super.key,
    required this.banner,
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
    final banner = widget.banner;

    final text = banner.text.trim();
    final imageUrl = banner.imageUrl.trim();

    final bool hasValidText = banner.isText && text.isNotEmpty;
    final bool hasValidImage = banner.isImage && imageUrl.isNotEmpty;

    // Safety: لو البيانات غلط، نخفي الكارت بالكامل بدل UI غريب
    if (!hasValidText && !hasValidImage) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF003D3D).withValues(alpha: 0.08),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ===== Header Section =====
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [Color(0xFF003D3D), Color(0xFF005F5F)],
                ),
              ),
              child: Row(
                children: [
                  ScaleTransition(
                    scale: Tween(begin: 1.0, end: 1.2).animate(
                      CurvedAnimation(
                        parent: _pulseController,
                        curve: Curves.easeInOut,
                      ),
                    ),
                    child: const Icon(
                      Icons.tips_and_updates_rounded,
                      color: AppColors.secondaryOrange,
                      size: 16,
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
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              color: Colors.white,
              child: hasValidImage
                  ? _ProCardImage(url: imageUrl)
                  : Text(
                      text,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.cairo(
                        fontSize: 15,
                        height: 1.7,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2D3142),
                      ),
                    ),
            ),

            /// ===== Button Section =====
            if (widget.onRead != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onRead,
                    borderRadius: BorderRadius.circular(14),
                    child: Ink(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F4F0),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color:
                              AppColors.secondaryOrange.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          "استوعبت المعلومة",
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.w900,
                            color: AppColors.secondaryOrange,
                            fontSize: 13,
                          ),
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

class _ProCardImage extends StatelessWidget {
  final String url;
  const _ProCardImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[50],
            alignment: Alignment.center,
            child: const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[100],
            alignment: Alignment.center,
            child: Text(
              "فشل تحميل الصورة",
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.w800,
                color: Colors.grey[700],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

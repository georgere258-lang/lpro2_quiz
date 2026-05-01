// PATH: lib/presentation/home/widgets/section_identity_card.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart'; // ✅ [جديد] للتعامل مع الإحصائيات
import '../../../core/constants/app_colors.dart';
// ✅ [جديد] استيراد الموديل للحسابات الدقيقة
import '../../../features/quizzes/models/user_question_record.dart';

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

  // ✅ تعريف الأقسام الجديدة (بدون لمس القديم)
  bool get _isMarket =>
      sectionKey.contains("سوق العقار") || title.contains("سوق العقار");
  bool get _isSales =>
      sectionKey.contains("البيع وعقد المطور") ||
      title.contains("البيع وعقد المطور");

  String get _badgeText {
    if (_isStars) return "FRESH";
    if (_isPro) return "PRO";
    if (_isMarket) return "MARKET";
    if (_isSales) return "SALES";
    return "LPRO";
  }

  String get _badgeEmoji {
    if (_isStars) return "✨";
    if (_isPro) return "🔥";
    if (_isMarket) return "🏙️";
    if (_isSales) return "⚖️";
    return "⭐";
  }

  Color get _badgeColor {
    if (_isStars) return const Color(0xFF3498DB);
    if (_isPro) return AppColors.secondaryOrange;
    if (_isMarket) return const Color(0xFF2ECC71);
    if (_isSales) return AppColors.primaryDeepTeal;
    return const Color(0xFF4FA8A8);
  }

  String get _headline {
    if (_isStars) {
      return "اجمع نقاط دوري النجوم واستعد لمفاجآت قادمة \nلكن خلي بالك…\nالتطور الحقيقي مش بالنقاط بس،\nالتطور بيبدأ بالاستمرارية والفهم وبناء الأساس الصح.";
    }
    if (_isPro) {
      return "اجمع نقاطك بقوة… واستنى مفاجآت قادمة 🚀\nإنت هنا مش جديد على السوق،\nإنت محترف، والمعلومة هي ثروتك الحقيقية.";
    }
    if (_isMarket) {
      return "مكونات السوق العقارى 🏙️\nالقرار الصح بيبدأ بمعلومة صحيحة،\nوقوة المسوق في معرفته بأدق تفاصيل المناطق والمشاريع.";
    }
    if (_isSales) {
      return "أسرار البيع والتعاقد ⚖️\nالمحترف هو اللي فاهم بنود عقده قبل عميله،\nثباتك في 'الكلوزينج' بيجي من تمكنك القانوني والفني.";
    }
    return "خُد خطوة ثابتة… وكمّل صح.";
  }

  String get _subLine {
    if (_isStars) return "بداية الطريق الصح ✨";
    if (_isPro) return "مستوى Pro 🔥";
    if (_isMarket) return "خريطة الاستثمار العقاري 🗺️";
    if (_isSales) return "فنون التفاوض والتعاقد 🤝";
    return "تعلم • تطور • نجاح";
  }

  String get _footerLine {
    if (_isStars) return "تعلم مستمر ◀️ تطور كبير ◀️ نجاح أكيد 💪";
    if (_isPro) return "تطوير مستمر ◀️ نجاحات أكتر ◀️ إنت قائد Pro 👑";
    if (_isMarket) return "فهم السوق ◀️ تحليل المشاريع ◀️ إغلاق ناجح 💪";
    if (_isSales) return "مهارة البيع ◀️ ثقة العميل ◀️ احترافية كاملة 👑";
    return "هدفنا: تثبيت فهمك… قبل ما نحسب نقاطك.";
  }

  // ✅ [جديد] بناء صف الإحصائيات الذكية للأقسام الجديدة فقط
  Widget _buildSmartStats(Color themeColor) {
    return ValueListenableBuilder(
      valueListenable: Hive.box('app_settings').listenable(),
      builder: (context, Box settingsBox, _) {
        // سحب البيانات المخزنة محلياً لهذا القسم
        final int attempted =
            settingsBox.get('total_attempted_$title', defaultValue: 0);
        final int correct =
            settingsBox.get('total_correct_$title', defaultValue: 0);

        // حساب عدد الأخطاء الحالية من صندوق السجلات
        final recordsBox = Hive.box<UserQuestionRecord>('question_records');
        final mistakesCount = recordsBox.values
            .where((r) =>
                r.wasCorrect == false &&
                r.questionId.contains(_isMarket ? "mkt" : "sls"))
            .length;

        final double accuracy = attempted > 0 ? (correct / attempted) * 100 : 0;

        return Column(
          children: [
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: themeColor.withValues(alpha: 0.1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statItem(
                      "الدقة", "${accuracy.toStringAsFixed(1)}%", Colors.green),
                  _statItem("المتقنة", "$correct", AppColors.primaryDeepTeal),
                  _statItem("أخطاء", "$mistakesCount", Colors.redAccent),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label,
            style: GoogleFonts.cairo(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600])),
        Text(value,
            style: GoogleFonts.cairo(
                fontSize: 14, fontWeight: FontWeight.w900, color: color)),
      ],
    );
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
                            color: AppColors.primaryDeepTeal
                                .withValues(alpha: 0.75),
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
                  Text(
                    description,
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      height: 1.75,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),

                  // ✅ [جديد] إضافة الإحصائيات هنا للقسمين الجديدين فقط
                  if (_isMarket || _isSales) _buildSmartStats(_badgeColor),

                  const SizedBox(height: 16),
                  Container(
                    height: 1,
                    width: double.infinity,
                    color: AppColors.primaryDeepTeal.withValues(alpha: 0.08),
                  ),
                  const SizedBox(height: 14),
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
                              color: _badgeColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _badgeColor.withValues(alpha: 0.25),
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDeepTeal.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color:
                            AppColors.primaryDeepTeal.withValues(alpha: 0.10),
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
                              color: AppColors.primaryDeepTeal
                                  .withValues(alpha: 0.85),
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

// PATH: lib/presentation/screens/close_screen.dart
// STATUS: Full File – Fixed scope bug + “CLOSE” scenarios (zero cost)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';

class CloseScreen extends StatefulWidget {
  const CloseScreen({super.key});

  @override
  State<CloseScreen> createState() => _CloseScreenState();
}

class _CloseScreenState extends State<CloseScreen> {
  final List<_Scenario> _scenarios = const [
    _Scenario(
      title: "اعتراض: السعر غالي",
      prompt: "العميل قال: السعر غالي جدًا…",
      options: [
        "ممكن حضرتك تقولي مقارنة بإيه؟ عشان أشرح الفرق بالأرقام.",
        "طيب خلاص هنشوف حاجة أرخص وخلاص.",
        "السعر غالي عشان المشروع جامد.",
      ],
      correctIndex: 0,
      feedback:
          "الصح: سؤال معايرة + تحويل لنقاش أرقام. بيسحب الاعتراض من العاطفة للمنطق.",
    ),
    _Scenario(
      title: "اعتراض: خايف من المطور",
      prompt: "العميل قال: المطور ده جديد…",
      options: [
        "معاك حق. خليني أوريك سابقة الأعمال وخطة التسليم ونظام الضمان.",
        "ما تقلقش كله تمام.",
        "لو مش عاجبك خلاص.",
      ],
      correctIndex: 0,
      feedback: "الصح: اعتراف بالمخاوف + دليل محدد (سابقات/تسليم/ضمان).",
    ),
    _Scenario(
      title: "لحظة الإغلاق",
      prompt: "العميل مقتنع… بس بيتردد قبل الحجز.",
      options: [
        "تحب نحجز بأقل خطوة (EOI/حجز مبدئي) عشان نثبت السعر ونراجع العقد براحتك؟",
        "لازم تحجز دلوقتي حالًا.",
        "خلاص براحتك.",
      ],
      correctIndex: 0,
      feedback: "الصح: micro-commitment (خطوة صغيرة) بدل الضغط أو الانسحاب.",
    ),
  ];

  int _selectedScenario = 0;
  int? _picked;
  bool _showResult = false;

  void _reset() {
    setState(() {
      _picked = null;
      _showResult = false;
    });
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final scenario = _scenarios[_selectedScenario];

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        backgroundColor: AppColors.primaryDeepTeal,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Text('CLOSE',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w900)),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
          children: [
            _topSelector(),
            const SizedBox(height: 14),
            _card(
              title: scenario.title,
              sub: scenario.prompt,
              options: scenario.options,
              correctIndex: scenario.correctIndex,
              feedback: scenario.feedback,
            ),
            const SizedBox(height: 14),
            _actions(scenario),
          ],
        ),
      ),
    );
  }

  Widget _topSelector() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [
            AppColors.primaryDeepTeal.withValues(alpha: 0.10),
            AppColors.secondaryOrange.withValues(alpha: 0.10),
          ],
        ),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt, color: AppColors.secondaryOrange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "سيناريوهات تدريب سريعة — اختار ردك",
              textAlign: TextAlign.right,
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.w900,
                color: AppColors.primaryDeepTeal,
              ),
            ),
          ),
          const SizedBox(width: 10),
          DropdownButton<int>(
            value: _selectedScenario,
            underline: const SizedBox.shrink(),
            items: List.generate(_scenarios.length, (i) {
              return DropdownMenuItem(
                value: i,
                child: Text(
                  "${i + 1}",
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w900),
                ),
              );
            }),
            onChanged: (v) {
              if (v == null) return;
              setState(() {
                _selectedScenario = v;
                _picked = null;
                _showResult = false;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _actions(_Scenario scenario) {
    final canCheck = _picked != null && !_showResult;

    return Row(
      children: [
        _pillButton(
          label: "جولة جديدة",
          icon: Icons.refresh,
          color: Colors.white,
          border: AppColors.primaryDeepTeal.withValues(alpha: 0.18),
          textColor: AppColors.primaryDeepTeal,
          onTap: _reset,
        ),
        const SizedBox(width: 10),
        _pillButton(
          label: "تحقق",
          icon: Icons.check_rounded,
          color: canCheck ? AppColors.secondaryOrange : Colors.grey[300]!,
          border: Colors.transparent,
          textColor: canCheck ? Colors.white : Colors.black45,
          onTap: canCheck
              ? () {
                  setState(() => _showResult = true);
                  final ok = _picked == scenario.correctIndex;
                  _snack(ok ? "صح ✅" : "مش أفضل اختيار ❌");
                }
              : null,
        ),
      ],
    );
  }

  Widget _pillButton({
    required String label,
    required IconData icon,
    required Color color,
    required Color border,
    required Color textColor,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
          boxShadow: [
            if (color != Colors.white)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: textColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({
    required String title,
    required String sub,
    required List<String> options,
    required int correctIndex,
    required String feedback,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primaryDeepTeal.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            textAlign: TextAlign.right,
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: AppColors.primaryDeepTeal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            sub,
            textAlign: TextAlign.right,
            style: GoogleFonts.cairo(
              fontSize: 12,
              height: 1.6,
              fontWeight: FontWeight.w700,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(options.length, (i) {
            final picked = _picked == i;
            final isCorrect = correctIndex == i;
            final reveal = _showResult;

            Color border = Colors.black.withValues(alpha: 0.06);
            Color bg = Colors.white;

            if (reveal && picked) {
              bg = isCorrect
                  ? Colors.green.withValues(alpha: 0.10)
                  : Colors.red.withValues(alpha: 0.08);
              border = isCorrect
                  ? Colors.green.withValues(alpha: 0.35)
                  : Colors.red.withValues(alpha: 0.35);
            } else if (picked) {
              bg = AppColors.secondaryOrange.withValues(alpha: 0.10);
              border = AppColors.secondaryOrange.withValues(alpha: 0.35);
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  if (_showResult) return;
                  setState(() => _picked = i);
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        picked
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: AppColors.primaryDeepTeal,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          options[i],
                          textAlign: TextAlign.right,
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.w800,
                            height: 1.6,
                            color: const Color(0xFF2D3142),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          if (_showResult) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryDeepTeal.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                feedback,
                textAlign: TextAlign.right,
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w800,
                  height: 1.6,
                  color: const Color(0xFF2D3142),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Scenario {
  final String title;
  final String prompt;
  final List<String> options;
  final int correctIndex;
  final String feedback;

  const _Scenario({
    required this.title,
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.feedback,
  });
}

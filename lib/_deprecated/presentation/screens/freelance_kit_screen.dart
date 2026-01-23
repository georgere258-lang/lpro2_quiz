// PATH: lib/presentation/screens/freelance_kit_screen.dart
// STATUS: Full File – Zero-cost utilities + clean premium UI (no external deps)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';

class FreelanceKitScreen extends StatefulWidget {
  const FreelanceKitScreen({super.key});

  @override
  State<FreelanceKitScreen> createState() => _FreelanceKitScreenState();
}

class _FreelanceKitScreenState extends State<FreelanceKitScreen> {
  final _priceC = TextEditingController();
  final _downPaymentC = TextEditingController();
  final _yearsC = TextEditingController();

  double _monthly = 0;
  double _total = 0;

  @override
  void dispose() {
    _priceC.dispose();
    _downPaymentC.dispose();
    _yearsC.dispose();
    super.dispose();
  }

  double _toNum(TextEditingController c) {
    final s = c.text.trim().replaceAll(',', '');
    return double.tryParse(s) ?? 0;
  }

  void _calcInstallment() {
    final price = _toNum(_priceC);
    final down = _toNum(_downPaymentC);
    final years = _toNum(_yearsC);

    final months = (years * 12).round();
    if (price <= 0 || months <= 0) {
      setState(() {
        _monthly = 0;
        _total = 0;
      });
      return;
    }

    final remaining = (price - down);
    final monthly = remaining / months;
    setState(() {
      _monthly = monthly.isFinite ? monthly : 0;
      _total = down + (monthly * months);
    });
  }

  String _money(double v) {
    final x = v.round();
    return "${x.toString().replaceAllMapped(
              RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
              (m) => '${m[1]},',
            )} EGP";
  }

  Widget _card({
    required String title,
    required String sub,
    required Widget child,
    IconData icon = Icons.auto_awesome,
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
          Row(
            children: [
              Icon(icon, color: AppColors.secondaryOrange),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryDeepTeal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
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
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _tf(TextEditingController c, String hint) {
    return TextField(
      controller: c,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.right,
      style: GoogleFonts.cairo(fontWeight: FontWeight.w900),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      onChanged: (_) => _calcInstallment(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        backgroundColor: AppColors.primaryDeepTeal,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          'Freelance Kit',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w900),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
          children: [
            _card(
              title: "مخطط الأقساط السريع",
              sub:
                  "أدخل السعر + المقدم + عدد السنين… وهتطلع القسط فورًا قدام العميل.",
              icon: Icons.calculate_outlined,
              child: Column(
                children: [
                  _tf(_priceC, "سعر الوحدة (EGP)"),
                  const SizedBox(height: 10),
                  _tf(_downPaymentC, "المقدم (EGP)"),
                  const SizedBox(height: 10),
                  _tf(_yearsC, "سنوات التقسيط (مثال: 7)"),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryDeepTeal.withValues(alpha: 0.10),
                          AppColors.secondaryOrange.withValues(alpha: 0.10),
                        ],
                      ),
                      border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
                    ),
                    child: Column(
                      children: [
                        _resultRow("القسط الشهري", _money(_monthly)),
                        const SizedBox(height: 6),
                        _resultRow("الإجمالي التقريبي", _money(_total)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _card(
              title: "Checklist تأمين العمولة",
              sub: "خطوات سريعة قبل أي مقابلة/حجز عشان تحمي حقك.",
              icon: Icons.verified_user_outlined,
              child: const Column(
                children: [
                  _CheckLine("اتفاق مكتوب (حتى لو WhatsApp) على العمولة."),
                  _CheckLine("تحديد من صاحب القرار (المالك/الزوج/الشريك)."),
                  _CheckLine("توثيق مصدر العميل (Referral/Ads/Walk-in)."),
                  _CheckLine("تأكيد صفة المطور/المسوق الرسمي إن وُجد."),
                  _CheckLine(
                      "تسجيل الزيارة: تاريخ + مكان + مشروع + اسم العميل."),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _card(
              title: "اسكربتات جاهزة (Mini)",
              sub: "رسالة قصيرة تفتح الباب بدون زن.",
              icon: Icons.chat_bubble_outline,
              child: Column(
                children: [
                  _scriptBox("متابعة خفيفة",
                      "مساء الخير يا فندم 🌟\nحابب أطمن هل لسه مهتم بنفس المشروع؟\nوأبعتلك 2 اختيار مناسبين لميزانيتك."),
                  const SizedBox(height: 10),
                  _scriptBox("تأكيد زيارة",
                      "تمام يا فندم ✅\nنقابل الساعة __ في __\nوهبعتلك لوكيشن + تفاصيل سريعة قبلها."),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultRow(String k, String v) {
    return Row(
      children: [
        Text(
          v,
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.w900,
            color: AppColors.primaryDeepTeal,
          ),
        ),
        const Spacer(),
        Text(
          k,
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.w900,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _scriptBox(String title, String body) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            textAlign: TextAlign.right,
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.w900,
              color: AppColors.secondaryOrange,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.right,
            style: GoogleFonts.cairo(
              height: 1.7,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2D3142),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckLine extends StatelessWidget {
  final String text;
  const _CheckLine(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
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
    );
  }
}

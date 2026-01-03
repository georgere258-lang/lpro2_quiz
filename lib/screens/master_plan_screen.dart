import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MasterPlanScreen extends StatefulWidget {
  const MasterPlanScreen({super.key});

  @override
  State<MasterPlanScreen> createState() => _MasterPlanScreenState();
}

class _MasterPlanScreenState extends State<MasterPlanScreen> {
  final Color deepTeal = const Color(0xFF1B4D57);
  final Color safetyOrange = const Color(0xFFE67E22);
  final Color lightTeal = const Color(0xFF4FA8A8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F8),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: CustomScrollView(
          slivers: [
            // هيدر الشاشة
            _buildSliverAppBar(),

            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildIntroText(),
                  const SizedBox(height: 25),

                  // أقسام التحليل
                  _buildAnalysisCard(
                    title: "الميزانية والقدرة المالية",
                    subtitle: "حدد نطاق السعر وطريقة السداد",
                    icon: Icons.account_balance_wallet_outlined,
                    points: [
                      "الكاش المتوفر",
                      "التمويل العقاري",
                      "نظام الأقساط المفضل"
                    ],
                  ),
                  _buildAnalysisCard(
                    title: "الغرض من الشراء",
                    subtitle: "لماذا يريد العميل هذا العقار؟",
                    icon: Icons.track_changes_outlined,
                    points: [
                      "سكن عائلي أول",
                      "استثمار وإعادة بيع",
                      "عائد إيجاري شهري"
                    ],
                  ),
                  _buildAnalysisCard(
                    title: "الجدول الزمني",
                    subtitle: "متى يريد العميل استلام الوحدة؟",
                    icon: Icons.access_time_rounded,
                    points: [
                      "استلام فوري",
                      "قيد الإنشاء (سنة/سنتين)",
                      "استثمار طويل الأمد"
                    ],
                  ),
                  _buildAnalysisCard(
                    title: "المتطلبات الجغرافية",
                    subtitle: "تحديد المنطقة ونوع الوحدة",
                    icon: Icons.map_outlined,
                    points: [
                      "منطقة محددة (التجمع/زايد)",
                      "نوع الوحدة (شقة/فيلا)",
                      "الخدمات الأساسية المطلوبة"
                    ],
                  ),

                  const SizedBox(height: 30),
                  _buildProTip(),
                  const SizedBox(height: 40),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 100,
      floating: false,
      pinned: true,
      backgroundColor: deepTeal,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          "اعرف عميلك.. تملك مفتاح البيع",
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildIntroText() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border(right: BorderSide(color: safetyOrange, width: 5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)
        ],
      ),
      child: Text(
        "المستشار العقاري الناجح يبدأ دائماً بالأسئلة الصحيحة. استخدم هذه المحاور لتحليل احتياج عميلك بدقة قبل عرض أي مشروع.",
        style: GoogleFonts.cairo(
            fontSize: 13,
            height: 1.6,
            color: deepTeal,
            fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildAnalysisCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<String> points,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: lightTeal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: deepTeal, size: 26),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: deepTeal)),
                    Text(subtitle,
                        style: GoogleFonts.cairo(
                            fontSize: 11, color: Colors.grey[600])),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 15),
            child: Divider(height: 1),
          ),
          ...points.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 16, color: safetyOrange),
                    const SizedBox(width: 10),
                    Text(p,
                        style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildProTip() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: lightTeal.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: lightTeal.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Text("💡", style: TextStyle(fontSize: 24)),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              "نصيحة Pro: ابدأ دائماً بسؤال 'ما الذي يجعلك تفكر في الشراء اليوم؟' لتفهم الدافع النفسي الحقيقي خلف الصفقة.",
              style: GoogleFonts.cairo(
                  fontSize: 12, fontWeight: FontWeight.bold, color: deepTeal),
            ),
          ),
        ],
      ),
    );
  }
}

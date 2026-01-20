import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/sound_manager.dart';
import '../home/widgets/section_identity_card.dart'; // استيراد المكون المعتمد

class MasterPlanScreen extends StatefulWidget {
  const MasterPlanScreen({super.key});

  @override
  State<MasterPlanScreen> createState() => _MasterPlanScreenState();
}

class _MasterPlanScreenState extends State<MasterPlanScreen> {
  // الثوابت الاستراتيجية تم نقلها هنا لتنظيم المحتوى الثابت
  final List<Map<String, dynamic>> staticTopics = [
    {
      'title': 'مصفوفة الاحتياج (Need Matrix)',
      'content':
          'قبل عرض الوحدات، اسأل: "هل تشتري للسكن أم للاستثمار؟". إذا كان للسكن ركز على الخدمات والهدوء، وإذا كان للاستثمار ركز على العائد الإيجاري وسرعة إعادة البيع.',
      'icon': Icons.grid_view_rounded
    },
    {
      'title': 'سيكولوجية الموقع المفضل',
      'content':
          '"أين تقضي أغلب وقتك حالياً؟". هذا السؤال يكشف لك إذا كان العميل يفضل القرب من عمله، أم يهرب من الزحام إلى المدن الجديدة. افهم جغرافية حياته قبل أن تبيع له مكاناً.',
      'icon': Icons.location_on_rounded
    },
    {
      'title': 'لغز الميزانية الحقيقي',
      'content':
          'العميل غالباً لا يفصح عن ميزانيته الحقيقية. اسأل: "ما هو القسط الشهري الذي يجعلك تشعر بالراحة؟". الرقم الذي سيذكره هو المفتاح الحقيقي لتحديد المشروع المناسب.',
      'icon': Icons.account_balance_wallet_rounded
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 25, 20, 10),
                child: Column(
                  children: [
                    // حقن كارت الهوية المعتمد لقسم (اعرف عميلك)
                    const SectionIdentityCard(
                      sectionKey: 'master_plan_identity',
                      icon: Icons.psychology_outlined,
                      title: "لماذا قسم اعرف عميلك؟",
                      description:
                          "المستشار العقاري Pro لا يبيع مجرد جدران، بل يقدم حلولاً ذكية لاحتياجات حقيقية عبر تحليل سيكولوجية المشتري.",
                      benefits: [
                        "فهم الدوافع الحقيقية وراء قرار الشراء.",
                        "إتقان فن توجيه الأسئلة الكاشفة للميزانية والاحتياج.",
                        "تحويل العلاقة من (بائع ومشتري) إلى (مستشار وشريك نجاح)."
                      ],
                    ),
                    const SizedBox(height: 15),
                    _buildSectionHeader("استراتيجيات تحليل العميل 🧠"),
                  ],
                ),
              ),
            ),

            // الجزء الديناميكي: جلب المواضيع من Firestore
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('topics')
                  .where('category', isEqualTo: 'عرف عميلك')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const SliverToBoxAdapter(
                      child: Center(child: Text("خطأ في تحميل البيانات")));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(
                      child: Center(
                          child: Padding(
                              padding: EdgeInsets.all(30),
                              child: CircularProgressIndicator())));
                }

                final docs = snapshot.data?.docs ?? [];
                return SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildAttractiveTopicCard(
                          docs[index].data() as Map<String, dynamic>),
                      childCount: docs.length,
                    ),
                  ),
                );
              },
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 25, 20, 15),
                child: _buildSectionHeader("ثوابت المستشار الـ Pro ⭐"),
              ),
            ),

            // الجزء الثابت
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildStaticToolCard(staticTopics[index]),
                  childCount: staticTopics.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.primaryDeepTeal,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text("اعرف عميلك",
            style: GoogleFonts.cairo(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: Colors.white)),
        background: Container(color: AppColors.primaryDeepTeal),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border:
              Border.all(color: AppColors.primaryDeepTeal.withValues(alpha: 0.1))),
      child: Text(title,
          style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.primaryDeepTeal)),
    );
  }

  Widget _buildAttractiveTopicCard(Map<String, dynamic> data) {
    return GestureDetector(
      onTap: () {
        SoundManager.playTap();
        Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => MasterPlanDetailPage(data: data)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 25),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 10))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (data['imageUrl'] != null && data['imageUrl'] != "")
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                child: CachedNetworkImage(
                    imageUrl: data['imageUrl'],
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['title'] ?? "",
                      style: GoogleFonts.cairo(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryDeepTeal)),
                  const SizedBox(height: 10),
                  Text(data['content'] ?? "",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                          fontSize: 13, color: Colors.grey[600], height: 1.6)),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text("عرض التفاصيل",
                          style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: AppColors.secondaryOrange,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(width: 5),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          size: 12, color: AppColors.secondaryOrange),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaticToolCard(Map<String, dynamic> topic) {
    return GestureDetector(
      onTap: () {
        SoundManager.playTap();
        Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => MasterPlanDetailPage(data: topic)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: AppColors.primaryDeepTeal.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                  color: AppColors.primaryDeepTeal.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(topic['icon'] ?? Icons.lightbulb_outline,
                  color: AppColors.secondaryOrange, size: 24),
            ),
            const SizedBox(width: 15),
            Expanded(
                child: Text(topic['title'],
                    style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDeepTeal))),
            Icon(Icons.chevron_left_rounded,
                color: AppColors.secondaryOrange.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}

class MasterPlanDetailPage extends StatelessWidget {
  final Map<String, dynamic> data;
  const MasterPlanDetailPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDeepTeal,
        elevation: 0,
        title:
            Text("تفاصيل الاستراتيجية", style: GoogleFonts.cairo(fontSize: 16)),
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (data['imageUrl'] != null && data['imageUrl'] != "")
                CachedNetworkImage(
                    imageUrl: data['imageUrl'],
                    width: double.infinity,
                    height: 250,
                    fit: BoxFit.cover),
              Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['title'] ?? "",
                        style: GoogleFonts.cairo(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primaryDeepTeal)),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 20),
                    Text(data['content'] ?? "",
                        style: GoogleFonts.cairo(
                            fontSize: 16,
                            height: 1.9,
                            color: const Color(0xFF2D3142),
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

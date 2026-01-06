import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/sound_manager.dart';

class MasterPlanScreen extends StatefulWidget {
  const MasterPlanScreen({super.key});

  @override
  State<MasterPlanScreen> createState() => _MasterPlanScreenState();
}

class _MasterPlanScreenState extends State<MasterPlanScreen> {
  final Color deepTeal = AppColors.primaryDeepTeal;
  final Color safetyOrange = AppColors.secondaryOrange;

  // الثوابت الاستراتيجية التي تظهر دائماً للمستخدم
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
                    _buildIntroText(),
                    const SizedBox(height: 35),
                    _buildSectionHeader("استراتيجيات تحليل العميل 🧠"),
                  ],
                ),
              ),
            ),

            // الجزء الديناميكي: جلب المواضيع المتغيرة من Firestore
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('topics')
                  .where('category', isEqualTo: 'عرف عميلك')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError)
                  return const SliverToBoxAdapter(
                      child: Center(child: Text("خطأ في تحميل البيانات")));

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
                      (context, index) {
                        var data = docs[index].data() as Map<String, dynamic>;
                        return _buildAttractiveTopicCard(data);
                      },
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

            // الجزء الثابت: نصائح واستراتيجيات أساسية
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
      backgroundColor: deepTeal,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text("اعرف عميلك",
            style: GoogleFonts.cairo(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: Colors.white)),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [deepTeal, deepTeal.withOpacity(0.85)],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIntroText() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
                color: safetyOrange.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5))
          ],
          border: Border(right: BorderSide(color: safetyOrange, width: 6))),
      child: Text(
          "المستشار العقاري Pro لا يبيع مجرد جدران، بل يقدم حلولاً ذكية لاحتياجات حقيقية. ابدأ بتحليل عميلك بعمق.",
          style: GoogleFonts.cairo(
              fontSize: 14.5,
              height: 1.7,
              color: deepTeal,
              fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: deepTeal.withOpacity(0.1))),
      child: Text(title,
          style: GoogleFonts.cairo(
              fontSize: 16, fontWeight: FontWeight.w900, color: deepTeal)),
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
                color: Colors.black.withOpacity(0.06),
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
                  fit: BoxFit.cover,
                  memCacheWidth: 450,
                ),
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
                          color: deepTeal)),
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
                              color: safetyOrange,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(width: 5),
                      Icon(Icons.arrow_forward_ios_rounded,
                          size: 12, color: safetyOrange),
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
          border: Border.all(color: deepTeal.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                  color: deepTeal.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(topic['icon'] ?? Icons.lightbulb_outline,
                  color: safetyOrange, size: 24),
            ),
            const SizedBox(width: 15),
            Expanded(
                child: Text(topic['title'],
                    style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: deepTeal))),
            Icon(Icons.chevron_left_rounded,
                color: safetyOrange.withOpacity(0.5)),
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
                  fit: BoxFit.cover,
                ),
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

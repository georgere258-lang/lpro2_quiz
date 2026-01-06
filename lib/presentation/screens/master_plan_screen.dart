import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/sound_manager.dart'; // استدعاء مدير الصوت

class MasterPlanScreen extends StatefulWidget {
  const MasterPlanScreen({super.key});

  @override
  State<MasterPlanScreen> createState() => _MasterPlanScreenState();
}

class _MasterPlanScreenState extends State<MasterPlanScreen> {
  final Color deepTeal = AppColors.primaryDeepTeal;
  final Color safetyOrange = AppColors.secondaryOrange;

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
          physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics()),
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
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('topics').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const SliverToBoxAdapter(
                    child: Center(
                        child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Text("خطأ في تحميل البيانات"))),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(
                    child: Center(
                        child: Padding(
                            padding: EdgeInsets.all(40),
                            child: CircularProgressIndicator())),
                  );
                }

                final docs = snapshot.data?.docs.where((doc) {
                      var data = doc.data() as Map<String, dynamic>;
                      return data['category'] != null &&
                          data['category'].toString().contains("عرف عميلك");
                    }).toList() ??
                    [];

                if (docs.isEmpty) {
                  return const SliverToBoxAdapter(child: SizedBox());
                }

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
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildStaticToolCard(staticTopics[index]),
                  childCount: staticTopics.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 60)),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 110,
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
              colors: [deepTeal, deepTeal.withOpacity(0.8)],
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
                color: safetyOrange.withOpacity(0.15),
                blurRadius: 15,
                offset: const Offset(0, 5)),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
                color: safetyOrange.withOpacity(0.2),
                offset: const Offset(3, 3),
                blurRadius: 0),
          ],
          border: Border.all(color: deepTeal.withOpacity(0.1))),
      child: Text(title,
          style: GoogleFonts.cairo(
              fontSize: 16, fontWeight: FontWeight.w900, color: deepTeal)),
    );
  }

  Widget _buildAttractiveTopicCard(Map<String, dynamic> data) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        SoundManager.playTap(); // تشغيل صوت النقر عند الدخول للموضوع
        Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => MasterPlanDetailPage(data: data)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 20,
                offset: const Offset(0, 10)),
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
                  memCacheWidth: 400, // تحسين الذاكرة: فك ضغط الصورة بحجم أصغر
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color: safetyOrange.withOpacity(0.25),
                              offset: const Offset(3, 3),
                              blurRadius: 0),
                        ],
                        border: Border.all(color: deepTeal.withOpacity(0.05))),
                    child: Text(data['title'] ?? "",
                        style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: deepTeal)),
                  ),
                  const SizedBox(height: 15),
                  Text(data['content'] ?? "",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                          fontSize: 13.5,
                          color: Colors.grey[600],
                          height: 1.6)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                            color: deepTeal,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                  color: deepTeal.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4))
                            ]),
                        child: Row(
                          children: [
                            Text("استكشف السر",
                                style: GoogleFonts.cairo(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800)),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_back_rounded,
                                size: 16, color: Colors.white),
                          ],
                        ),
                      ),
                      Icon(Icons.auto_awesome_motion_rounded,
                          color: safetyOrange.withOpacity(0.5), size: 22),
                    ],
                  ),
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
      behavior: HitTestBehavior.opaque,
      onTap: () {
        SoundManager.playTap();
        Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => MasterPlanDetailPage(data: topic)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
                color: safetyOrange.withOpacity(0.12),
                offset: const Offset(3, 3),
                blurRadius: 0),
          ],
          border: Border.all(color: deepTeal.withOpacity(0.06)),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                  color: deepTeal, borderRadius: BorderRadius.circular(15)),
              child: Icon(topic['icon'] ?? Icons.star_rounded,
                  color: safetyOrange, size: 26),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(topic['title'],
                      style: GoogleFonts.cairo(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: deepTeal)),
                  Text("دليل المستشار العقاري",
                      style: GoogleFonts.cairo(
                          fontSize: 11, color: Colors.grey[500])),
                ],
              ),
            ),
            Icon(Icons.chevron_left_rounded, color: safetyOrange, size: 30),
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
      appBar: AppBar(backgroundColor: AppColors.primaryDeepTeal, elevation: 0),
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
                  height: 280,
                  fit: BoxFit.cover,
                  memCacheWidth: 800, // دقة أعلى لصفحة التفاصيل
                ),
              Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                                color:
                                    AppColors.secondaryOrange.withOpacity(0.3),
                                offset: const Offset(4, 4),
                                blurRadius: 0),
                          ],
                          border: Border.all(
                              color:
                                  AppColors.primaryDeepTeal.withOpacity(0.1))),
                      child: Text(data['title'] ?? "",
                          style: GoogleFonts.cairo(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primaryDeepTeal)),
                    ),
                    const SizedBox(height: 30),
                    Text(data['content'] ?? "",
                        style: GoogleFonts.cairo(
                            fontSize: 16,
                            height: 1.9,
                            color: const Color(0xFF2D3142),
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 100),
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

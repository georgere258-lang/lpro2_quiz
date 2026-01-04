import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

// استيراد الثوابت المركزية
import '../../core/constants/app_colors.dart';

class MasterPlanScreen extends StatefulWidget {
  const MasterPlanScreen({super.key});

  @override
  State<MasterPlanScreen> createState() => _MasterPlanScreenState();
}

class _MasterPlanScreenState extends State<MasterPlanScreen> {
  final Color deepTeal = AppColors.primaryDeepTeal;
  final Color safetyOrange = AppColors.secondaryOrange;

  // داتا تأسيسية قوية تظهر دائماً في الأسفل كمرجع
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
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Column(
                  children: [
                    _buildIntroText(),
                    const SizedBox(height: 25),
                    _buildSectionTitle("محاور التحليل الاستراتيجية"),
                  ],
                ),
              ),
            ),

            // عرض البيانات الديناميكية من Firebase
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('topics').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(
                    child: Center(
                        child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator())),
                  );
                }

                // فلترة مرنة تتجاهل اختلاف الهمزة في كلمة "اعرف عميلك"
                final docs = snapshot.data?.docs.where((doc) {
                      String cat = doc['category'].toString();
                      return cat.contains("عرف عميلك");
                    }).toList() ??
                    [];

                if (docs.isNotEmpty) {
                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          var data = docs[index].data() as Map<String, dynamic>;
                          return _buildTopicCard(data);
                        },
                        childCount: docs.length,
                      ),
                    ),
                  );
                }

                return const SliverToBoxAdapter(child: SizedBox());
              },
            ),

            // عرض الداتا الثابتة (الأساسيات)
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: _buildSectionTitle("أساسيات L Pro الثابتة"),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) =>
                      _buildStaticTopicCard(staticTopics[index]),
                  childCount: staticTopics.length,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 50)),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: deepTeal,
      elevation: 0,
      title: Text("إعرف عميلك",
          style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
      centerTitle: true,
    );
  }

  Widget _buildIntroText() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border(right: BorderSide(color: safetyOrange, width: 5))),
      child: Text(
          "المستشار العقاري الناجح يبدأ دائماً بالأسئلة الصحيحة لتحليل احتياج العميل بدقة قبل عرض أي مشروع.",
          style: GoogleFonts.cairo(
              fontSize: 13,
              height: 1.6,
              color: deepTeal,
              fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(title,
          style: GoogleFonts.cairo(
              fontSize: 18, fontWeight: FontWeight.w900, color: deepTeal)),
    );
  }

  Widget _buildTopicCard(Map<String, dynamic> data) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (c) => MasterPlanDetailPage(data: data))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5))
          ],
        ),
        child: Column(
          children: [
            if (data['imageUrl'] != null && data['imageUrl'] != "")
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                child: CachedNetworkImage(
                  imageUrl: data['imageUrl'],
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                      height: 160,
                      color: Colors.grey[100],
                      child: const Center(child: CircularProgressIndicator())),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['title'] ?? "",
                      style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: deepTeal)),
                  const SizedBox(height: 8),
                  Text(data['content'] ?? "",
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                          fontSize: 12, color: Colors.grey[600], height: 1.5)),
                  const SizedBox(height: 10),
                  Text("اضغط للتفاصيل...",
                      style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: safetyOrange,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaticTopicCard(Map<String, dynamic> topic) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (c) => MasterPlanDetailPage(data: topic))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: deepTeal.withOpacity(0.05))),
        child: Row(
          children: [
            CircleAvatar(
                backgroundColor: safetyOrange.withOpacity(0.1),
                child: Icon(topic['icon'] ?? Icons.star,
                    color: safetyOrange, size: 20)),
            const SizedBox(width: 15),
            Expanded(
                child: Text(topic['title'],
                    style: GoogleFonts.cairo(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: deepTeal))),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterPadding() {
    return const SliverToBoxAdapter(child: SizedBox(height: 50));
  }
}

class MasterPlanDetailPage extends StatelessWidget {
  final Map<String, dynamic> data;
  const MasterPlanDetailPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 250,
              pinned: true,
              backgroundColor: AppColors.primaryDeepTeal,
              flexibleSpace: FlexibleSpaceBar(
                background: data['imageUrl'] != null && data['imageUrl'] != ""
                    ? CachedNetworkImage(
                        imageUrl: data['imageUrl'], fit: BoxFit.cover)
                    : Container(
                        color: AppColors.primaryDeepTeal,
                        child: Icon(data['icon'] ?? Icons.lightbulb,
                            size: 80, color: Colors.white24)),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(25),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Text(data['title'] ?? "",
                      style: GoogleFonts.cairo(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryDeepTeal)),
                  const Divider(height: 40),
                  Text(data['content'] ?? "",
                      style: GoogleFonts.cairo(
                          fontSize: 15, height: 1.8, color: Colors.black87)),
                  const SizedBox(height: 50),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

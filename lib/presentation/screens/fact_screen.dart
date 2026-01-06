import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/sound_manager.dart';

class FactScreen extends StatefulWidget {
  const FactScreen({super.key});

  @override
  State<FactScreen> createState() => _FactScreenState();
}

class _FactScreenState extends State<FactScreen> {
  final Color deepTeal = AppColors.primaryDeepTeal;
  final Color safetyOrange = AppColors.secondaryOrange;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: deepTeal,
        centerTitle: true,
        elevation: 0,
        title: Text("المعلومة بتفرق",
            style: GoogleFonts.cairo(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: StreamBuilder<QuerySnapshot>(
          // جلب البيانات من مجموعة topics وتصفية الفئة
          stream: FirebaseFirestore.instance
              .collection('topics')
              .where('category', isEqualTo: 'المعلومة بتفرق')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("لا توجد معلومات حالياً"));
            }

            final dataItems = snapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: dataItems.length,
              // تحسين السكرول ومنع النتشة
              cacheExtent: 1000,
              itemBuilder: (context, index) {
                var data = dataItems[index].data() as Map<String, dynamic>;
                return RepaintBoundary(
                  // تحسين أداء الرسم
                  child: _buildAttractiveTopicCard(data),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildAttractiveTopicCard(Map<String, dynamic> data) {
    return GestureDetector(
      onTap: () {
        SoundManager.playTap();
        Navigator.push(context,
            MaterialPageRoute(builder: (c) => FactDetailPage(data: data)));
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
                  memCacheHeight:
                      400, // السحر هنا لمنع التهنيج (تقليل استهلاك الرام)
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
                              blurRadius: 0)
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
                            Text("اقرأ المعلومة",
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
                      Icon(Icons.lightbulb_outline_rounded,
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
}

// صفحة التفاصيل المخصصة
class FactDetailPage extends StatelessWidget {
  final Map<String, dynamic> data;
  const FactDetailPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFB),
      appBar: AppBar(
          backgroundColor: AppColors.primaryDeepTeal,
          elevation: 0,
          centerTitle: true,
          title: Text(data['title'] ?? "التفاصيل",
              style: GoogleFonts.cairo(
                  fontSize: 16, fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (data['imageUrl'] != null && data['imageUrl'] != "")
                CachedNetworkImage(
                    imageUrl: data['imageUrl'],
                    width: double.infinity,
                    height: 250,
                    fit: BoxFit.cover,
                    memCacheHeight: 800),
              Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['title'] ?? "",
                        style: GoogleFonts.cairo(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primaryDeepTeal)),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 20),
                    Text(data['content'] ?? "",
                        style: GoogleFonts.cairo(
                            fontSize: 16,
                            height: 1.8,
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

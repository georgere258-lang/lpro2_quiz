import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class KnowledgeScreen extends StatelessWidget {
  const KnowledgeScreen({super.key});

  // --- ميثاق ألوان باكدج 3 المعتمد (LPro Deep Teal) ---
  static const Color deepTeal = Color(0xFF005F6B);     // اللون القائد
  static const Color safetyOrange = Color(0xFFFF8C00); // لون الأكشن واللوجو (المثلث)
  static const Color iceWhite = Color(0xFFF8F9FA);     // الخلفية الأساسية
  static const Color darkTealText = Color(0xFF002D33); // نصوص العناوين

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: iceWhite,
      appBar: AppBar(
        title: Text(
          "المكتبة العقارية الشاملة", 
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: darkTealText, fontSize: 18)
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: deepTeal),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('articles').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: deepTeal));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "لا توجد مقالات تعليمية حالياً", 
                style: GoogleFonts.cairo(color: Colors.grey, fontSize: 14)
              )
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              String imagePath = data['imageUrl'] ?? "https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=500";

              return Container(
                margin: const EdgeInsets.only(bottom: 25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: deepTeal.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _showDetails(context, data, imagePath),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // منطقة الصورة مع Tag الهوية البرتقالي
                      Stack(
                        children: [
                          Image.network(
                            imagePath,
                            height: 210,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            top: 15,
                            right: 15,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: safetyOrange, // اللون البرتقالي المعتمد للمثلث والتاج
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5)]
                              ),
                              child: Text(
                                "دليل LPro التعليمي", 
                                style: GoogleFonts.cairo(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['title'] ?? "مقال عقاري جديد", 
                              style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: darkTealText, height: 1.3)
                            ),
                            const SizedBox(height: 10),
                            Text(
                              data['content'] ?? "", 
                              maxLines: 2, 
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.cairo(color: const Color(0xFF5A5A5A), fontSize: 13, height: 1.6)
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Text(
                                  "استكمل القراءة", 
                                  style: GoogleFonts.cairo(color: deepTeal, fontWeight: FontWeight.bold, fontSize: 14)
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_rounded, size: 18, color: deepTeal),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // نافذة التفاصيل المستوحاة من تصميم شاشة المراجعة
  void _showDetails(BuildContext context, Map<String, dynamic> data, String img) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.9,
        minChildSize: 0.6,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 45, height: 4, 
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))
                  ),
                ),
                const SizedBox(height: 25),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(img, fit: BoxFit.cover, width: double.infinity),
                ),
                const SizedBox(height: 25),
                Text(
                  data['title'] ?? "", 
                  style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.bold, color: darkTealText, height: 1.4)
                ),
                const SizedBox(height: 15),
                Text(
                  data['content'] ?? "", 
                  style: GoogleFonts.cairo(fontSize: 16, height: 1.8, color: const Color(0xFF4A4A4A))
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
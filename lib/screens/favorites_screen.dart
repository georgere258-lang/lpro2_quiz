import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  // --- ميثاق ألوان باكدج 3 المعتمد ---
  static const Color deepTeal = Color(0xFF005F6B);     // اللون القائد
  static const Color safetyOrange = Color(0xFFFF8C00); // لون التميز (الأكشن)
  static const Color iceWhite = Color(0xFFF8F9FA);     // الخلفية الأساسية
  static const Color darkTealText = Color(0xFF002D33); // نصوص العناوين

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: iceWhite,
      appBar: AppBar(
        title: Text(
          "المقالات المحفوظة", 
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18)
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: darkTealText,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .collection('favorites')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: deepTeal));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // أيقونة الحالة الفارغة بلمحة فيروزية
                  Icon(Icons.bookmark_border_rounded, size: 80, color: deepTeal.withOpacity(0.2)),
                  const SizedBox(height: 15),
                  Text(
                    "لا توجد مقالات محفوظة حالياً", 
                    style: GoogleFonts.cairo(color: Colors.grey[500], fontSize: 15)
                  ),
                ],
              ),
            );
          }

          final favs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            itemCount: favs.length,
            itemBuilder: (context, index) {
              var data = favs[index].data() as Map<String, dynamic>;
              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: deepTeal.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: const Icon(Icons.bookmark_rounded, color: safetyOrange, size: 30),
                  title: Text(
                    data['title'] ?? "", 
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: darkTealText)
                  ),
                  subtitle: Text(
                    "اضغط للقراءة الآن", 
                    style: GoogleFonts.cairo(color: Colors.grey[600], fontSize: 12)
                  ),
                  trailing: Icon(Icons.arrow_forward_ios_rounded, color: deepTeal.withOpacity(0.2), size: 16),
                  onTap: () {
                    // فتح تفاصيل المقال (يمكن ربطه بـ ArticleDetailsScreen لاحقاً)
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
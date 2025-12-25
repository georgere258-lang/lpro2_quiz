import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F9),
      appBar: AppBar(
        title: const Text("المقالات المحفوظة", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF102A43),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // هنا نقرأ من مجموعة فرعية داخل المستخدم تسمى favorites
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .collection('favorites')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 70, color: Colors.grey),
                  SizedBox(height: 10),
                  Text("لا توجد مقالات محفوظة حالياً", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final favs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: favs.length,
            itemBuilder: (context, index) {
              var data = favs[index].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  leading: const Icon(Icons.bookmark, color: Colors.red),
                  title: Text(data['title'] ?? "", style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text("اضغط للقراءة"),
                  onTap: () {
                    // هنا يمكننا فتح تفاصيل المقال
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
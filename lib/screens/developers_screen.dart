import 'package:flutter/material.dart';

class DevelopersScreen extends StatelessWidget {
  const DevelopersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color brandOrange = Color(0xFFFF8C42);

    return Scaffold(
      appBar: AppBar(
        title: const Text("المطورين العقاريين"),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 8, // عدد افتراضي للمطورين
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 15),
            decoration: BoxDecoration(
              color: const Color(0xFF1B3358),
              borderRadius: BorderRadius.circular(15),
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: brandOrange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.business, color: brandOrange),
              ),
              title: Text(
                "اسم الشركة المطورة ${index + 1}",
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              subtitle: const Text("استكشف المشاريع المتاحة", style: TextStyle(color: Colors.white54)),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
              onTap: () {
                // سيتم إضافة صفحة تفاصيل المطور هنا لاحقاً
              },
            ),
          );
        },
      ),
    );
  }
}
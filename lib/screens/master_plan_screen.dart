import 'package:flutter/material.dart';

class MasterPlanScreen extends StatelessWidget {
  const MasterPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color brandOrange = Color(0xFFFF8C42);

    return Scaffold(
      appBar: AppBar(
        title: const Text("المخطط العام"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map_rounded, size: 100, color: brandOrange.withOpacity(0.2)),
              const SizedBox(height: 20),
              const Text(
                "المخطط العام التفاعلي",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              const Text(
                "هذا القسم سيتيح لك استعراض كافة المواقع العقارية عبر الخرائط التفاعلية.",
                style: TextStyle(color: Colors.white60, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () {
                  // هنا نضع دالة فتح الخرائط
                },
                icon: const Icon(Icons.location_on),
                label: const Text("فتح الخريطة الآن"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
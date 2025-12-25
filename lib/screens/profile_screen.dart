import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color brandOrange = Color(0xFFFF8C42);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("الملف الشخصي")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(radius: 50, backgroundColor: brandOrange, child: Icon(Icons.person, size: 50, color: Colors.white)),
            const SizedBox(height: 15),
            Text(user?.phoneNumber ?? "رقم المستخدم", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            
            // كارت النقاط
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF1B3358), Color(0xFF061121)]),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: brandOrange.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("إجمالي النقاط", style: TextStyle(color: Colors.white70)),
                      Text("2,450 PT", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: brandOrange)),
                    ],
                  ),
                  Icon(Icons.stars, size: 50, color: brandOrange),
                ],
              ),
            ),
            const SizedBox(height: 40),
            _profileOption(Icons.history, "سجل الطلبات"),
            _profileOption(Icons.notifications_outlined, "التنبيهات"),
            _profileOption(Icons.logout, "تسجيل الخروج", color: Colors.redAccent),
          ],
        ),
      ),
    );
  }

  Widget _profileOption(IconData icon, String title, {Color color = Colors.white}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white24),
    );
  }
}
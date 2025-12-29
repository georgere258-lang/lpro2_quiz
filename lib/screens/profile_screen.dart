import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color deepTeal = Color(0xFF1B4D57);
    const Color safetyOrange = Color(0xFFE67E22);
    
    final String? uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: deepTeal,
        elevation: 0,
        centerTitle: true,
        title: Text("ملفي الشخصي", style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: const BackButton(color: Colors.white),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: deepTeal));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("لم يتم العثور على بيانات"));
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;
          String name = userData['name'] ?? "مستشار عقاري";
          String level = userData['level'] ?? "مبتدئ";
          String points = (userData['points'] ?? 0).toString();
          String experience = (userData['experience'] ?? "0").toString();

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 30),
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: deepTeal,
                  child: Icon(Icons.person, size: 60, color: Colors.white),
                ),
                const SizedBox(height: 15),
                Text(name, style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.bold)),
                Text(level, style: GoogleFonts.cairo(color: Colors.grey)),
                
                const SizedBox(height: 30),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatCard("نقاط الدوري", points, Colors.amber[800]!),
                    _buildStatCard("سنين الخبرة", experience, deepTeal),
                    _buildStatCard("المستوى", "ذهبي", safetyOrange),
                  ],
                ),
                
                const SizedBox(height: 30),
                const Divider(),
                
                _buildOption(Icons.emoji_events, "إنجازاتي في المسابقات"),
                _buildOption(Icons.history, "سجل الاختبارات"),
                _buildOption(Icons.settings, "إعدادات الحساب"),
                
                const SizedBox(height: 30),
                TextButton.icon(
                  onPressed: () => FirebaseAuth.instance.signOut(),
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text("تسجيل الخروج", style: TextStyle(color: Colors.red)),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: GoogleFonts.cairo(fontSize: 12)),
      ],
    );
  }

  Widget _buildOption(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1B4D57)),
      title: Text(title, style: GoogleFonts.cairo()),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
    );
  }
}
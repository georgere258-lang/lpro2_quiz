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
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: deepTeal));
          }

          var userData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          String name = userData['name'] ?? "مستشار عقاري";
          String level = userData['level'] ?? "مبتدئ عقاري";
          String points = (userData['points'] ?? 0).toString();
          String experience = (userData['experience'] ?? "0").toString();

          return Column(
            children: [
              // الهيدر المنحني مع صورة الملف الشخصي
              Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: deepTeal,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(50),
                        bottomRight: Radius.circular(50),
                      ),
                    ),
                    child: AppBar(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      centerTitle: true,
                      leading: const BackButton(color: Colors.white),
                      title: Text("ملفي الشخصي", 
                          style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  Positioned(
                    top: 130,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: const CircleAvatar(
                        radius: 60,
                        backgroundColor: Color(0xFFE0E0E0),
                        child: Icon(Icons.person, size: 70, color: deepTeal),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 65),
              
              // اسم المستخدم ومستواه
              Text(name, style: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.bold, color: deepTeal)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                decoration: BoxDecoration(
                  color: safetyOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(level, style: GoogleFonts.cairo(color: safetyOrange, fontWeight: FontWeight.bold, fontSize: 13)),
              ),

              const SizedBox(height: 30),

              // كارت الإحصائيات (نقاط، خبرة، رتبة)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem("النقاط", points, Icons.emoji_events_outlined, Colors.amber[700]!),
                      Container(height: 40, width: 1, color: Colors.grey[200]),
                      _buildStatItem("الخبرة", "$experience سنين", Icons.history_edu, deepTeal),
                      Container(height: 40, width: 1, color: Colors.grey[200]),
                      _buildStatItem("الرتبة", "#12", Icons.trending_up, Colors.blue),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // قائمة الخيارات بتصميم أنيق
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _buildMenuOption(Icons.settings_outlined, "إعدادات الحساب"),
                    _buildMenuOption(Icons.help_outline, "مركز المساعدة"),
                    _buildMenuOption(Icons.share_outlined, "دعوة زميل للبرنامج"),
                    const SizedBox(height: 10),
                    _buildLogoutButton(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 8),
        Text(value, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildMenuOption(IconData icon, String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF1B4D57)),
        title: Text(title, style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        onTap: () {},
      ),
    );
  }

  Widget _buildLogoutButton() {
    return TextButton(
      onPressed: () => FirebaseAuth.instance.signOut(),
      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.logout, color: Colors.redAccent, size: 20),
          const SizedBox(width: 10),
          Text("تسجيل الخروج", style: GoogleFonts.cairo(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'knowledge_screen.dart';
import 'quiz_screen.dart';
import 'practice_screen.dart'; 
import 'favorites_screen.dart';
import 'developers_screen.dart';
import 'master_plan_screen.dart'; // تم تفعيل الاستيراد الجديد

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
          builder: (context, snapshot) {
            String name = "مستخدم جديد";
            if (snapshot.hasData && snapshot.data!.exists) {
              name = snapshot.data!['name'] ?? "مستخدم جديد";
            }
            return Text("أهلاً، $name", 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF102A43)));
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () async => await FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("مركز الإحصائيات", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF102A43))),
            const SizedBox(height: 15),
            
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
              builder: (context, snapshot) {
                String points = "0";
                String level = "⚡ المنطلق";
                if (snapshot.hasData && snapshot.data!.exists) {
                  var data = snapshot.data!.data() as Map<String, dynamic>;
                  points = data['points']?.toString() ?? "0";
                  level = data['level']?.toString() ?? "⚡ المنطلق";
                }
                return Row(
                  children: [
                    Expanded(child: _buildStatCard("الرتبة: $level", "$points نقطة خبرة", Icons.workspace_premium_rounded, Colors.orange.shade800, () {})),
                    const SizedBox(width: 15),
                    Expanded(child: _buildStatCard("المحفوظات", "مقالات تهمك", Icons.bookmark_rounded, Colors.red.shade700, () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const FavoritesScreen()));
                    })),
                  ],
                );
              },
            ),
            
            const SizedBox(height: 30),
            const Text("الدليل الفني والمخططات", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF102A43))),
            const SizedBox(height: 15),

            // تفعيل زر الماستر بلان
            _buildWideCard(context, "الماستر بلان (Master Plan)", "شرح تفصيلي لخرائط وتقسيم المشاريع", Icons.layers_outlined, Colors.teal.shade700, const MasterPlanScreen()),
            const SizedBox(height: 15),

            _buildWideCard(context, "سجل المطورين العقاريين", "سابقة الأعمال، الملاك، والموقف القانوني", Icons.business_center_outlined, Colors.indigo.shade900, const DevelopersScreen()),
            
            const SizedBox(height: 30),
            const Text("أدوات التطوير والتعلم", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF102A43))),
            const SizedBox(height: 15),
            
            _buildWideCard(context, "الدليل العقاري الشامل", "تعرف على خريطة الاستثمار العقاري", Icons.map_rounded, const Color(0xFF102A43), const KnowledgeScreen()),
            const SizedBox(height: 15),
            _buildWideCard(context, "تنشيط المعلومات 💡", "راجع معلوماتك بسرعة وبدون خسارة نقاط", Icons.psychology_rounded, Colors.purple.shade700, const PracticeScreen()),
            const SizedBox(height: 15),
            _buildWideCard(context, "الدوري العقاري 🏆", "نافس الخبراء، اجمع النقاط وتصدر الترتيب", Icons.leaderboard_rounded, const Color(0xFFD68A1A), const QuizScreen()),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String sub, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildWideCard(BuildContext context, String title, String desc, IconData icon, Color color, Widget? target) {
    return InkWell(
      onTap: target == null ? () {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("جاري تجهيز هذا القسم...")));
      } : () => Navigator.push(context, MaterialPageRoute(builder: (context) => target)),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 15),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF102A43))),
              Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ])),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
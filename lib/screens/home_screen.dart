import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'quiz_screen.dart'; 
import 'master_plan_screen.dart';
import 'profile_screen.dart'; 
import 'leaderboard_screen.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final Color deepTeal = const Color(0xFF1B4D57);
  final Color safetyOrange = const Color(0xFFE67E22);
  
  // استدعاء الاسم الأول فقط لإعطاء لمسة شخصية ودودة
  final String userName = FirebaseAuth.instance.currentUser?.displayName?.split(' ')[0] ?? "مريم";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());
  }

  void _startScrolling() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(seconds: 15),
        curve: Curves.linear,
      ).then((_) {
        if (mounted) {
          _scrollController.jumpTo(0);
          _startScrolling();
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        backgroundColor: deepTeal,
        elevation: 0,
        centerTitle: true,
        title: Image.asset(
          'assets/top_brand.png', 
          height: 40, 
          errorBuilder: (c, e, s) => const Icon(Icons.business, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.account_circle_outlined, size: 28, color: Colors.white),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const ProfileScreen())),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events_outlined, color: Colors.amber, size: 28),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const LeaderboardScreen())),
          ),
        ],
      ),
      body: Column(
        children: [
          // شريط الأخبار المتحرك (الهوية البصرية)
          Container(
            height: 38, 
            color: safetyOrange,
            child: ListView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                Center(
                  child: Text(
                    "  📣 قريباً: تحديثات الماستر بلان لحي النرجس وبيت الوطن! 📣   |   🏆 مبروك لـ $userName تألقها في دوري العقارات 🏆   |   🚀 المعلومة بتفرق.. طور مهاراتك الآن! 🚀  ", 
                    style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("يا أهلاً بكِ يا $userName ✨", 
                    style: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.bold, color: deepTeal)),
                  Text("المعلومة بتفرق في كل صفقة جديدة.. 😉", 
                    style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey[700])),
                  
                  const SizedBox(height: 25),
                  
                  // كارت التميز
                  _buildFeatureCard(),

                  const SizedBox(height: 30),
                  
                  // شبكة الأقسام (تحديث الروابط)
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 15,
                    crossAxisSpacing: 15,
                    childAspectRatio: 1.1,
                    children: [
                      _buildGridCard("دوري النجوم", "🌱 لسه جديد", Icons.stars, Colors.blueGrey, 
                        const QuizScreen(categoryTitle: "دوري النجوم", isTextQuiz: false)),
                      
                      _buildGridCard("دوري المحترفين", "💪 يا كبير", Icons.military_tech, safetyOrange, 
                        const QuizScreen(categoryTitle: "دوري المحترفين", isTextQuiz: false)),
                      
                      // تحديث: نشط ذهنك أصبح MCQ لسرعة اللعب
                      _buildGridCard("نشط ذهنك", "🧠 فكر بسرعة", Icons.psychology, Colors.purple, 
                        const QuizScreen(categoryTitle: "نشط ذهنك", isTextQuiz: false)),
                      
                      _buildGridCard("الماستر بلان", "🗺️ تحدي الخرائط", Icons.map, deepTeal, 
                        const MasterPlanScreen()),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard() {
    return Container(
      width: double.infinity, 
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [deepTeal, deepTeal.withOpacity(0.8)]),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: deepTeal.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.amber, size: 40),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("تحدي اليوم", style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Text("كن أول من يحل تحدي الماستر بلان الجديد واجمع نقاط الضعف!", 
                  style: GoogleFonts.cairo(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridCard(String title, String sub, IconData icon, Color color, Widget screen) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => screen)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
          border: Border.all(color: Colors.grey.withOpacity(0.08)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(height: 10),
            Text(title, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14, color: deepTeal)),
            Text(sub, style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }
}
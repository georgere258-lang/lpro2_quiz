import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'quiz_screen.dart'; 
import 'master_plan_screen.dart';
import 'profile_screen.dart'; // استيراد ملف البيانات الحقيقية
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
  
  final String userName = FirebaseAuth.instance.currentUser?.displayName ?? "مريم";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());
  }

  void _startScrolling() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(seconds: 10),
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
      backgroundColor: const Color(0xFFF4F7F8),
      appBar: AppBar(
        backgroundColor: deepTeal,
        elevation: 0,
        centerTitle: true,
        title: Image.asset('assets/top_brand.png', height: 40, 
          errorBuilder: (c, e, s) => const Icon(Icons.business, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.account_circle, size: 32, color: Colors.white),
          // تم الربط بشاشة ProfileScreen الحقيقية لعرض النقاط والبيانات
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const ProfileScreen())),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events, color: Colors.amber),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const LeaderboardScreen())),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            height: 40, 
            color: safetyOrange,
            child: ListView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                Center(
                  child: Text(
                    "  📣 قريباً: تحديثات الماستر بلان لحي النرجس وبيت الوطن! 📣   |   🏆 مبروك لـ $userName تألقها في دوري العقارات 🏆  ", 
                    style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)
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
                    style: GoogleFonts.cairo(fontSize: 26, fontWeight: FontWeight.bold, color: deepTeal)),
                  const SizedBox(height: 5),
                  Text("مستعدة لنجاح جديد اليوم؟", 
                    style: GoogleFonts.cairo(fontSize: 16, color: Colors.grey[700])),
                  const SizedBox(height: 25),
                  
                  Container(
                    width: double.infinity, 
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: deepTeal, 
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: deepTeal.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]
                    ),
                    child: Text(
                      "المعلومة بتفرق! راجعي الأسئلة باستمرار لتبقي دائماً في صدارة وحوش العقارات. 😉",
                      textAlign: TextAlign.right, 
                      style: GoogleFonts.cairo(color: Colors.white, fontSize: 15, height: 1.4)
                    ),
                  ),

                  const SizedBox(height: 35),
                  
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
                      
                      _buildGridCard("نشط ذهنك", "🧠 فكر", Icons.psychology, Colors.purple, 
                        const QuizScreen(categoryTitle: "نشط ذهنك", isTextQuiz: true)),
                      
                      _buildGridCard("الماستر بلان", "🗺️ خرائط", Icons.map, deepTeal, 
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

  Widget _buildGridCard(String title, String sub, IconData icon, Color color, Widget screen) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => screen)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 40),
            const SizedBox(height: 8),
            Text(title, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15, color: deepTeal)),
            Text(sub, style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}
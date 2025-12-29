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
  
  int _currentIndex = 0;
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
      ),
      bottomNavigationBar: _buildBottomNavBar(),
      body: Column(
        children: [
          _buildMarqueeNews(),
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
                  _buildFeatureCard(),

                  // قسم الإحصائيات الجديد لاستغلال المساحة
                  const SizedBox(height: 25),
                  Row(
                    children: [
                      _buildSmallStatCard("نقاطك", "١,٢٥٠", Icons.stars, Colors.amber),
                      const SizedBox(width: 12),
                      _buildSmallStatCard("ترتيبك", "#١٢", Icons.leaderboard, Colors.blueAccent),
                      const SizedBox(width: 12),
                      _buildSmallStatCard("المستوى", "خبير", Icons.workspace_premium, Colors.purple),
                    ],
                  ),

                  const SizedBox(height: 30),
                  _buildGridMenu(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // شريط الأخبار المتحرك
  Widget _buildMarqueeNews() {
    return Container(
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
    );
  }

  // ويجيت الإحصائيات الصغيرة
  Widget _buildSmallStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))],
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: deepTeal)),
            Text(title, style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // قائمة المسابقات (Grid)
  Widget _buildGridMenu() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 18,
      crossAxisSpacing: 18,
      childAspectRatio: 0.85, 
      children: [
        _buildGridCard("دوري النجوم", "🌱 ابدأ رحلتك", Icons.stars_rounded, const Color(0xFF3498DB), 
          "https://images.unsplash.com/photo-1512917774080-9991f1c4c750?q=80&w=500", 
          const QuizScreen(categoryTitle: "دوري النجوم")),
        _buildGridCard("دوري المحترفين", "💪 يا كبير", Icons.workspace_premium_rounded, safetyOrange, 
          "https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?q=80&w=500", 
          const QuizScreen(categoryTitle: "دوري المحترفين")),
        _buildGridCard("نشط ذهنك", "🧠 فكر بسرعة", Icons.bolt_rounded, Colors.purpleAccent, 
          "https://images.unsplash.com/photo-1558403194-611308249627?q=80&w=500", 
          const QuizScreen(categoryTitle: "نشط ذهنك")),
        _buildGridCard("الماستر بلان", "🗺️ تحدي الخرائط", Icons.map_rounded, const Color(0xFF2ECC71), 
          "https://images.unsplash.com/photo-1503387762-592dea58ef23?q=80&w=500", 
          const MasterPlanScreen()),
      ],
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: const BoxDecoration(boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)]),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 1) Navigator.push(context, MaterialPageRoute(builder: (c) => const LeaderboardScreen()));
          if (index == 2) Navigator.push(context, MaterialPageRoute(builder: (c) => const MasterPlanScreen()));
          if (index == 3) Navigator.push(context, MaterialPageRoute(builder: (c) => const ProfileScreen()));
        },
        selectedItemColor: safetyOrange,
        unselectedItemColor: deepTeal.withOpacity(0.5),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_max_rounded), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events_rounded), label: 'المتصدرين'),
          BottomNavigationBarItem(icon: Icon(Icons.map_rounded), label: 'الخرائط'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'حسابي'),
        ],
      ),
    );
  }

  Widget _buildFeatureCard() {
    return Container(
      width: double.infinity, 
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [deepTeal, deepTeal.withOpacity(0.85)]),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: deepTeal.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))]
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

  Widget _buildGridCard(String title, String sub, IconData icon, Color color, String imageUrl, Widget screen) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => screen)),
      borderRadius: BorderRadius.circular(25),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: Stack(
            children: [
              Positioned.fill(child: Image.network(imageUrl, fit: BoxFit.cover)),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black.withOpacity(0.1), Colors.black.withOpacity(0.85)],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: color.withOpacity(0.9), shape: BoxShape.circle),
                      child: Icon(icon, color: Colors.white, size: 24),
                    ),
                    const SizedBox(height: 10),
                    Text(title, style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                      child: Text(sub, style: GoogleFonts.cairo(color: Colors.white.withOpacity(0.9), fontSize: 10)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
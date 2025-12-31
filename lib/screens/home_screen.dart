import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'quiz_screen.dart';
import 'master_plan_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final Color deepTeal = const Color(0xFF1B4D57);
  final Color safetyOrange = const Color(0xFFE67E22);
  final User? user = FirebaseAuth.instance.currentUser;

  late AnimationController _newsController;
  late Animation<Offset> _newsAnimation;

  final List<String> _newsItems = [
    "🚀 المعلومة بتفرق.. طور مهاراتك العقارية الآن!",
    "🏆 مبروك لـ جورج تألقها في دوري العقارات!",
    "📢 قريباً: تحديثات ضخمة في مناطق النرجس وبيت الوطن!",
  ];

  @override
  void initState() {
    super.initState();
    // سرعة انسيابية مريحة للعين (30 ثانية للدورة الواحدة)
    _newsController =
        AnimationController(duration: const Duration(seconds: 30), vsync: this)
          ..repeat();

    _newsAnimation =
        Tween<Offset>(begin: const Offset(1.0, 0), end: const Offset(-2.5, 0))
            .animate(_newsController);
  }

  @override
  void dispose() {
    _newsController.dispose();
    super.dispose();
  }

  Stream<int> getUserRank() {
    return FirebaseFirestore.instance
        .collection('users')
        .orderBy('points', descending: true)
        .snapshots()
        .map((snapshot) {
      int index = snapshot.docs.indexWhere((doc) => doc.id == user?.uid);
      return index != -1 ? index + 1 : 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    String userName = user?.displayName?.split(' ')[0] ?? "جورج";
    String fullTickerText = _newsItems.join("      |      ");

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      // ملاحظة: تم حذف الـ AppBar من هنا ليعتمد التطبيق على اللوجو الموجود في الـ MainWrapper منعاً للتكرار
      body: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user?.uid)
              .snapshots(),
          builder: (context, snapshot) {
            int userPoints = 0;
            if (snapshot.hasData && snapshot.data!.exists) {
              var data = snapshot.data!.data() as Map<String, dynamic>;
              userPoints = data['points'] ?? 0;
              userName = data['name'] ?? userName;
            }

            return Column(
              children: [
                // 1. شريط الأخبار: ملتصق بالهيدر العلوي تماماً
                Container(
                  width: double.infinity,
                  height: 30,
                  color: safetyOrange,
                  child: ClipRect(
                    child: SlideTransition(
                      position: _newsAnimation,
                      child: Center(
                        child: Text(
                          fullTickerText,
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                          softWrap: false,
                        ),
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // الترحيب
                          Text("يا أهلاً بكِ يا $userName ✨",
                              style: GoogleFonts.cairo(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: deepTeal)),
                          Text(
                              "المعلومة بتفرق.. جاهزة لتحدي جديد يرفع سكورك؟ 🚀",
                              style: GoogleFonts.cairo(
                                  fontSize: 14, color: Colors.grey[700])),

                          const SizedBox(height: 25),

                          // كارت معلومة في السريع
                          _buildQuickInfoCard(),

                          const SizedBox(height: 20),

                          // كارت تحدي اليوم
                          _buildFeatureCard(),

                          const SizedBox(height: 25),

                          // قسم الإحصائيات (المربعات البيضاء)
                          Row(
                            children: [
                              _buildStatBox("نقاطك", "$userPoints", Icons.stars,
                                  Colors.amber),
                              const SizedBox(width: 12),
                              StreamBuilder<int>(
                                  stream: getUserRank(),
                                  builder: (context, rankSnapshot) {
                                    String rank = rankSnapshot.hasData
                                        ? "#${rankSnapshot.data}"
                                        : "...";
                                    return _buildStatBox(
                                        "الترتيب",
                                        rank,
                                        Icons.bar_chart_rounded,
                                        Colors.blueAccent);
                                  }),
                              const SizedBox(width: 12),
                              _buildStatBox(
                                  "المستوى",
                                  userPoints > 100 ? "خبير" : "مبتدئ",
                                  Icons.workspace_premium,
                                  Colors.purple),
                            ],
                          ),

                          const SizedBox(height: 30),

                          // كروت الأقسام (تنسيق الصور والأشرطة جهة اليمين)
                          _buildGridMenu(),

                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
    );
  }

  Widget _buildQuickInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: safetyOrange.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15)
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text("معلومة في السريع",
                        style: GoogleFonts.cairo(
                            fontWeight: FontWeight.bold,
                            color: deepTeal,
                            fontSize: 17)),
                    const SizedBox(width: 5),
                    const Icon(Icons.lightbulb, color: Colors.amber, size: 20),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                    "الاستثمار التجاري الناجح يبدأ من دراسة الـ Footfall (كثافة المشاة) حول المول.",
                    style: GoogleFonts.cairo(
                        color: Colors.black87, fontSize: 13, height: 1.5)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            backgroundColor: safetyOrange.withOpacity(0.1),
            radius: 25,
            child: Icon(Icons.insights, color: safetyOrange),
          )
        ],
      ),
    );
  }

  Widget _buildStatBox(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(value,
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: deepTeal)),
            Text(title,
                style: GoogleFonts.cairo(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: const Color(0xFF2C5F6A),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
                color: deepTeal.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8))
          ]),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.amber, size: 35),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("كن أول من يحل تحدي الماستر بلان الجديد",
                    style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                Text("واجمع نقاط الضعف!",
                    style:
                        GoogleFonts.cairo(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridMenu() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 18,
      crossAxisSpacing: 18,
      childAspectRatio: 0.85,
      children: [
        _buildGridCard(
            "دوري النجوم",
            "✨ Fresh",
            Colors.blue,
            "https://images.unsplash.com/photo-1512917774080-9991f1c4c750?q=80&w=500",
            const QuizScreen(categoryTitle: "دوري النجوم")),
        _buildGridCard(
            "دوري المحترفين",
            "🔥 Pro",
            Colors.orange,
            "https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?q=80&w=500",
            const QuizScreen(categoryTitle: "دوري المحترفين")),
        _buildGridCard(
            "نشط ذهنك",
            "🧠 Mind",
            Colors.purpleAccent,
            "https://images.unsplash.com/photo-1558403194-611308249627?q=80&w=500",
            const QuizScreen(categoryTitle: "نشط ذهنك")),
        _buildGridCard(
            "الماستر بلان",
            "🗺️ Maps",
            Colors.green,
            "https://images.unsplash.com/photo-1503387762-592dea58ef23?q=80&w=500",
            const MasterPlanScreen()),
      ],
    );
  }

  Widget _buildGridCard(String title, String badgeText, Color badgeColor,
      String imageUrl, Widget screen) {
    return InkWell(
      onTap: () =>
          Navigator.push(context, MaterialPageRoute(builder: (c) => screen)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: Stack(
            children: [
              Positioned.fill(
                  child: Image.network(imageUrl, fit: BoxFit.cover)),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.85)
                      ],
                    ),
                  ),
                ),
              ),
              // التعديل المطلوب: البادج والعنوان في أقصى اليمين (Right: 15) تماماً كالصورة
              Positioned(
                bottom: 15,
                right: 15,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.end, // دفع كل المحتوى لليمين
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(10)),
                      child: Text(badgeText,
                          style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 6),
                    Text(title,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
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

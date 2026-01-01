import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

// استيراد الشاشات المطلوبة
import 'quiz_screen.dart';
import 'about_screen.dart';
import 'admin_panel.dart';

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

  final List<String> friendlyPrompts = [
    "لو فيك دماغ، بص بصة على خريطة 'بيت الوطن' وقارنها بمدينتي.. المعلومة دي سلاحك الجاي! 🏗️",
    "إيه رأيك تراجع مشروعين النهاردة؟ بجد هيفرقوا جداً في طريقتك وأنت بتشرح للعميل. ✨",
    "لو فضيت شوية، ألقي نظرة على تطورات العاصمة.. فيها فرص لو عرفتها هتسبق الكل! 🚀",
    "بيني وبينك.. مراجعة 'الماستر بلان' النهاردة هتخليك وحش في الميتنج الجاي! 💪",
    "لو جالك مزاج، شوف الفرق بين أسعار التجمع وزايد النهاردة.. خليك دايماً سابق بخطوة. 🗺️",
  ];

  late String currentPrompt;

  @override
  void initState() {
    super.initState();
    _newsController =
        AnimationController(duration: const Duration(seconds: 18), vsync: this)
          ..repeat();
    _newsAnimation =
        Tween<Offset>(begin: const Offset(1.2, 0), end: const Offset(-1.2, 0))
            .animate(_newsController);
    currentPrompt = friendlyPrompts[Random().nextInt(friendlyPrompts.length)];
  }

  @override
  void dispose() {
    _newsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        String name = "بطل Pro";
        String role = "user";

        if (snapshot.hasData && snapshot.data!.exists) {
          var data = snapshot.data!.data() as Map<String, dynamic>;
          name = data['name'] ?? "بطل Pro";
          role = data['role'] ?? "user";
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF4F7F8),
          // تمت إزالة AppBar من هنا لاعتماده في الـ MainWrapper
          drawer: _buildDrawer(context, role),
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              children: [
                _buildUltraSlimTicker(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(
                            height: 20), // تقليل المسافة لتناسب الهيدر الثابت
                        _buildHeaderWithMenu(context, name),
                        const SizedBox(height: 25),
                        _buildQuickFact(),
                        const SizedBox(height: 15),
                        _buildFriendlyEncouragement(),
                        const SizedBox(height: 35),
                        Text(
                          "من يملك المعلومة.. يملك القوة",
                          style: GoogleFonts.cairo(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            color: deepTeal,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 15),
                        _buildPremiumGrid(),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderWithMenu(BuildContext context, String name) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("أهلاً بك يا $name ✨",
                  style: GoogleFonts.cairo(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: deepTeal)),
              Text("خطوة جديدة لتعزيز مكانتك كخبير..",
                  style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        Builder(builder: (context) {
          return IconButton(
            icon: Icon(Icons.menu_open_rounded, color: deepTeal, size: 32),
            onPressed: () => Scaffold.of(context).openDrawer(),
          );
        }),
      ],
    );
  }

  Widget _buildUltraSlimTicker() {
    return Container(
      height: 28,
      width: double.infinity,
      color: safetyOrange,
      child: SlideTransition(
        position: _newsAnimation,
        child: Center(
          child: Text(
            "⚡ آخر تحديثات السوق: ارتفاع الطلب على التجمع الخامس.. معلومة تهمك!",
            style: GoogleFonts.cairo(
                color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, String role) {
    return Drawer(
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: deepTeal),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.stars_rounded, color: safetyOrange, size: 40),
              ),
              accountName: Text(
                "أبطال Pro",
                style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold, fontSize: 18),
              ),
              accountEmail: const Text("نخبة المستشارين العقاريين"),
            ),
            _buildDrawerItem(
                Icons.info_outline,
                "حول أبطال Pro",
                () => Navigator.push(context,
                    MaterialPageRoute(builder: (c) => const AboutScreen()))),
            if (role.contains("admin"))
              _buildDrawerItem(
                  Icons.admin_panel_settings_outlined,
                  "لوحة التحكم (للأدمن)",
                  () => Navigator.push(context,
                      MaterialPageRoute(builder: (c) => const AdminPanel())),
                  color: safetyOrange),
            const Spacer(),
            const Divider(),
            _buildDrawerItem(Icons.logout, "تسجيل الخروج",
                () => FirebaseAuth.instance.signOut(),
                color: Colors.redAccent),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap,
      {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? deepTeal),
      title: Text(title,
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14)),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  Widget _buildQuickFact() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.withOpacity(0.15))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Text("معلومة في السريع",
                  style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: safetyOrange)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
              "المستشار العقاري الناجح لا يبيع وحدات، بل يبيع 'مستقبلاً آمناً' بناءً على أرقام دقيقة.",
              style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: Colors.black87,
                  height: 1.5,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildFriendlyEncouragement() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [deepTeal, const Color(0xFF2C5F6A)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
                color: deepTeal.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8))
          ]),
      child: Row(
        children: [
          const Icon(Icons.forum_outlined, color: Colors.amber, size: 28),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("بيني وبينك.. ✨",
                    style: GoogleFonts.cairo(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(currentPrompt,
                    style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 15,
      crossAxisSpacing: 15,
      childAspectRatio: 0.82,
      children: [
        _buildImageCard("دوري النجوم", "Fresh ✨", const Color(0xFF3498DB),
            "stars.png", "دوري النجوم"),
        _buildImageCard("دوري المحترفين", "Pro 🔥", const Color(0xFFE67E22),
            "pro.png", "دوري المحترفين"),
        _buildImageCard("المعلومة بتفرق", "Data 💡", const Color(0xFF1ABC9C),
            "info.png", "المعلومة بتفرق"),
        _buildImageCard("الماستر بلان", "Maps 🗺️", const Color(0xFFE74C3C),
            "map.png", "الماستر بلان"),
      ],
    );
  }

  Widget _buildImageCard(String title, String badge, Color color,
      String imageName, String category) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (c) => QuizScreen(categoryTitle: category))),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          image: DecorationImage(
              image: AssetImage("assets/card_images/$imageName"),
              fit: BoxFit.cover),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4))
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.85)]),
          ),
          padding:
              const EdgeInsets.only(right: 15, left: 15, bottom: 20, top: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(8)),
                child: Text(badge,
                    style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900)),
              ),
              const SizedBox(height: 12),
              Text(title,
                  style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      height: 1.1)),
            ],
          ),
        ),
      ),
    );
  }
}

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // تمت إزالة AppBar هنا أيضاً لأن الهيدر في الـ Wrapper ثابت
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy('points', descending: true)
            .limit(20)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          var users = snapshot.data!.docs;

          return Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              children: [
                const SizedBox(height: 10),
                if (users.length >= 3) _buildPodium(users.take(3).toList()),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: users.length > 3 ? users.length - 3 : 0,
                    itemBuilder: (context, index) {
                      var user = users[index + 3];
                      return _buildLeaderboardTile(user, index + 4);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPodium(List<DocumentSnapshot> topThree) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      color: const Color(0xFFF4F7F8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildPodiumItem(topThree[1], "2", 70, Colors.grey[400]!),
          _buildPodiumItem(topThree[0], "1", 100, Colors.amber),
          _buildPodiumItem(topThree[2], "3", 60, Colors.brown[400]!),
        ],
      ),
    );
  }

  Widget _buildPodiumItem(
      DocumentSnapshot user, String rank, double height, Color color) {
    var data = user.data() as Map<String, dynamic>;
    return Column(
      children: [
        CircleAvatar(
          radius: height / 2.5,
          backgroundColor: color,
          child: CircleAvatar(
            radius: (height / 2.5) - 3,
            backgroundColor: Colors.white,
            backgroundImage: data['photoUrl'] != null
                ? NetworkImage(data['photoUrl'])
                : null,
            child: data['photoUrl'] == null ? const Icon(Icons.person) : null,
          ),
        ),
        const SizedBox(height: 8),
        Text(data['name'] ?? "بطل",
            style:
                GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12)),
        Text("${data['points'] ?? 0} نقطة",
            style: GoogleFonts.poppins(color: Colors.grey, fontSize: 10)),
        const SizedBox(height: 10),
        Container(
          width: 60,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
          ),
          child: Center(
            child: Text(rank,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
          ),
        )
      ],
    );
  }

  Widget _buildLeaderboardTile(DocumentSnapshot user, int rank) {
    var data = user.data() as Map<String, dynamic>;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.grey[200],
        child: Text("#$rank",
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ),
      title: Text(data['name'] ?? "بطل Pro",
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
      subtitle: Text("${data['points'] ?? 0} نقطة",
          style: GoogleFonts.poppins(fontSize: 12)),
      trailing: data['photoUrl'] != null
          ? CircleAvatar(backgroundImage: NetworkImage(data['photoUrl']))
          : const Icon(Icons.account_circle, color: Colors.grey),
    );
  }
}

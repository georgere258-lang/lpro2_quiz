import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // --- ميثاق ألوان باكدج 3 المعتمد (LPro Deep Teal) ---
  static const Color deepTeal = Color(0xFF005F6B);     // اللون القائد
  static const Color safetyOrange = Color(0xFFFF8C00); // لون المثلث والتميز
  static const Color iceWhite = Color(0xFFF8F9FA);     // الخلفية الأساسية
  static const Color darkTealText = Color(0xFF002D33); // نصوص العناوين

  // بيانات افتراضية (سيتم جلبها من Firebase لاحقاً)
  String userName = "مريم جرجس";
  String userPhone = "+20 101 234 5678";
  int userCoins = 150;
  String userRank = "برو جونيور 🐣";

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: iceWhite,
      body: CustomScrollView(
        slivers: [
          // 1. الهيدر الفيروزي العميق: تم ضبطه ليعكس الفخامة المطلوبة
          _buildProfileHeader(),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // 2. كارت الإحصائيات المحدث (النقاط والرتبة)
                  _buildStatsCard(),
                  const SizedBox(height: 25),
                  
                  // 3. قائمة الإعدادات الاحترافية
                  _buildInfoSection(),
                  const SizedBox(height: 25),
                  
                  // 4. زر تسجيل الخروج
                  _buildLogoutButton(),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: deepTeal,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          alignment: Alignment.center,
          children: [
            // تدرج الخلفية المطابق للسبلاش سكرين
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [deepTeal, Color(0xFF003D45)],
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                // إطار الصورة البرتقالي (Safety Orange) - رمز التميز
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: safetyOrange, 
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)]
                  ),
                  child: const CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person_rounded, size: 60, color: deepTeal),
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  userName,
                  style: GoogleFonts.cairo(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                ),
                // [المطلوب]: الجملة التحفيزية الخاصة بالملف الشخصي
                Text(
                  "خبير عقاري طموح في LPro 🏆",
                  style: GoogleFonts.cairo(color: safetyOrange, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(
                  userPhone,
                  style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: deepTeal.withOpacity(0.08), 
            blurRadius: 15, 
            offset: const Offset(0, 5)
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem("رصيد النقاط", "$userCoins", Icons.stars_rounded),
          Container(width: 1, height: 40, color: Colors.grey[100]),
          _buildStatItem("المستوى الحالي", userRank, Icons.emoji_events_rounded),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: safetyOrange, size: 28),
        const SizedBox(height: 5),
        Text(label, style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey[600])),
        Text(value, style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: darkTealText)),
      ],
    );
  }

  Widget _buildInfoSection() {
    return Column(
      children: [
        _buildMenuTile("تعديل البيانات الشخصية", Icons.edit_note_rounded),
        _buildMenuTile("سجل التحديات والمنافسات", Icons.history_rounded),
        _buildMenuTile("تنبيهات الدوري العقاري", Icons.notifications_active_outlined),
        _buildMenuTile("تغيير لغة التطبيق", Icons.translate_rounded),
        _buildMenuTile("دعم LPro الفني", Icons.support_agent_rounded),
      ],
    );
  }

  Widget _buildMenuTile(String title, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: Icon(icon, color: deepTeal),
        title: Text(title, style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w600, color: darkTealText)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: safetyOrange),
        onTap: () {},
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: _logout,
        icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
        label: Text(
          "تسجيل الخروج من الحساب",
          style: GoogleFonts.cairo(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.all(15),
          backgroundColor: Colors.redAccent.withOpacity(0.05),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
      ),
    );
  }
}
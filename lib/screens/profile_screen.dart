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
  // الألوان الموحدة
  static const Color brandOrange = Color(0xFFC67C32);
  static const Color navyDeep = Color(0xFF1E2B3E);
  static const Color iceGray = Color(0xFFF2F4F7);

  // بيانات افتراضية (سيتم جلبها من السيرفر لاحقاً)
  String userName = "مريم جرجس";
  String userPhone = "+20 101 234 5678";
  int userCoins = 150;
  String userRank = "برو جونيور 🐣";

  // دالة تسجيل الخروج
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
      backgroundColor: iceGray,
      body: CustomScrollView(
        slivers: [
          // 1. الهيدر المتطور مع الصورة
          _buildProfileHeader(),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // 2. كارت الإحصائيات (الكوينات والرتبة)
                  _buildStatsCard(),
                  const SizedBox(height: 25),
                  
                  // 3. قائمة الإعدادات والمعلومات
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
      backgroundColor: navyDeep,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          alignment: Alignment.center,
          children: [
            // تدرج الخلفية
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [navyDeep, Color(0xFF2C3E50)],
                ),
              ),
            ),
            // محتوى الهيدر
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                // إطار الصورة الذهبي
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: brandOrange, shape: BoxShape.circle),
                  child: const CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 60, color: navyDeep),
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  userName,
                  style: GoogleFonts.cairo(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                ),
                Text(
                  userPhone,
                  style: GoogleFonts.poppins(color: Colors.white60, fontSize: 14),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem("رصيدك", "$userCoins", Icons.stars_rounded),
          Container(width: 1, height: 40, color: Colors.grey[200]),
          _buildStatItem("الرتبة", userRank, Icons.emoji_events_rounded),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: brandOrange, size: 28),
        const SizedBox(height: 5),
        Text(label, style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey)),
        Text(value, style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: navyDeep)),
      ],
    );
  }

  Widget _buildInfoSection() {
    return Column(
      children: [
        _buildMenuTile("تعديل الملف الشخصي", Icons.edit_note_rounded),
        _buildMenuTile("سجل النشاطات", Icons.history_rounded),
        _buildMenuTile("الإشعارات", Icons.notifications_active_outlined),
        _buildMenuTile("تغيير اللغة", Icons.translate_rounded),
        _buildMenuTile("الدعم الفني", Icons.support_agent_rounded),
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
        leading: Icon(icon, color: navyDeep),
        title: Text(title, style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: brandOrange),
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
          "تسجيل الخروج",
          style: GoogleFonts.cairo(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.all(15),
          backgroundColor: Colors.redAccent.withOpacity(0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
      ),
    );
  }
}
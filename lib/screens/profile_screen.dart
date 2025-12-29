import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // الألوان الثابتة للهوية
  static const Color deepTeal = Color(0xFF1B4D57);
  static const Color safetyOrange = Color(0xFFE67E22);
  static const Color iceWhite = Color(0xFFF8F9FA);

  // دالة تحديث البيانات (حافظنا عليها كما هي في كودك)
  Future<void> _updateUserData(BuildContext context, String field, String currentValue) async {
    final TextEditingController editController = TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: Text("تعديل ${field == 'name' ? 'الاسم' : 'الخبرة'}", 
            textAlign: TextAlign.right, style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: editController,
          textAlign: TextAlign.right,
          keyboardType: field == 'experience' ? TextInputType.number : TextInputType.text,
          inputFormatters: field == 'experience' ? [FilteringTextInputFormatter.digitsOnly] : [],
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("إلغاء", style: GoogleFonts.cairo(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: deepTeal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final uid = FirebaseAuth.instance.currentUser?.uid;
              await FirebaseFirestore.instance.collection('users').doc(uid).update({
                field: editController.text.trim(),
              });
              Navigator.pop(context);
            },
            child: Text("حفظ", style: GoogleFonts.cairo(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: iceWhite,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: deepTeal));
          }

          var userData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          String name = userData['name'] ?? "مستشار عقاري";
          String level = userData['level'] ?? "مبتدئ عقاري";
          String points = (userData['points'] ?? 0).toString();
          String experience = (userData['experience'] ?? "0").toString();

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(context, name, level),
                const SizedBox(height: 30),
                _buildStatsCard(context, points, experience),
                const SizedBox(height: 30),
                _buildMenuSection(),
                const SizedBox(height: 20),
                _buildLogoutButton(),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  // ويجيت الرأس المطور (Gradient + Avatar)
  Widget _buildHeader(BuildContext context, String name, String level) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [deepTeal, Color(0xFF0D2A30)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(50)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 50),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const BackButton(color: Colors.white),
                Text("ملفي الشخصي", style: GoogleFonts.cairo(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(width: 48), // لموازنة المكان
              ],
            ),
          ),
          const SizedBox(height: 20),
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                child: CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 65, color: deepTeal.withOpacity(0.8)),
                ),
              ),
              Positioned(
                bottom: 5,
                right: 5,
                child: GestureDetector(
                  onTap: () => _updateUserData(context, 'name', name),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: safetyOrange, shape: BoxShape.circle),
                    child: const Icon(Icons.edit, color: Colors.white, size: 15),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(name, style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 30),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
            child: Text(level, style: GoogleFonts.cairo(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  // كارت الإحصائيات (النقاط، الخبرة، الرتبة)
  Widget _buildStatsCard(BuildContext context, String points, String experience) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 25),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatItem("النقاط", points, Icons.stars, Colors.amber[700]!),
            _buildDivider(),
            GestureDetector(
              onTap: () => _updateUserData(context, 'experience', experience),
              child: _buildStatItem("الخبرة", experience, Icons.business_center, deepTeal, suffix: " عام"),
            ),
            _buildDivider(),
            _buildStatItem("الرتبة", "12", Icons.emoji_events, Colors.blue, prefix: "#"),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() => Container(height: 35, width: 1.5, color: Colors.grey[100]);

  Widget _buildStatItem(String label, String value, IconData icon, Color color, {String suffix = "", String prefix = ""}) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 10),
        RichText(
          text: TextSpan(
            style: GoogleFonts.poppins(color: deepTeal, fontWeight: FontWeight.bold, fontSize: 18),
            children: [
              if (prefix.isNotEmpty) TextSpan(text: prefix),
              TextSpan(text: value),
              if (suffix.isNotEmpty) TextSpan(text: suffix, style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.normal)),
            ],
          ),
        ),
        Text(label, style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w600)),
      ],
    );
  }

  // قائمة الخيارات
  Widget _buildMenuSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        children: [
          _buildMenuTile(Icons.settings_outlined, "إعدادات الحساب"),
          _buildMenuTile(Icons.help_outline_rounded, "مركز المساعدة والدعم"),
          _buildMenuTile(Icons.share_outlined, "دعوة زميل للبرنامج"),
        ],
      ),
    );
  }

  Widget _buildMenuTile(IconData icon, String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.withOpacity(0.05)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: deepTeal.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: deepTeal, size: 20),
        ),
        title: Text(title, style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600, color: deepTeal)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
        onTap: () {},
      ),
    );
  }

  Widget _buildLogoutButton() {
    return TextButton.icon(
      onPressed: () => FirebaseAuth.instance.signOut(),
      icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
      label: Text("تسجيل الخروج", style: GoogleFonts.cairo(color: Colors.redAccent, fontWeight: FontWeight.bold)),
    );
  }
}
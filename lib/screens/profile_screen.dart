import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const Color deepTeal = Color(0xFF1B4D57);
  static const Color safetyOrange = Color(0xFFE67E22);
  static const Color iceWhite = Color(0xFFF8F9FA);

  // دالة لجلب الترتيب الفعلي من الفايربيز
  Stream<int> _getUserRank(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .orderBy('points', descending: true)
        .snapshots()
        .map((snapshot) {
      int index = snapshot.docs.indexWhere((doc) => doc.id == uid);
      return index != -1 ? index + 1 : 0;
    });
  }

  Future<void> _updateUserData(
      BuildContext context, String field, String currentValue) async {
    final TextEditingController editController =
        TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: Text("تعديل ${field == 'name' ? 'الاسم' : 'سنوات الخبرة'}",
            textAlign: TextAlign.right,
            style:
                GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: editController,
          textAlign: TextAlign.right,
          keyboardType:
              field == 'experience' ? TextInputType.number : TextInputType.text,
          inputFormatters: field == 'experience'
              ? [FilteringTextInputFormatter.digitsOnly]
              : [],
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final uid = FirebaseAuth.instance.currentUser?.uid;
              if (uid != null) {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .update({
                  field: field == 'experience'
                      ? int.parse(editController.text)
                      : editController.text.trim(),
                });
              }
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
        stream:
            FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: deepTeal));
          }

          var userData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          String name = userData['name'] ?? "مستشار عقاري";
          String level = userData['level'] ?? "وحش العقارات المتألق";
          String points = (userData['points'] ?? 0).toString();
          String experience = (userData['experience'] ?? "0").toString();

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(context, name, level),
                const SizedBox(height: 30),
                _buildStatsCard(context, uid!, points, experience),
                const SizedBox(height: 30),
                _buildMenuSection(),
                const SizedBox(height: 20),
                _buildLogoutButton(context),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

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
          const SizedBox(height: 60),
          Text("ملفي الشخصي",
              style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 25),
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                    color: Colors.white24, shape: BoxShape.circle),
                child: CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person,
                      size: 65, color: deepTeal.withOpacity(0.8)),
                ),
              ),
              Positioned(
                bottom: 5,
                right: 5,
                child: GestureDetector(
                  onTap: () => _updateUserData(context, 'name', name),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                        color: safetyOrange, shape: BoxShape.circle),
                    child:
                        const Icon(Icons.edit, color: Colors.white, size: 16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(name,
              style: GoogleFonts.cairo(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 40),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20)),
            child: Text(level,
                style: GoogleFonts.cairo(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(
      BuildContext context, String uid, String points, String experience) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 25),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 10))
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatItem("النقاط", points, Icons.stars, Colors.amber[700]!),
            _buildDivider(),
            GestureDetector(
              onTap: () => _updateUserData(context, 'experience', experience),
              child: _buildStatItem(
                  "الخبرة", experience, Icons.business_center, deepTeal,
                  suffix: " عام"),
            ),
            _buildDivider(),
            StreamBuilder<int>(
                stream: _getUserRank(uid),
                builder: (context, rankSnapshot) {
                  String rank = rankSnapshot.hasData
                      ? rankSnapshot.data.toString()
                      : "..";
                  return _buildStatItem(
                      "الرتبة", rank, Icons.emoji_events, Colors.blue,
                      prefix: "#");
                }),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() =>
      Container(height: 35, width: 1.5, color: Colors.grey[100]);

  Widget _buildStatItem(String label, String value, IconData icon, Color color,
      {String suffix = "", String prefix = ""}) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 10),
        RichText(
          text: TextSpan(
            style: GoogleFonts.poppins(
                color: deepTeal, fontWeight: FontWeight.bold, fontSize: 18),
            children: [
              if (prefix.isNotEmpty) TextSpan(text: prefix),
              TextSpan(text: value),
              if (suffix.isNotEmpty)
                TextSpan(
                    text: suffix,
                    style: GoogleFonts.cairo(
                        fontSize: 12, fontWeight: FontWeight.normal)),
            ],
          ),
        ),
        Text(label,
            style: GoogleFonts.cairo(
                fontSize: 11,
                color: Colors.grey[500],
                fontWeight: FontWeight.w600)),
      ],
    );
  }

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
          decoration: BoxDecoration(
              color: deepTeal.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: deepTeal, size: 20),
        ),
        title: Text(title,
            style: GoogleFonts.cairo(
                fontSize: 14, fontWeight: FontWeight.w600, color: deepTeal)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded,
            size: 14, color: Colors.grey),
        onTap: () {},
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return TextButton.icon(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("تسجيل الخروج",
                textAlign: TextAlign.right,
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            content: Text("هل أنت متأكد أنك تريد مغادرة عالم وحوش العقارات؟",
                textAlign: TextAlign.right, style: GoogleFonts.cairo()),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("إلغاء",
                      style: GoogleFonts.cairo(color: Colors.grey))),
              TextButton(
                onPressed: () {
                  FirebaseAuth.instance.signOut().then((_) {
                    Navigator.of(context)
                        .pushNamedAndRemoveUntil('/login', (route) => false);
                  });
                },
                child: Text("خروج",
                    style: GoogleFonts.cairo(
                        color: Colors.redAccent, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
      icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
      label: Text("تسجيل الخروج",
          style: GoogleFonts.cairo(
              color: Colors.redAccent, fontWeight: FontWeight.bold)),
    );
  }
}

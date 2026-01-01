import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

// تأكدي من استيراد هذه الشاشات
import 'about_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final Color deepTeal = const Color(0xFF1B4D57);

  // 1. تسجيل الخروج
  Future<void> _handleLogout() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "تسجيل الخروج",
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "هل أنت متأكد أنك تريد مغادرة تطبيق أبطال Pro؟",
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text("إلغاء"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(c, true),
            child: Text("خروج", style: GoogleFonts.cairo(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  // 2. تعديل الاسم
  void _showEditDialog(String currentName) {
    TextEditingController nameEdit = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text("تعديل الاسم", style: GoogleFonts.cairo()),
        content: TextField(
          controller: nameEdit,
          decoration: const InputDecoration(hintText: "اكتب اسمك الجديد"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text("إلغاء"),
          ),
          ElevatedButton(
            onPressed: () async {
              String newName = nameEdit.text.trim();
              if (newName.isNotEmpty) {
                // تحديث الاسم في Auth
                await user?.updateDisplayName(newName);
                // تحديث الاسم في Firestore
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user!.uid)
                    .update({'name': newName});
                if (mounted) Navigator.pop(c);
              }
            },
            child: const Text("حفظ"),
          ),
        ],
      ),
    );
  }

  // دالة لاستخراج أول حرف من الاسم
  String _getInitials(String name) {
    if (name.isEmpty) return "P";
    return name.trim().substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F8),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user?.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            var data = snapshot.data?.data() as Map<String, dynamic>?;
            String displayName = data?['name'] ?? "بطل Pro الجديد";
            String phoneNumber =
                data?['phone'] ?? user?.phoneNumber ?? "لا يوجد رقم";

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const SizedBox(height: 50),
                Center(
                  child: Column(
                    children: [
                      // عرض أول حرف من الاسم بدلاً من الصورة
                      CircleAvatar(
                        radius: 65,
                        backgroundColor: deepTeal,
                        child: Text(
                          _getInitials(displayName),
                          style: GoogleFonts.cairo(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        displayName,
                        style: GoogleFonts.cairo(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: deepTeal,
                        ),
                      ),
                      Text(
                        phoneNumber,
                        style: GoogleFonts.poppins(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                _buildProfileBtn(
                  "تعديل الاسم",
                  Icons.edit_note_rounded,
                  () => _showEditDialog(displayName),
                ),
                _buildProfileBtn(
                  "دعوة صديق",
                  Icons.person_add_alt_1_rounded,
                  () => Share.share("انضم لأبطال Pro!"),
                ),
                _buildProfileBtn("حول التطبيق", Icons.info_outline_rounded, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (c) => const AboutScreen()),
                  );
                }),
                const Divider(height: 50),
                _buildProfileBtn(
                  "تسجيل الخروج",
                  Icons.logout_rounded,
                  _handleLogout,
                  isExit: true,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileBtn(
    String title,
    IconData icon,
    VoidCallback onTap, {
    bool isExit = false,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Icon(icon, color: isExit ? Colors.redAccent : deepTeal),
        title: Text(
          title,
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.w600,
            color: isExit ? Colors.redAccent : Colors.black87,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: onTap,
      ),
    );
  }
}

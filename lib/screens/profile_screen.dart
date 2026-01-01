import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'about_screen.dart'; // استيراد شاشة حول لتعمل الأزرار

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final Color deepTeal = const Color(0xFF1B4D57);

  // 1. دالة دعوة صديق
  void _inviteFriend() {
    Share.share(
      'يا بطل! انضم إلينا في تطبيق أبطال Pro العقاري، وتعلم كل أسرار السوق. حمل التطبيق من هنا: [رابط التطبيق]',
      subject: 'دعوة للانضمام إلى أبطال Pro',
    );
  }

  // 2. دالة تغيير الصورة الشخصية
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("تم اختيار الصورة بنجاح (بانتظار الرفع لـ Storage)")),
      );
    }
  }

  // 3. دالة تعديل الاسم والبيانات
  void _showEditDialog() {
    TextEditingController nameEdit =
        TextEditingController(text: user?.displayName ?? "بطل Pro");
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text("تعديل بيانات بطل Pro", style: GoogleFonts.cairo()),
        content: TextField(
          controller: nameEdit,
          decoration: const InputDecoration(labelText: "الاسم الجديد"),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c), child: const Text("إلغاء")),
          ElevatedButton(
            onPressed: () async {
              // تحديث الاسم في Firebase Auth
              await user?.updateDisplayName(nameEdit.text);
              // تحديث الاسم في Firestore
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user!.uid)
                  .set({
                'name': nameEdit.text,
              }, SetOptions(merge: true));

              Navigator.pop(c);
              setState(() {});

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("تم تحديث البيانات بنجاح")),
              );
            },
            child: const Text("حفظ"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F8),
      appBar: AppBar(
        title: Text("بروفايل أبطال Pro",
            style: GoogleFonts.cairo(
                color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: deepTeal,
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // قسم الصورة والاسم
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 55,
                          backgroundColor: deepTeal,
                          child: const CircleAvatar(
                            radius: 52,
                            backgroundImage: AssetImage(
                                'assets/user_placeholder.png'), // تأكدي من وجود الصورة في Assets
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            backgroundColor: Colors.orange,
                            radius: 18,
                            child: const Icon(Icons.camera_alt,
                                size: 18, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(user?.displayName ?? "بطل Pro الجديد",
                      style: GoogleFonts.cairo(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  Text(user?.email ?? "",
                      style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // الأزرار الوظيفية
            _buildProfileBtn("تعديل بياناتي", Icons.edit, _showEditDialog),

            _buildProfileBtn(
                "دعوة صديق للانضمام", Icons.person_add, _inviteFriend),

            _buildProfileBtn("حول أبطال Pro", Icons.info_outline, () {
              // تفعيل التنقل لشاشة حول
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutScreen()),
              );
            }),

            const Divider(height: 40),

            _buildProfileBtn("تسجيل الخروج", Icons.logout, () async {
              await FirebaseAuth.instance.signOut();
              // العودة لشاشة تسجيل الدخول
              Navigator.of(context).popUntil((route) => route.isFirst);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileBtn(String title, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: deepTeal),
        title:
            Text(title, style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
        trailing:
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}

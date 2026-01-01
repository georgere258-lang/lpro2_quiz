import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'about_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final Color deepTeal = const Color(0xFF1B4D57);

  // 1. دالة تسجيل الخروج الاحترافية
  Future<void> _handleLogout() async {
    try {
      bool? confirm = await showDialog(
        context: context,
        builder: (c) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("تسجيل الخروج",
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          content: Text("هل أنت متأكد أنك تريد مغادرة تطبيق أبطال Pro؟",
              style: GoogleFonts.cairo()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child:
                  Text("إلغاء", style: GoogleFonts.cairo(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(c, true),
              child:
                  Text("خروج", style: GoogleFonts.cairo(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/login', (route) => false);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("خطأ أثناء الخروج: $e")));
    }
  }

  // 2. دالة دعوة صديق
  void _inviteFriend() {
    Share.share(
      'يا بطل! انضم إلينا في تطبيق أبطال Pro العقاري، وتعلم كل أسرار السوق. حمل التطبيق من هنا: [رابط التطبيق]',
      subject: 'دعوة للانضمام إلى أبطال Pro',
    );
  }

  // 3. دالة تغيير الصورة الشخصية
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

  // 4. دالة تعديل الاسم
  void _showEditDialog(String currentName) {
    TextEditingController nameEdit = TextEditingController(text: currentName);
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
              String newName = nameEdit.text.trim();
              if (newName.isNotEmpty) {
                await user?.updateDisplayName(newName);
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user!.uid)
                    .set({
                  'name': newName,
                  'lastUpdate': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));

                if (mounted) {
                  Navigator.pop(c);
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("تم تحديث البيانات بنجاح")));
                }
              }
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
        // حل مشكلة الشاشة السوداء: التوجيه للرئيسية مباشرة عند الرجوع
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            // استبدال الشاشة الحالية بالرئيسية لمنع ظهور شاشة سوداء
            Navigator.of(context).pushReplacementNamed('/home');
          },
        ),
        title: Text("بروفايل أبطال Pro",
            style: GoogleFonts.cairo(
                color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: deepTeal,
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user?.uid)
              .snapshots(),
          builder: (context, snapshot) {
            String displayName = user?.displayName ?? "بطل Pro الجديد";
            String photoUrl = "";

            if (snapshot.hasData && snapshot.data!.exists) {
              var data = snapshot.data!.data() as Map<String, dynamic>;
              displayName = data['name'] ?? displayName;
              photoUrl = data['photoUrl'] ?? "";
            }

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
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
                              child: CircleAvatar(
                                radius: 52,
                                backgroundColor: Colors.grey[200],
                                backgroundImage: photoUrl.isEmpty
                                    ? const AssetImage(
                                            'assets/user_placeholder.png')
                                        as ImageProvider
                                    : NetworkImage(photoUrl),
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
                      Text(displayName,
                          style: GoogleFonts.cairo(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(user?.email ?? "",
                          style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                _buildProfileBtn("تعديل بياناتي", Icons.edit,
                    () => _showEditDialog(displayName)),
                _buildProfileBtn(
                    "دعوة صديق للانضمام", Icons.person_add, _inviteFriend),
                _buildProfileBtn("حول أبطال Pro", Icons.info_outline, () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AboutScreen()));
                }),
                const Divider(height: 40),
                _buildProfileBtn("تسجيل الخروج", Icons.logout, _handleLogout,
                    isExit: true),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileBtn(String title, IconData icon, VoidCallback onTap,
      {bool isExit = false}) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: isExit ? Colors.redAccent : deepTeal),
        title: Text(title,
            style: GoogleFonts.cairo(
                fontWeight: FontWeight.w600,
                color: isExit ? Colors.redAccent : Colors.black)),
        trailing:
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}

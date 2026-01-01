import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'chat_support_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final TextEditingController _nameController = TextEditingController();
  final Color deepTeal = const Color(0xFF1B4D57);

  // دالة جلب الترتيب
  Stream<int> getUserRank() {
    return FirebaseFirestore.instance
        .collection('users')
        .orderBy('points', descending: true)
        .snapshots()
        .map((snap) {
      int index = snap.docs.indexWhere((doc) => doc.id == user?.uid);
      return index != -1 ? index + 1 : 0;
    });
  }

  // دالة تعديل الاسم
  Future<void> _updateName(String currentName) async {
    _nameController.text = currentName;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("تعديل الاسم",
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold, color: deepTeal)),
        content: TextField(
          controller: _nameController,
          textAlign: TextAlign.center,
          decoration: const InputDecoration(
              hintText: "الاسم الجديد", border: OutlineInputBorder()),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  Text("إلغاء", style: GoogleFonts.cairo(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: deepTeal),
            onPressed: () async {
              if (_nameController.text.trim().isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user?.uid)
                    .update({'name': _nameController.text.trim()});
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text("حفظ", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // دالة اختيار الصورة
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("جاري رفع الصورة...")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          var data = snapshot.data!.data() as Map<String, dynamic>?;
          String name =
              data?['name'] ?? "Pro-${user?.uid.substring(0, 4).toUpperCase()}";

          return Directionality(
            textDirection: TextDirection.rtl,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // الهيدر مع الكاميرا
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(top: 60, bottom: 40),
                    decoration: BoxDecoration(
                        color: deepTeal,
                        borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(40),
                            bottomRight: Radius.circular(40))),
                    child: Column(children: [
                      Stack(alignment: Alignment.bottomRight, children: [
                        const CircleAvatar(
                            radius: 55,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.person,
                                size: 60, color: Color(0xFF1B4D57))),
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                  color: Colors.orange, shape: BoxShape.circle),
                              child: const Icon(Icons.camera_alt,
                                  color: Colors.white, size: 20)),
                        )
                      ]),
                      const SizedBox(height: 15),
                      Text(name,
                          style: GoogleFonts.cairo(
                              fontSize: 22,
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ]),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // الإحصائيات (النجوم، المحترفين، الترتيب)
                        StreamBuilder<int>(
                          stream: getUserRank(),
                          builder: (context, rSnap) => Row(children: [
                            _buildStatItem(
                                "دوري النجوم",
                                "${data?['points_stars'] ?? 0}",
                                Icons.stars,
                                Colors.blue),
                            const SizedBox(width: 10),
                            _buildStatItem(
                                "المحترفين",
                                "${data?['points_pro'] ?? 0}",
                                Icons.workspace_premium,
                                Colors.orange),
                            const SizedBox(width: 10),
                            _buildStatItem("ترتيبك", "#${rSnap.data ?? '..'}",
                                Icons.leaderboard, Colors.teal),
                          ]),
                        ),
                        const SizedBox(height: 30),

                        // الأزرار التفاعلية
                        _buildBtn("تعديل الاسم والبيانات", Icons.edit_rounded,
                            () => _updateName(name)),

                        _buildBtn(
                            "دعوة زميل للمنافسة", Icons.person_add_rounded, () {
                          Share.share(
                              "يا بطل! حمل تطبيق برو العقاري ونافسني في المعلومات. رابط التطبيق: [Link]");
                        }),

                        _buildBtn(
                            "مركز المساعدة والتواصل",
                            Icons.support_agent_rounded,
                            () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (c) =>
                                        const ChatSupportScreen()))),

                        const SizedBox(height: 30),

                        TextButton.icon(
                            onPressed: () => FirebaseAuth.instance.signOut(),
                            icon: const Icon(Icons.logout, color: Colors.red),
                            label: Text("تسجيل الخروج",
                                style: GoogleFonts.cairo(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold))),
                      ],
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String t, String v, IconData i, Color c) {
    return Expanded(
        child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04), blurRadius: 10)
                ]),
            child: Column(children: [
              Icon(i, color: c, size: 26),
              const SizedBox(height: 5),
              Text(v,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              Text(t,
                  style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey))
            ])));
  }

  Widget _buildBtn(String t, IconData i, VoidCallback o) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Icon(i, color: deepTeal),
        title: Text(t,
            style:
                GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold)),
        trailing:
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        onTap: o,
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

// استيراد الثوابت المركزية
import '../../core/constants/app_colors.dart';
import 'admin_messages_list.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7F8),
        appBar: AppBar(
          title: Text("لوحة تحكم L Pro",
              style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: AppColors.primaryDeepTeal,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.center, // --- حل مشكلة توسط العناوين ---
            indicatorColor: AppColors.secondaryOrange,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withOpacity(0.6),
            labelStyle:
                GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(text: "الأعضاء", icon: Icon(Icons.people_alt)),
              Tab(text: "الأخبار", icon: Icon(Icons.campaign)),
              Tab(text: "الأسئلة", icon: Icon(Icons.quiz)),
              Tab(text: "المواضيع", icon: Icon(Icons.article)),
              Tab(text: "الدعم", icon: Icon(Icons.chat_bubble)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            UserManager(),
            NewsManager(),
            QuizManager(),
            TopicManager(),
            AdminMessagesList(),
          ],
        ),
      ),
    );
  }
}

// --- 1. إدارة الأعضاء ---
class UserManager extends StatefulWidget {
  const UserManager({super.key});
  @override
  State<UserManager> createState() => _UserManagerState();
}

class _UserManagerState extends State<UserManager> {
  String query = "";
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchField(
            "بحث بالاسم أو الرقم...", (v) => setState(() => query = v)),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError)
                return const Center(child: Text("حدث خطأ ما"));
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());

              var docs = snapshot.data!.docs.where((d) {
                var data = d.data() as Map<String, dynamic>;
                String name = (data['name'] ?? "").toString().toLowerCase();
                String phone = (data['phone'] ?? "").toString();
                return name.contains(query.toLowerCase()) ||
                    phone.contains(query);
              }).toList();

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  var user = docs[i];
                  var userData = user.data() as Map<String, dynamic>;
                  bool isBlocked = userData['isBlocked'] ?? false;

                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                    child: ListTile(
                      title: Text(userData['name'] ?? "بدون اسم",
                          style:
                              GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                      subtitle: Text(userData['phone'] ?? "بدون رقم هاتفي"),
                      trailing: IconButton(
                        icon: Icon(Icons.block,
                            color: isBlocked ? Colors.red : Colors.grey),
                        onPressed: () =>
                            user.reference.update({'isBlocked': !isBlocked}),
                      ),
                      onTap: () => _showUserDetails(user),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showUserDetails(DocumentSnapshot user) {
    var data = user.data() as Map<String, dynamic>;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (c) => Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("تفاصيل العضو",
                style: GoogleFonts.cairo(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            _infoRow("الاسم:", data['name'] ?? "غير متوفر"),
            _infoRow("الهاتف:", data['phone'] ?? "غير متوفر"),
            _infoRow("إجمالي النقاط:", "${data['points'] ?? 0}"),
            _infoRow("نقاط النجوم:", "${data['starsPoints'] ?? 0}"),
            _infoRow("نقاط المحترفين:", "${data['proPoints'] ?? 0}"),
          ],
        ),
      ),
    );
  }
}

// --- 2. إدارة الأخبار ---
class NewsManager extends StatelessWidget {
  const NewsManager({super.key});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildActionBtn(context, "إضافة خبر جديد", Icons.add_comment,
            () => _showAddNews(context)),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('news')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              return ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, i) {
                  var newsData =
                      snapshot.data!.docs[i].data() as Map<String, dynamic>;
                  return _buildListTile(
                      newsData['content'] ?? "",
                      "شريط الأخبار",
                      () => snapshot.data!.docs[i].reference.delete());
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAddNews(BuildContext context) {
    TextEditingController c = TextEditingController();
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: Text("إضافة خبر", style: GoogleFonts.cairo()),
              content: TextField(
                  controller: c,
                  decoration: const InputDecoration(hintText: "نص الخبر")),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("إلغاء")),
                ElevatedButton(
                    onPressed: () {
                      if (c.text.isNotEmpty) {
                        FirebaseFirestore.instance.collection('news').add({
                          'content': c.text,
                          'createdAt': FieldValue.serverTimestamp()
                        });
                        Navigator.pop(ctx);
                      }
                    },
                    child: const Text("إضافة"))
              ],
            ));
  }
}

// --- 3. إدارة الأسئلة ---
class QuizManager extends StatefulWidget {
  const QuizManager({super.key});
  @override
  State<QuizManager> createState() => _QuizManagerState();
}

class _QuizManagerState extends State<QuizManager> {
  String query = "";
  File? _quizImage;

  Future<void> _pickQuizImage(StateSetter setModalState) async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) setModalState(() => _quizImage = File(picked.path));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: _buildActionBtn(
                    context, "سؤال واحد", Icons.add, () => _showQuizForm())),
            Expanded(
                child: _buildActionBtn(context, "رفع مجمع", Icons.library_add,
                    () => _showBulkUpload(context))),
          ],
        ),
        _buildSearchField(
            "بحث في الأسئلة...", (v) => setState(() => query = v)),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance.collection('quizzes').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              var filtered = snapshot.data!.docs.where((d) {
                var data = d.data() as Map<String, dynamic>;
                return (data['question'] ?? "").toString().contains(query);
              }).toList();

              return ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, i) {
                  var data = filtered[i].data() as Map<String, dynamic>;
                  return _buildListTile(
                      data['question'] ?? "",
                      data['category'] ?? "",
                      () => filtered[i].reference.delete());
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showQuizForm() {
    final qC = TextEditingController();
    final optC = List.generate(4, (i) => TextEditingController());
    int correct = 0;
    String cat = "دوري النجوم";
    bool uploading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (c) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("إضافة سؤال",
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                GestureDetector(
                  onTap: () => _pickQuizImage(setModalState),
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10)),
                    child: _quizImage != null
                        ? Image.file(_quizImage!, fit: BoxFit.cover)
                        : const Icon(Icons.add_a_photo, size: 40),
                  ),
                ),
                DropdownButton<String>(
                  value: cat,
                  isExpanded: true,
                  items: ["دوري النجوم", "دوري المحترفين"]
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setModalState(() => cat = v!),
                ),
                TextField(
                    controller: qC,
                    decoration: const InputDecoration(labelText: "السؤال")),
                ...List.generate(
                    4,
                    (i) => Row(children: [
                          Radio(
                              value: i,
                              groupValue: correct,
                              onChanged: (v) =>
                                  setModalState(() => correct = v as int)),
                          Expanded(
                              child: TextField(
                                  controller: optC[i],
                                  decoration: InputDecoration(
                                      labelText: "خيار ${i + 1}"))),
                        ])),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: uploading
                      ? null
                      : () async {
                          if (qC.text.isEmpty) return;
                          setModalState(() => uploading = true);
                          String url = "";
                          if (_quizImage != null) {
                            var ref = FirebaseStorage.instance.ref().child(
                                'quizzes/${DateTime.now().millisecondsSinceEpoch}.jpg');
                            await ref.putFile(_quizImage!);
                            url = await ref.getDownloadURL();
                          }
                          await FirebaseFirestore.instance
                              .collection('quizzes')
                              .add({
                            'question': qC.text,
                            'options': optC.map((e) => e.text).toList(),
                            'correctAnswer': correct,
                            'category': cat,
                            'imageUrl': url
                          });
                          Navigator.pop(context);
                          setState(() => _quizImage = null);
                        },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDeepTeal),
                  child: uploading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white))
                      : const Text("حفظ",
                          style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showBulkUpload(BuildContext context) {
    TextEditingController bulk = TextEditingController();
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: Text("رفع مجمع", style: GoogleFonts.cairo()),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                      "التنسيق: سؤال#خيار1,خيار2,خيار3,خيار4#رقم_الاجابة"),
                  const SizedBox(height: 10),
                  TextField(
                      controller: bulk,
                      maxLines: 5,
                      decoration:
                          const InputDecoration(border: OutlineInputBorder())),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("إلغاء")),
                ElevatedButton(
                    onPressed: () async {
                      for (var line in bulk.text.split('\n')) {
                        if (line.contains('#')) {
                          var p = line.split('#');
                          if (p.length >= 3) {
                            FirebaseFirestore.instance
                                .collection('quizzes')
                                .add({
                              'question': p[0],
                              'options': p[1].split(','),
                              'correctAnswer': int.parse(p[2].trim()),
                              'category': "دوري النجوم",
                              'imageUrl': ""
                            });
                          }
                        }
                      }
                      Navigator.pop(ctx);
                    },
                    child: const Text("رفع الكل"))
              ],
            ));
  }
}

// --- 4. إدارة المواضيع ---
class TopicManager extends StatefulWidget {
  const TopicManager({super.key});
  @override
  State<TopicManager> createState() => _TopicManagerState();
}

class _TopicManagerState extends State<TopicManager> {
  String query = "";
  File? _topicImage;

  Future<void> _pickTopicImage(StateSetter setModalState) async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) setModalState(() => _topicImage = File(picked.path));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildActionBtn(
            context, "إضافة موضوع جديد", Icons.article, () => _showTopicForm()),
        _buildSearchField(
            "بحث في المواضيع...", (v) => setState(() => query = v)),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('topics').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              var docs = snapshot.data!.docs.where((d) {
                var data = d.data() as Map<String, dynamic>;
                return (data['title'] ?? "").toString().contains(query);
              }).toList();

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  var data = docs[i].data() as Map<String, dynamic>;
                  return _buildListTile(data['title'] ?? "",
                      data['category'] ?? "", () => docs[i].reference.delete());
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showTopicForm() {
    final tC = TextEditingController();
    final cC = TextEditingController();
    String cat = "المعلومة بتفرق";
    bool uploading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (c) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("إضافة موضوع",
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                GestureDetector(
                  onTap: () => _pickTopicImage(setModalState),
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10)),
                    child: _topicImage != null
                        ? Image.file(_topicImage!, fit: BoxFit.cover)
                        : const Icon(Icons.add_a_photo, size: 50),
                  ),
                ),
                DropdownButton<String>(
                  value: cat,
                  isExpanded: true,
                  // --- تم التعديل ليتوافق مع أسماء الأقسام الجديدة ---
                  items: ["المعلومة بتفرق", "إعرف عميلك"]
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setModalState(() => cat = v!),
                ),
                TextField(
                    controller: tC,
                    decoration: const InputDecoration(labelText: "العنوان")),
                TextField(
                    controller: cC,
                    maxLines: 5,
                    decoration: const InputDecoration(labelText: "المحتوى")),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: uploading
                      ? null
                      : () async {
                          if (tC.text.isEmpty) return;
                          setModalState(() => uploading = true);
                          String url = "";
                          if (_topicImage != null) {
                            var ref = FirebaseStorage.instance.ref().child(
                                'topics/${DateTime.now().millisecondsSinceEpoch}.jpg');
                            await ref.putFile(_topicImage!);
                            url = await ref.getDownloadURL();
                          }
                          await FirebaseFirestore.instance
                              .collection('topics')
                              .add({
                            'title': tC.text,
                            'content': cC.text,
                            'category': cat,
                            'imageUrl': url
                          });
                          Navigator.pop(context);
                          setState(() => _topicImage = null);
                        },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDeepTeal),
                  child: uploading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white))
                      : const Text("حفظ الموضوع",
                          style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- Helpers ---
Widget _buildSearchField(String hint, Function(String) onChange) {
  return Padding(
    padding: const EdgeInsets.all(12),
    child: TextField(
        onChanged: onChange,
        decoration: InputDecoration(
            hintText: hint,
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 0, horizontal: 15),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none))),
  );
}

Widget _buildActionBtn(
    BuildContext context, String title, IconData icon, VoidCallback onTap) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    child: ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white, size: 18),
      label: Text(title,
          style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12)),
      style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDeepTeal,
          minimumSize: const Size(double.infinity, 45),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
    ),
  );
}

Widget _buildListTile(String title, String sub, VoidCallback onDel) {
  return Card(
    elevation: 0,
    margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    child: ListTile(
      title: Text(title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(sub, style: const TextStyle(fontSize: 12)),
      trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
          onPressed: onDel),
    ),
  );
}

Widget _infoRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Text(label,
            style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold, color: AppColors.primaryDeepTeal)),
        const SizedBox(width: 10),
        Text(value, style: GoogleFonts.cairo()),
      ],
    ),
  );
}

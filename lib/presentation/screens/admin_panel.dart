import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:flutter/services.dart' show rootBundle;

// استيراد الثوابت والصفحات
import 'package:lpro2_quiz/core/constants/app_colors.dart';
import 'package:lpro2_quiz/presentation/screens/admin_messages_list.dart';

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
            tabAlignment: TabAlignment.center,
            indicatorColor: AppColors.secondaryOrange,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withAlpha(150),
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

// --- دالة إرسال الإشعارات (تعمل مجاناً) ---
Future<void> _sendNotification(String title, String body) async {
  auth.AutoRefreshingAuthClient? client;
  try {
    final jsonString =
        await rootBundle.loadString('assets/service_account.json');
    final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
    final String projectName = jsonMap['project_id'];
    final accountCredentials = auth.ServiceAccountCredentials.fromJson(jsonMap);
    final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

    client = await auth.clientViaServiceAccount(accountCredentials, scopes);
    final String url =
        'https://fcm.googleapis.com/v1/projects/$projectName/messages:send';

    await client.post(
      Uri.parse(url),
      body: jsonEncode({
        'message': {
          'topic': 'all_users',
          'notification': {'title': title, 'body': body},
          'android': {
            'notification': {
              'channel_id': 'lpro_notifications',
              'sound': 'default',
            },
          },
        }
      }),
    );
  } catch (e) {
    debugPrint("FCM Error: $e");
  } finally {
    client?.close();
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
            stream: FirebaseFirestore.instance
                .collection('users')
                .limit(100)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
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
                  var userData = docs[i].data() as Map<String, dynamic>;
                  bool isBlocked = userData['isBlocked'] ?? false;
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                    child: ListTile(
                      title: Text(userData['name'] ?? "بدون اسم",
                          style:
                              GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                      subtitle: Text(userData['phone'] ?? "بدون رقم"),
                      trailing: IconButton(
                        icon: Icon(Icons.block,
                            color: isBlocked ? Colors.red : Colors.grey),
                        onPressed: () =>
                            docs[i].reference.update({'isBlocked': !isBlocked}),
                      ),
                      onTap: () => _showUserDetails(docs[i]),
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
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
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
              onPressed: () => Navigator.pop(ctx), child: const Text("إلغاء")),
          ElevatedButton(
            onPressed: () async {
              if (c.text.isNotEmpty) {
                await FirebaseFirestore.instance.collection('news').add({
                  'content': c.text,
                  'createdAt': FieldValue.serverTimestamp()
                });
                _sendNotification("خبر عاجل ⚡", c.text);
                if (context.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text("إرسال"),
          )
        ],
      ),
    );
  }
}

// --- 3. إدارة الأسئلة (تم التعديل لتخطي الـ Storage) ---
class QuizManager extends StatefulWidget {
  const QuizManager({super.key});
  @override
  State<QuizManager> createState() => _QuizManagerState();
}

class _QuizManagerState extends State<QuizManager> {
  String query = "";

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
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
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
    final imgC = TextEditingController(); // حقل رابط الصورة
    final optC = List.generate(4, (i) => TextEditingController());
    int correct = 0;
    String cat = "دوري النجوم";

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
                Text("إضافة سؤال (عن طريق الرابط)",
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                TextField(
                  controller: imgC,
                  decoration: const InputDecoration(
                    labelText: "رابط الصورة (اختياري)",
                    hintText: "انسخ رابط الصورة من ImgBB أو جوجل",
                    prefixIcon: Icon(Icons.link),
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
                          Radio<int>(
                              value: i,
                              groupValue: correct,
                              onChanged: (v) =>
                                  setModalState(() => correct = v!)),
                          Expanded(
                              child: TextField(
                                  controller: optC[i],
                                  decoration: InputDecoration(
                                      labelText: "خيار ${i + 1}"))),
                        ])),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (qC.text.isEmpty) return;
                    await FirebaseFirestore.instance.collection('quizzes').add({
                      'question': qC.text,
                      'options': optC.map((e) => e.text).toList(),
                      'correctAnswer': correct,
                      'category': cat,
                      'imageUrl': imgC.text // حفظ الرابط مباشرة
                    });
                    _sendNotification(
                        "تحدي جديد 🏆", "تم إضافة سؤال جديد في $cat");
                    if (context.mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDeepTeal),
                  child: const Text("حفظ ونشر",
                      style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(height: 20),
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
        content: TextField(
          controller: bulk,
          maxLines: 5,
          decoration: const InputDecoration(
              hintText: "سؤال#خيار1,خيار2,خيار3,خيار4#رقم_الاجابة#رابط_الصورة",
              border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("إلغاء")),
          ElevatedButton(
            onPressed: () async {
              final batch = FirebaseFirestore.instance.batch();
              final lines = bulk.text.split('\n');
              for (var line in lines) {
                if (line.contains('#')) {
                  var p = line.split('#');
                  if (p.length >= 3) {
                    var ref =
                        FirebaseFirestore.instance.collection('quizzes').doc();
                    batch.set(ref, {
                      'question': p[0],
                      'options': p[1].split(','),
                      'correctAnswer': int.parse(p[2].trim()),
                      'category': "دوري النجوم",
                      'imageUrl': p.length > 3 ? p[3].trim() : ""
                    });
                  }
                }
              }
              await batch.commit();
              _sendNotification(
                  "تحديث الدوري 🚀", "تم إضافة مجموعة أسئلة جديدة");
              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text("رفع الكل"),
          )
        ],
      ),
    );
  }
}

// --- 4. إدارة المواضيع (تخطي الـ Storage) ---
class TopicManager extends StatefulWidget {
  const TopicManager({super.key});
  @override
  State<TopicManager> createState() => _TopicManagerState();
}

class _TopicManagerState extends State<TopicManager> {
  String query = "";
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildActionBtn(context, "إضافة موضوع برابط صورة", Icons.article,
            () => _showTopicForm()),
        _buildSearchField(
            "بحث في المواضيع...", (v) => setState(() => query = v)),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('topics').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
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
    final imgC = TextEditingController();
    String cat = "المعلومة بتفرق";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (c) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("إضافة موضوع تعليمي",
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
              TextField(
                  controller: imgC,
                  decoration:
                      const InputDecoration(labelText: "رابط صورة الموضوع")),
              TextField(
                  controller: tC,
                  decoration: const InputDecoration(labelText: "العنوان")),
              TextField(
                  controller: cC,
                  maxLines: 5,
                  decoration: const InputDecoration(labelText: "المحتوى")),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (tC.text.isEmpty) return;
                  await FirebaseFirestore.instance.collection('topics').add({
                    'title': tC.text,
                    'content': cC.text,
                    'category': cat,
                    'imageUrl': imgC.text
                  });
                  _sendNotification("موضوع يهمك 📚", tC.text);
                  if (context.mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDeepTeal),
                child: const Text("حفظ", style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 20),
            ],
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
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none),
      ),
    ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
  );
}

Widget _buildListTile(String title, String sub, VoidCallback onDel) {
  return Card(
    margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
    child: ListTile(
      title: Text(title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(sub),
      trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
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

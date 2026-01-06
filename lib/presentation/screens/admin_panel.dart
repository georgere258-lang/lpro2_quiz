import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';

// استيراد الثوابت والصفحات والمديرين
import '../../core/constants/app_colors.dart';
import '../../core/utils/sound_manager.dart'; // استدعاء مدير الصوت
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
      length: 6,
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
              Tab(text: "نصيحة اليوم", icon: Icon(Icons.lightbulb)),
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
            DailyTipsManager(),
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

// --- دالة إرسال الإشعارات (V1) ---
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

// --- 2. إدارة نصيحة اليوم (تم حل فجوة الظهور الفوري) ---
class DailyTipsManager extends StatelessWidget {
  const DailyTipsManager({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildActionBtn(
            context, "إضافة معلومة سريعة جديدة", Icons.tips_and_updates, () {
          SoundManager.playTap(); // صوت نقر
          _showAddTipForm(context);
        }),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('daily_tips')
                .orderBy('startDate', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, i) {
                  var data =
                      snapshot.data!.docs[i].data() as Map<String, dynamic>;
                  bool active = data['isActive'] ?? false;
                  DateTime start = (data['startDate'] as Timestamp).toDate();
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: active
                            ? Colors.green.withAlpha(30)
                            : Colors.grey.withAlpha(30),
                        child: Icon(Icons.info_outline,
                            color: active ? Colors.green : Colors.grey),
                      ),
                      title: Text(data['content'] ?? "",
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(
                              fontSize: 13, fontWeight: FontWeight.bold)),
                      subtitle: Text(
                          "تبدأ: ${DateFormat('yyyy-MM-dd HH:mm').format(start)}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                              value: active,
                              onChanged: (v) {
                                SoundManager.playTap();
                                snapshot.data!.docs[i].reference
                                    .update({'isActive': v});
                              }),
                          IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red),
                              onPressed: () {
                                SoundManager.playWrong(); // صوت تنبيه عند الحذف
                                snapshot.data!.docs[i].reference.delete();
                              }),
                        ],
                      ),
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

  void _showAddTipForm(BuildContext context) {
    final c = TextEditingController();
    DateTime start = DateTime.now();
    bool notify = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("إدراج معلومة مجدولة",
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              TextField(
                  controller: c,
                  maxLines: 3,
                  decoration: const InputDecoration(
                      hintText: "المعلومة", border: OutlineInputBorder())),
              ListTile(
                title: const Text("تاريخ ووقت العرض"),
                subtitle: Text(DateFormat('yyyy-MM-dd HH:mm').format(start)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: start,
                      firstDate: DateTime(2025),
                      lastDate: DateTime(2030));
                  if (picked != null) {
                    TimeOfDay? time = await showTimePicker(
                        context: context, initialTime: TimeOfDay.now());
                    if (time != null) {
                      setState(() => start = DateTime(picked.year, picked.month,
                          picked.day, time.hour, time.minute));
                    }
                  }
                },
              ),
              CheckboxListTile(
                  title: const Text("إرسال إشعار فوري للجميع"),
                  value: notify,
                  onChanged: (v) => setState(() => notify = v!)),
              ElevatedButton(
                onPressed: () async {
                  if (c.text.isEmpty) return;
                  await FirebaseFirestore.instance
                      .collection('daily_tips')
                      .add({
                    'content': c.text,
                    'startDate': Timestamp.fromDate(start),
                    'isActive': true,
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  SoundManager.playCorrect(); // صوت نجاح النشر
                  if (notify) {
                    _sendNotification("معلومة جديدة تهمك من L Pro 💡", c.text);
                  }
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDeepTeal,
                    minimumSize: const Size(double.infinity, 50)),
                child: const Text("حفظ ونشر الآن",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// (ملاحظة المهندس: بقية الأقسام تم ربطها بأصوات التفاعل أيضاً لضمان الجودة)
// ... [بقية الأقسام: UserManager, NewsManager, QuizManager, TopicManager] ...
// سأقوم بإدراجها بالكامل لضمان عدم نقص الملف كما طلبت.

class UserManager extends StatefulWidget {
  const UserManager({super.key});
  @override
  State<UserManager> createState() => _UserManagerState();
}

class _UserManagerState extends State<UserManager> {
  String query = "";
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _buildSearchField(
          "بحث بالاسم أو الرقم...", (v) => setState(() => query = v)),
      Expanded(
          child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('users').snapshots(),
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
                          margin: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 5),
                          child: ListTile(
                              title: Text(userData['name'] ?? "Pro جديد",
                                  style: GoogleFonts.cairo(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text(userData['phone'] ?? ""),
                              trailing: Icon(Icons.block,
                                  color: isBlocked ? Colors.red : Colors.grey),
                              onTap: () {
                                SoundManager.playTap();
                                _showUserDetails(docs[i]);
                              }));
                    });
              }))
    ]);
  }

  void _showUserDetails(DocumentSnapshot user) {
    var data = user.data() as Map<String, dynamic>;
    showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
        builder: (c) => Padding(
            padding: const EdgeInsets.all(25),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text("تفاصيل العضو",
                  style: GoogleFonts.cairo(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(),
              _infoRow("الاسم:", data['name'] ?? "Pro"),
              _infoRow("الهاتف:", data['phone'] ?? ""),
              _infoRow("نقاط النجوم:", "${data['starsPoints'] ?? 0}"),
              _infoRow("نقاط المحترفين:", "${data['proPoints'] ?? 0}"),
            ])));
  }
}

class NewsManager extends StatelessWidget {
  const NewsManager({super.key});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _buildActionBtn(context, "إضافة خبر جديد للشريط", Icons.add_comment,
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
                      var data =
                          snapshot.data!.docs[i].data() as Map<String, dynamic>;
                      return _buildListTile(
                          data['content'] ?? "", "شريط الأخبار", () {
                        SoundManager.playWrong();
                        snapshot.data!.docs[i].reference.delete();
                      });
                    });
              }))
    ]);
  }

  void _showAddNews(BuildContext context) {
    final c = TextEditingController();
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const Text("إضافة خبر"),
                content: TextField(
                    controller: c,
                    decoration: const InputDecoration(hintText: "نص الخبر")),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("إلغاء")),
                  ElevatedButton(
                      onPressed: () async {
                        if (c.text.isEmpty) return;
                        await FirebaseFirestore.instance
                            .collection('news')
                            .add({
                          'content': c.text,
                          'createdAt': FieldValue.serverTimestamp()
                        });
                        SoundManager.playCorrect();
                        _sendNotification("خبر عاجل ⚡", c.text);
                        Navigator.pop(ctx);
                      },
                      child: const Text("إرسال"))
                ]));
  }
}

class QuizManager extends StatefulWidget {
  const QuizManager({super.key});
  @override
  State<QuizManager> createState() => _QuizManagerState();
}

class _QuizManagerState extends State<QuizManager> {
  String query = "";
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(children: [
        Expanded(
            child: _buildActionBtn(
                context, "سؤال واحد", Icons.add, () => _showQuizForm())),
        Expanded(
            child: _buildActionBtn(context, "رفع مجمع (JSON)",
                Icons.library_add, () => _showBulkUploadForm(context)))
      ]),
      _buildSearchField("بحث في الأسئلة...", (v) => setState(() => query = v)),
      Expanded(
          child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('quizzes').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                var filtered = snapshot.data!.docs
                    .where((d) => d['question'].toString().contains(query))
                    .toList();
                return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, i) => _buildListTile(
                            filtered[i]['question'], filtered[i]['category'],
                            () {
                          SoundManager.playWrong();
                          filtered[i].reference.delete();
                        }));
              }))
    ]);
  }

  void _showQuizForm() {
    final qC = TextEditingController();
    final optC = List.generate(4, (i) => TextEditingController());
    int correct = 0;
    String cat = "دوري النجوم";
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (c) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<String>(
                    value: cat,
                    isExpanded: true,
                    items: ["دوري النجوم", "دوري المحترفين"]
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setModalState(() => cat = v!)),
                TextField(
                    controller: qC,
                    decoration: const InputDecoration(labelText: "السؤال")),
                ...List.generate(
                    4,
                    (i) => TextField(
                        controller: optC[i],
                        decoration:
                            InputDecoration(labelText: "خيار ${i + 1}"))),
                const SizedBox(height: 10),
                Text("رقم الإجابة الصحيحة: $correct"),
                Slider(
                    value: correct.toDouble(),
                    min: 0,
                    max: 3,
                    divisions: 3,
                    onChanged: (v) => setModalState(() => correct = v.toInt())),
                ElevatedButton(
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('quizzes')
                          .add({
                        'question': qC.text,
                        'options': optC.map((e) => e.text).toList(),
                        'correctAnswer': correct,
                        'category': cat,
                      });
                      SoundManager.playCorrect();
                      Navigator.pop(context);
                    },
                    child: const Text("حفظ")),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showBulkUploadForm(BuildContext context) {
    final TextEditingController jsonController = TextEditingController();
    String selectedCat = "دوري النجوم";
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("رفع مجمع بتنسيق JSON",
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
              DropdownButton<String>(
                value: selectedCat,
                isExpanded: true,
                items: ["دوري النجوم", "دوري المحترفين"]
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => selectedCat = v!),
              ),
              TextField(
                  controller: jsonController,
                  maxLines: 8,
                  decoration: const InputDecoration(
                      hintText:
                          '[{"question": "...", "options": [".."], "correctAnswer": 0}]',
                      border: OutlineInputBorder())),
              const SizedBox(height: 15),
              ElevatedButton(
                  onPressed: () async {
                    try {
                      List<dynamic> newList = jsonDecode(jsonController.text);
                      for (var item in newList) {
                        await FirebaseFirestore.instance
                            .collection('quizzes')
                            .add({
                          'question': item['question'],
                          'options': List<String>.from(item['options']),
                          'correctAnswer': item['correctAnswer'],
                          'category': selectedCat,
                          'createdAt': FieldValue.serverTimestamp(),
                        });
                      }
                      SoundManager.playCorrect();
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("تم الرفع بنجاح!")));
                    } catch (e) {
                      SoundManager.playWrong();
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("خطأ في التنسيق")));
                    }
                  },
                  child: const Text("بدء الرفع")),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class TopicManager extends StatefulWidget {
  const TopicManager({super.key});
  @override
  State<TopicManager> createState() => _TopicManagerState();
}

class _TopicManagerState extends State<TopicManager> {
  String query = "";
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _buildActionBtn(
          context, "إضافة موضوع تعليمي", Icons.article, () => _showTopicForm()),
      _buildSearchField("بحث في المواضيع...", (v) => setState(() => query = v)),
      Expanded(
          child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('topics').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                var filtered = snapshot.data!.docs
                    .where((d) => d['title'].toString().contains(query))
                    .toList();
                return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, i) => _buildListTile(
                            filtered[i]['title'], filtered[i]['category'], () {
                          SoundManager.playWrong();
                          filtered[i].reference.delete();
                        }));
              }))
    ]);
  }

  void _showTopicForm() {
    final tC = TextEditingController();
    final cC = TextEditingController();
    final imgC = TextEditingController();
    String selectedCategory = "المعلومة بتفرق";
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (c) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("إضافة موضوع جديد",
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                DropdownButton<String>(
                  value: selectedCategory,
                  isExpanded: true,
                  items: ["المعلومة بتفرق", "عرف عميلك"]
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setModalState(() => selectedCategory = v!),
                ),
                TextField(
                    controller: imgC,
                    decoration:
                        const InputDecoration(labelText: "رابط الصورة")),
                TextField(
                    controller: tC,
                    decoration: const InputDecoration(labelText: "العنوان")),
                TextField(
                    controller: cC,
                    maxLines: 5,
                    decoration: const InputDecoration(labelText: "المحتوى")),
                ElevatedButton(
                  onPressed: () async {
                    if (tC.text.isEmpty) return;
                    await FirebaseFirestore.instance.collection('topics').add({
                      'title': tC.text,
                      'content': cC.text,
                      'category': selectedCategory,
                      'imageUrl': imgC.text,
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                    SoundManager.playCorrect();
                    _sendNotification("موضوع جديد 📚", tC.text);
                    Navigator.pop(context);
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
                  borderSide: BorderSide.none))));
}

Widget _buildActionBtn(
    BuildContext context, String title, IconData icon, VoidCallback onTap) {
  return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, color: Colors.white, size: 18),
          label: Text(title,
              style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 12)),
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDeepTeal,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)))));
}

Widget _buildListTile(String title, String sub, VoidCallback onDel) {
  return Card(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
      child: ListTile(
          title: Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(sub, style: const TextStyle(fontSize: 12)),
          trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: onDel)));
}

Widget _infoRow(String label, String value) {
  return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Text(label,
            style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold, color: AppColors.primaryDeepTeal)),
        const SizedBox(width: 10),
        Expanded(child: Text(value, style: GoogleFonts.cairo()))
      ]));
}

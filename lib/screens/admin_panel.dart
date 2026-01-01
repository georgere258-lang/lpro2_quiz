import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart'; // ضروري لميزة النسخ
import 'admin_messages_list.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  String _currentView = "menu"; // menu, addQuestion, manageTeam, bulkUpload

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _qController = TextEditingController();
  final TextEditingController _bulkController = TextEditingController();
  final List<TextEditingController> _opts =
      List.generate(4, (_) => TextEditingController());

  int _correctIndex = 0;
  String _selectedCategory = "دوري النجوم";
  final List<String> _categories = [
    "دوري النجوم",
    "دوري المحترفين",
    "المعلومة بتفرق",
    "الماستر بلان"
  ];

  final Color deepTeal = const Color(0xFF1B4D57);
  final Color safetyOrange = const Color(0xFFE67E22);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F8),
      appBar: AppBar(
        title: Text(_getAppBarTitle(),
            style: GoogleFonts.cairo(
                color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: deepTeal,
        centerTitle: true,
        leading: _currentView != "menu"
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => setState(() => _currentView = "menu"))
            : null,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: _buildBody(),
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_currentView) {
      case "addQuestion":
        return "إضافة سؤال عقاري";
      case "manageTeam":
        return "إدارة فريق العمل والبيانات";
      case "bulkUpload":
        return "الرفع الجماعي للأسئلة";
      default:
        return "لوحة تحكم أبطال Pro";
    }
  }

  Widget _buildBody() {
    switch (_currentView) {
      case "addQuestion":
        return _buildQuestionForm();
      case "manageTeam":
        return _buildTeamManager();
      case "bulkUpload":
        return _buildBulkUploadForm();
      default:
        return _buildAdminMenu();
    }
  }

  Widget _buildAdminMenu() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildMenuCard("إدارة الأسئلة", "إضافة سؤال منفرد", Icons.quiz,
            Colors.blue, () => setState(() => _currentView = "addQuestion")),
        const SizedBox(height: 15),
        _buildMenuCard(
            "الرفع الجماعي",
            "إضافة مجموعة أسئلة دفعة واحدة",
            Icons.cloud_upload,
            Colors.teal,
            () => setState(() => _currentView = "bulkUpload")),
        const SizedBox(height: 15),
        _buildMenuCard("رسائل الدعم الفني", "الرد على استفسارات المستخدمين",
            Icons.message, Colors.orange, () {
          Navigator.push(context,
              MaterialPageRoute(builder: (c) => const AdminMessagesList()));
        }),
        const SizedBox(height: 15),
        _buildMenuCard(
            "إدارة فريق العمل",
            "عرض الأرقام وتعديل الصلاحيات",
            Icons.people_alt,
            Colors.purple,
            () => setState(() => _currentView = "manageTeam")),
      ],
    );
  }

  Widget _buildBulkUploadForm() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
              "انسخ الأسئلة هنا بالتنسيق التالي:\nالسؤال، خيار1، خيار2، خيار3، خيار4، رقم الإجابة الصحيحة (0-3)",
              style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey[700])),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            items: _categories
                .map((cat) => DropdownMenuItem(
                    value: cat, child: Text(cat, style: GoogleFonts.cairo())))
                .toList(),
            onChanged: (v) => setState(() => _selectedCategory = v!),
            decoration:
                const InputDecoration(labelText: "تحديد القسم للمجموعة"),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: TextField(
              controller: _bulkController,
              maxLines: null,
              expands: true,
              decoration: InputDecoration(
                hintText: "مثال:\nكم عدد أحياء التجمع، 3، 5، 7، 9، 2",
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: safetyOrange,
                minimumSize: const Size(double.infinity, 50)),
            onPressed: _processBulkUpload,
            icon: const Icon(Icons.rocket_launch, color: Colors.white),
            label: Text("بدء الرفع الجماعي الصاروخي",
                style: GoogleFonts.cairo(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _processBulkUpload() async {
    if (_bulkController.text.isEmpty) return;
    final batch = FirebaseFirestore.instance.batch();
    final lines = _bulkController.text.split('\n');
    int count = 0;
    try {
      for (var line in lines) {
        if (line.trim().isEmpty) continue;
        final parts = line.split('،');
        if (parts.length < 6) continue;
        final ref = FirebaseFirestore.instance.collection('quizzes').doc();
        batch.set(ref, {
          'question': parts[0].trim(),
          'options': [
            parts[1].trim(),
            parts[2].trim(),
            parts[3].trim(),
            parts[4].trim()
          ],
          'correctAnswer': int.parse(parts[5].trim()),
          'category': _selectedCategory,
          'createdAt': FieldValue.serverTimestamp(),
        });
        count++;
      }
      await batch.commit();
      _bulkController.clear();
      setState(() => _currentView = "menu");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("تم رفع $count سؤال بنجاح!")));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("خطأ في التنسيق: $e")));
    }
  }

  // ميزة إدارة الفريق المحدثة (رؤية الأرقام + استخراج الأرقام)
  Widget _buildTeamManager() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
          return const Center(child: Text("لا يوجد مستخدمين"));

        return Column(
          children: [
            // زر استخراج الأرقام (نسخ الكل)
            Padding(
              padding: const EdgeInsets.all(10),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                icon: const Icon(Icons.copy_all, color: Colors.white),
                label: Text("نسخ جميع أرقام الهواتف",
                    style: GoogleFonts.cairo(color: Colors.white)),
                onPressed: () {
                  String allPhones = "";
                  for (var doc in snapshot.data!.docs) {
                    var data = doc.data() as Map<String, dynamic>;
                    if (data.containsKey('phone') && data['phone'] != null) {
                      allPhones += "${data['phone']}\n";
                    }
                  }
                  if (allPhones.isNotEmpty) {
                    Clipboard.setData(ClipboardData(text: allPhones));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("تم نسخ جميع الأرقام بنجاح!")));
                  }
                },
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: snapshot.data!.docs.length,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                itemBuilder: (context, index) {
                  var doc = snapshot.data!.docs[index];
                  Map<String, dynamic> data =
                      doc.data() as Map<String, dynamic>;
                  String name = data['name'] ?? "بطل مجهول";
                  String role = data['role'] ?? "user";
                  String phone = data['phone'] ?? "غير متوفر"; // جلب الرقم

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    child: ListTile(
                      leading: CircleAvatar(
                          backgroundColor: deepTeal.withOpacity(0.1),
                          child: Icon(Icons.person, color: deepTeal)),
                      title: Text(name,
                          style:
                              GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("الرقم: $phone",
                              style: GoogleFonts.cairo(
                                  fontSize: 12, color: Colors.blueGrey)),
                          Text("الصلاحية: $role",
                              style: GoogleFonts.cairo(fontSize: 11)),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (String newRole) async {
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(doc.id)
                              .update({'role': newRole});
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                              value: "user", child: Text("مستخدم")),
                          const PopupMenuItem(
                              value: "admin", child: Text("مدير (Admin)")),
                        ],
                        child: Icon(Icons.more_vert, color: deepTeal),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuestionForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            items: _categories
                .map((cat) => DropdownMenuItem(
                    value: cat, child: Text(cat, style: GoogleFonts.cairo())))
                .toList(),
            onChanged: (v) => setState(() => _selectedCategory = v!),
            decoration: const InputDecoration(labelText: "اختر القسم/الدوري"),
          ),
          const SizedBox(height: 15),
          TextFormField(
              controller: _qController,
              decoration: const InputDecoration(labelText: "السؤال"),
              validator: (v) => v!.isEmpty ? "ادخل السؤال" : null),
          ...List.generate(
              4,
              (i) => TextFormField(
                  controller: _opts[i],
                  decoration: InputDecoration(labelText: "خيار ${i + 1}"),
                  validator: (v) => v!.isEmpty ? "ادخل الخيار" : null)),
          const SizedBox(height: 20),
          DropdownButtonFormField<int>(
            value: _correctIndex,
            items: List.generate(
                4,
                (i) => DropdownMenuItem(
                    value: i, child: Text("خيار ${i + 1} هو الصحيح"))),
            onChanged: (v) => setState(() => _correctIndex = v!),
            decoration: const InputDecoration(labelText: "الإجابة الصحيحة"),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: deepTeal, padding: const EdgeInsets.all(15)),
            onPressed: _saveQuestion,
            child: Text("حفظ السؤال",
                style: GoogleFonts.cairo(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _saveQuestion() async {
    if (_formKey.currentState!.validate()) {
      await FirebaseFirestore.instance.collection('quizzes').add({
        'question': _qController.text,
        'options': _opts.map((e) => e.text).toList(),
        'correctAnswer': _correctIndex,
        'category': _selectedCategory,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _qController.clear();
      for (var e in _opts) {
        e.clear();
      }
      setState(() => _currentView = "menu");
    }
  }

  Widget _buildMenuCard(String title, String sub, IconData icon, Color color,
      VoidCallback onTap) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color)),
        title:
            Text(title, style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        subtitle: Text(sub, style: GoogleFonts.cairo(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

// استيراد شاشة قائمة الرسائل لضمان الترابط
import 'admin_messages_list.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  final Color deepTeal = const Color(0xFF1B4D57);
  final Color safetyOrange = const Color(0xFFE67E22);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "لوحة تحكم أبطال Pro",
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: deepTeal,
          centerTitle: true,
          elevation: 0,
          bottom: TabBar(
            indicatorColor: safetyOrange,
            indicatorWeight: 3,
            labelStyle:
                GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12),
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(text: "الأخبار", icon: Icon(Icons.campaign)),
              Tab(text: "الأسئلة", icon: Icon(Icons.quiz)),
              Tab(text: "المواضيع", icon: Icon(Icons.article)),
              Tab(text: "الدعم", icon: Icon(Icons.chat_bubble)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
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

// --- 1. إدارة شريط الأخبار ---
class NewsManager extends StatelessWidget {
  const NewsManager({super.key});

  void _addNews(BuildContext context) {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("إضافة خبر جديد",
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          maxLines: 2,
          decoration: const InputDecoration(
            hintText: "اكتب نص الخبر هنا...",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c), child: const Text("إلغاء")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B4D57)),
            onPressed: () {
              if (controller.text.isNotEmpty) {
                FirebaseFirestore.instance.collection('news').add({
                  'content': controller.text,
                  'createdAt': FieldValue.serverTimestamp(),
                });
                Navigator.pop(c);
              }
            },
            child: const Text("إضافة", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildActionBtn(context, "إضافة جملة لشريط الأخبار", Icons.add_comment,
            () => _addNews(context)),
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
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var doc = snapshot.data!.docs[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      title: Text(doc['content'],
                          style: GoogleFonts.cairo(fontSize: 14)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_sweep, color: Colors.red),
                        onPressed: () => doc.reference.delete(),
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
}

// --- 2. إدارة الأسئلة (دوري النجوم / المحترفين) ---
class QuizManager extends StatefulWidget {
  const QuizManager({super.key});
  @override
  State<QuizManager> createState() => _QuizManagerState();
}

class _QuizManagerState extends State<QuizManager> {
  void _showQuizForm({DocumentSnapshot? doc}) {
    final isEdit = doc != null;
    final qController =
        TextEditingController(text: isEdit ? doc['question'] : "");
    final imgController =
        TextEditingController(text: isEdit ? doc['imageUrl'] : "");
    List<TextEditingController> optControllers = List.generate(
        4, (i) => TextEditingController(text: isEdit ? doc['options'][i] : ""));
    int correctIdx = isEdit ? doc['correctAnswer'] : 0;
    String category = isEdit ? doc['category'] : "دوري النجوم";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        // تم إزالة const من هنا
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
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
                Text(isEdit ? "تعديل سؤال" : "إضافة سؤال جديد",
                    style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration:
                      const InputDecoration(border: OutlineInputBorder()),
                  items: ["دوري النجوم", "دوري المحترفين"]
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setModalState(() => category = v!),
                ),
                const SizedBox(height: 10),
                TextField(
                    controller: qController,
                    decoration: const InputDecoration(
                        labelText: "السؤال", border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(
                    controller: imgController,
                    decoration: const InputDecoration(
                        labelText: "رابط الصورة (اختياري)",
                        border: OutlineInputBorder())),
                const SizedBox(height: 10),
                ...List.generate(
                    4,
                    (i) => Row(
                          children: [
                            Radio(
                                value: i,
                                groupValue: correctIdx,
                                onChanged: (v) =>
                                    setModalState(() => correctIdx = v as int)),
                            Expanded(
                                child: TextField(
                                    controller: optControllers[i],
                                    decoration: InputDecoration(
                                        labelText: "الخيار ${i + 1}"))),
                          ],
                        )),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B4D57),
                      minimumSize: const Size(double.infinity, 50)),
                  onPressed: () {
                    final data = {
                      'question': qController.text,
                      'imageUrl': imgController.text,
                      'options': optControllers.map((e) => e.text).toList(),
                      'correctAnswer': correctIdx,
                      'category': category,
                    };
                    isEdit
                        ? doc.reference.update(data)
                        : FirebaseFirestore.instance
                            .collection('quizzes')
                            .add(data);
                    Navigator.pop(context);
                  },
                  child: Text("حفظ السؤال",
                      style: GoogleFonts.cairo(color: Colors.white)),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildActionBtn(
            context, "إضافة سؤال جديد", Icons.add_task, () => _showQuizForm()),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance.collection('quizzes').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              return ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var doc = snapshot.data!.docs[index];
                  bool isStars = doc['category'] == "دوري النجوم";
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                    child: ListTile(
                      onTap: () => _showQuizForm(doc: doc),
                      leading: Icon(Icons.quiz,
                          color: isStars ? Colors.blue : Colors.orange),
                      title: Text(doc['question'],
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(doc['category']),
                      trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => doc.reference.delete()),
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
}

// --- 3. إدارة المواضيع (المعلومة بتفرق / افهم عميلك) ---
class TopicManager extends StatefulWidget {
  const TopicManager({super.key});
  @override
  State<TopicManager> createState() => _TopicManagerState();
}

class _TopicManagerState extends State<TopicManager> {
  void _showTopicForm({DocumentSnapshot? doc}) {
    final isEdit = doc != null;
    final titleController =
        TextEditingController(text: isEdit ? doc['title'] : "");
    final contentController =
        TextEditingController(text: isEdit ? doc['content'] : "");
    final imgController =
        TextEditingController(text: isEdit ? doc['imageUrl'] : "");
    String category = isEdit ? doc['category'] : "المعلومة بتفرق";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        // تم إزالة const من هنا
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
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
                Text(isEdit ? "تعديل موضوع" : "إضافة موضوع جديد",
                    style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration:
                      const InputDecoration(border: OutlineInputBorder()),
                  items: ["المعلومة بتفرق", "افهم عميلك"]
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setModalState(() => category = v!),
                ),
                const SizedBox(height: 10),
                TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                        labelText: "العنوان", border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(
                    controller: contentController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                        labelText: "المحتوى", border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(
                    controller: imgController,
                    decoration: const InputDecoration(
                        labelText: "رابط الصورة (URL)",
                        border: OutlineInputBorder())),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B4D57),
                      minimumSize: const Size(double.infinity, 50)),
                  onPressed: () {
                    final data = {
                      'title': titleController.text,
                      'content': contentController.text,
                      'imageUrl': imgController.text,
                      'category': category,
                    };
                    isEdit
                        ? doc.reference.update(data)
                        : FirebaseFirestore.instance
                            .collection('topics')
                            .add(data);
                    Navigator.pop(context);
                  },
                  child: const Text("حفظ الموضوع",
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildActionBtn(context, "إضافة موضوع جديد", Icons.library_add,
            () => _showTopicForm()),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('topics').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              return ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var doc = snapshot.data!.docs[index];
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                    child: ListTile(
                      onTap: () => _showTopicForm(doc: doc),
                      leading: doc['imageUrl'] != ""
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: Image.network(doc['imageUrl'],
                                  width: 45, height: 45, fit: BoxFit.cover))
                          : const Icon(Icons.article, size: 40),
                      title: Text(doc['title'],
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(doc['category']),
                      trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => doc.reference.delete()),
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
}

// ويدجت زر الإضافة الموحد الفخم
Widget _buildActionBtn(
    BuildContext context, String title, IconData icon, VoidCallback onTap) {
  return Padding(
    padding: const EdgeInsets.all(15.0),
    child: InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF1B4D57),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 10),
            Text(title,
                style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ],
        ),
      ),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'admin_messages_list.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  bool _isAddingQuestion = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _qController = TextEditingController();
  final List<TextEditingController> _opts =
      List.generate(4, (_) => TextEditingController());

  int _correctIndex = 0;
  String _selectedCategory = "دوري النجوم"; // افتراضي لضمان التنظيم
  final List<String> _categories = [
    "دوري النجوم",
    "دوري المحترفين",
    "المعلومة بتفرق",
    "الماستر بلان"
  ];

  final Color deepTeal = const Color(0xFF1B4D57);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F8),
      appBar: AppBar(
        title: Text(
            _isAddingQuestion ? "إضافة سؤال لأبطال Pro" : "لوحة تحكم أبطال Pro",
            style: GoogleFonts.cairo(
                color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: deepTeal,
        centerTitle: true,
        leading: _isAddingQuestion
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => setState(() => _isAddingQuestion = false))
            : null,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: _isAddingQuestion ? _buildQuestionForm() : _buildAdminMenu(),
      ),
    );
  }

  Widget _buildAdminMenu() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildMenuCard("إدارة الأسئلة", "أضف أسئلة جديدة للمسابقات", Icons.quiz,
            Colors.blue, () {
          setState(() => _isAddingQuestion = true);
        }),
        const SizedBox(height: 15),
        _buildMenuCard("رسائل أبطال Pro", "الرد على استفسارات الوحوش",
            Icons.message, Colors.orange, () {
          Navigator.push(context,
              MaterialPageRoute(builder: (c) => const AdminMessagesList()));
        }),
      ],
    );
  }

  Widget _buildMenuCard(String title, String sub, IconData icon, Color color,
      VoidCallback onTap) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
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

  Widget _buildQuestionForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // إضافة اختيار القسم لضمان ظهور السؤال في مكانه الصحيح
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
            decoration: const InputDecoration(labelText: "السؤال العقاري"),
            validator: (v) => v!.isEmpty ? "ادخل السؤال" : null,
          ),
          ...List.generate(
              4,
              (i) => TextFormField(
                    controller: _opts[i],
                    decoration: InputDecoration(labelText: "خيار رقم ${i + 1}"),
                    validator: (v) => v!.isEmpty ? "ادخل الخيار" : null,
                  )),
          const SizedBox(height: 20),
          DropdownButtonFormField<int>(
            value: _correctIndex,
            items: List.generate(
                4,
                (i) => DropdownMenuItem(
                    value: i, child: Text("خيار رقم ${i + 1} هو الصحيح"))),
            onChanged: (v) => setState(() => _correctIndex = v!),
            decoration: const InputDecoration(labelText: "حدد الإجابة الصحيحة"),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: deepTeal, padding: const EdgeInsets.all(15)),
            onPressed: _saveQuestion,
            child: Text("حفظ السؤال في بنك أبطال Pro",
                style: GoogleFonts.cairo(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _saveQuestion() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance.collection('quizzes').add({
          'question': _qController.text,
          'options': _opts.map((e) => e.text).toList(),
          'correctAnswer': _correctIndex,
          'category': _selectedCategory, // الحقل الجديد لفرز الأسئلة
          'createdAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("تم حفظ السؤال بنجاح في أبطال Pro")));

        _qController.clear();
        for (var e in _opts) {
          e.clear();
        }
        setState(() => _isAddingQuestion = false);
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("حدث خطأ: $e")));
      }
    }
  }
}

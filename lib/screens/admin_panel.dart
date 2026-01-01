import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  final _formKey = GlobalKey<FormState>();

  // التحكم في النصوص لتسهيل مسحها بعد الحفظ
  final TextEditingController _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers =
      List.generate(4, (_) => TextEditingController());

  int _correctAnswerIndex = 0;
  String _selectedCategory = 'دوري النجوم';

  // ألوان الهوية البصرية
  final Color deepTeal = const Color(0xFF1B4D57);
  final Color safetyOrange = const Color(0xFFE67E22);

  void _submitData() async {
    if (_formKey.currentState!.validate()) {
      try {
        // إظهار مؤشر تحميل
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (c) => const Center(child: CircularProgressIndicator()),
        );

        await FirebaseFirestore.instance.collection('quizzes').add({
          'question': _questionController.text.trim(),
          'options': _optionControllers.map((c) => c.text.trim()).toList(),
          'correctAnswer': _correctAnswerIndex,
          'category': _selectedCategory,
          'createdAt': FieldValue.serverTimestamp(),
        });

        Navigator.pop(context); // إغلاق مؤشر التحميل
        _clearForm();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("تم إضافة السؤال بنجاح إلى $_selectedCategory ✅",
                style: GoogleFonts.cairo()),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("حدث خطأ: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _clearForm() {
    _questionController.clear();
    for (var controller in _optionControllers) {
      controller.clear();
    }
    setState(() {
      _correctAnswerIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F8),
      appBar: AppBar(
        title: Text("إدارة المحتوى العقاري",
            style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: deepTeal,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _clearForm,
          )
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle("1. تصنيف المحتوى"),
                _buildCategorySelector(),
                const SizedBox(height: 25),
                _buildSectionTitle("2. نص السؤال العقاري"),
                _buildCustomField(
                  controller: _questionController,
                  label: "اكتب السؤال هنا...",
                  maxLines: 3,
                  icon: Icons.quiz_outlined,
                ),
                const SizedBox(height: 25),
                _buildSectionTitle("3. خيارات الإجابة"),
                ...List.generate(4, (index) => _buildOptionField(index)),
                const SizedBox(height: 25),
                _buildSectionTitle("4. تحديد الإجابة الصحيحة"),
                _buildCorrectAnswerPicker(),
                const SizedBox(height: 40),
                _buildSubmitButton(),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- مكونات واجهة المستخدم المطورة ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 5),
      child: Text(title,
          style: GoogleFonts.cairo(
              fontSize: 16, fontWeight: FontWeight.w900, color: deepTeal)),
    );
  }

  Widget _buildCategorySelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: deepTeal.withOpacity(0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: safetyOrange),
          items: [
            'دوري النجوم',
            'دوري المحترفين',
            'المعلومة بتفرق',
            'الماستر بلان'
          ]
              .map((c) => DropdownMenuItem(
                  value: c, child: Text(c, style: GoogleFonts.cairo())))
              .toList(),
          onChanged: (v) => setState(() => _selectedCategory = v!),
        ),
      ),
    );
  }

  Widget _buildCustomField(
      {required TextEditingController controller,
      required String label,
      int maxLines = 1,
      required IconData icon}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: GoogleFonts.cairo(fontSize: 14),
        decoration: InputDecoration(
          hintText: label,
          prefixIcon: Icon(icon, color: deepTeal, size: 20),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.all(15),
        ),
        validator: (v) => v!.isEmpty ? "هذا الحقل مطلوب" : null,
      ),
    );
  }

  Widget _buildOptionField(int index) {
    bool isSelected = _correctAnswerIndex == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: _buildCustomField(
              controller: _optionControllers[index],
              label: "الخيار رقم ${index + 1}",
              icon: Icons.circle_outlined,
            ),
          ),
          const SizedBox(width: 10),
          // زر اختيار سريع للإجابة الصحيحة بجانب كل خيار
          IconButton(
            icon: Icon(isSelected ? Icons.check_circle : Icons.radio_button_off,
                color: isSelected ? Colors.green : Colors.grey),
            onPressed: () => setState(() => _correctAnswerIndex = index),
          )
        ],
      ),
    );
  }

  Widget _buildCorrectAnswerPicker() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(4, (index) {
          bool isSelected = _correctAnswerIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _correctAnswerIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? safetyOrange : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text("${index + 1}",
                  style: GoogleFonts.cairo(
                      color: isSelected ? Colors.white : Colors.black54,
                      fontWeight: FontWeight.bold)),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(colors: [deepTeal, const Color(0xFF2C5F6A)]),
        boxShadow: [
          BoxShadow(
              color: deepTeal.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5))
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        onPressed: _submitData,
        child: Text("حفظ السؤال في القاعدة السحابية 🚀",
            style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
      ),
    );
  }

  @override
  void dispose() {
    _questionController.dispose();
    for (var c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }
}

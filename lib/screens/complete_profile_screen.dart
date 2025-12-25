import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main_wrapper.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _expController = TextEditingController();
  bool _isLoading = false;

  // دالة الحفظ (سواء ببيانات أو بيانات افتراضية عند التخطي)
  Future<void> _saveData({bool isSkipped = false}) async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      
      await FirebaseFirestore.instance.collection('users').doc(user?.uid).set({
        'name': isSkipped ? "مستخدم جديد" : _nameController.text.trim(),
        'email': isSkipped ? "" : _emailController.text.trim(),
        'experience': isSkipped ? "0" : _expController.text.trim(),
        'phone': user?.phoneNumber,
        'points': 0,
        'level': 'مبتدئ عقاري',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainWrapper()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("حدث خطأ: $e")),
      );
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("الملف الشخصي"),
        centerTitle: true,
        actions: [
          // زر التخطي في الأعلى
          TextButton(
            onPressed: () => _saveData(isSkipped: true),
            child: const Text("تخطي", style: TextStyle(color: Colors.grey, fontSize: 16)),
          ),
        ],
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF102A43),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 45,
              backgroundColor: Color(0xFFF0F4F8),
              child: Icon(Icons.person_outline, size: 50, color: Color(0xFF102A43)),
            ),
            const SizedBox(height: 10),
            const Text("أكمل بياناتك لتوثيق حسابك (اختياري)", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),
            _buildInput(_nameController, "الاسم الكامل", Icons.person_outline),
            const SizedBox(height: 15),
            _buildInput(_emailController, "البريد الإلكتروني", Icons.email_outlined),
            const SizedBox(height: 15),
            _buildInput(_expController, "سنوات الخبرة", Icons.trending_up, type: TextInputType.number),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF102A43),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: _isLoading ? null : () => _saveData(isSkipped: false),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("حفظ ومتابعة", style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String label, IconData icon, {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: type,
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF102A43)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }
}
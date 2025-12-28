import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main_wrapper.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  // --- ميثاق ألوان باكدج 3 المعتمد (LPro Deep Teal) ---
  static const Color deepTeal = Color(0xFF005F6B);     // اللون القائد
  static const Color safetyOrange = Color(0xFFFF8C00); // لون الأكشن (10%)
  static const Color iceWhite = Color(0xFFF8F9FA);     // الخلفية (60%)
  static const Color darkTealText = Color(0xFF002D33); // نصوص العناوين

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _expController = TextEditingController();
  bool _isLoading = false;

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
        SnackBar(
          content: Text("حدث خطأ في الحفظ: $e", style: GoogleFonts.cairo(fontSize: 13)),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: iceWhite,
      appBar: AppBar(
        title: Text("الملف الشخصي", style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        actions: [
          // زر التخطي بلمحة احترافية
          TextButton(
            onPressed: () => _saveData(isSkipped: true),
            child: Text("تخطي الآن", style: GoogleFonts.cairo(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.bold)),
          ),
        ],
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: darkTealText,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          children: [
            // أيقونة التعريف بلمسة فيروزية ناعمة
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: deepTeal.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_add_alt_1_rounded, size: 70, color: deepTeal),
            ),
            const SizedBox(height: 25),
            Text(
              "أكمل بياناتك لتوثيق هويتك كخبير عقاري", 
              style: GoogleFonts.cairo(color: Colors.grey[700], fontSize: 14, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 45),
            
            _buildInput(_nameController, "الاسم الكامل", Icons.person_outline_rounded),
            const SizedBox(height: 20),
            _buildInput(_emailController, "البريد الإلكتروني", Icons.email_outlined),
            const SizedBox(height: 20),
            _buildInput(_expController, "سنوات الخبرة في السوق", Icons.trending_up_rounded, type: TextInputType.number),
            
            const SizedBox(height: 60),
            
            // زر الحفظ والمتابعة باللون الفيروزي العميق الفخم
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: deepTeal,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shadowColor: deepTeal.withOpacity(0.3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                onPressed: _isLoading ? null : () => _saveData(isSkipped: false),
                child: _isLoading 
                  ? const SizedBox(height: 25, width: 25, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text("حفظ ومتابعة التميز", style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 17)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String label, IconData icon, {TextInputType type = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          keyboardType: type,
          textAlign: TextAlign.right,
          style: GoogleFonts.cairo(fontSize: 15, color: darkTealText, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: GoogleFonts.cairo(color: Colors.grey[600], fontSize: 14),
            prefixIcon: Icon(icon, color: deepTeal, size: 22),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: deepTeal.withOpacity(0.12)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: deepTeal, width: 1.8),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          ),
        ),
      ],
    );
  }
}
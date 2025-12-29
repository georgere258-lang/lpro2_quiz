import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_screen.dart'; 

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  static const Color deepTeal = Color(0xFF1B4D57); 
  static const Color safetyOrange = Color(0xFFE67E22); 
  static const Color iceWhite = Color(0xFFF8F9FA);
  static const Color darkTealText = Color(0xFF002D33);

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _expController = TextEditingController();
  bool _isLoading = false;

  Future<void> _saveData({bool isSkipped = false}) async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      
      // نستخدم doc(user?.uid) لضمان ربط البيانات بالحساب المسجل حالياً
      await FirebaseFirestore.instance.collection('users').doc(user?.uid).set({
        'name': isSkipped ? "مستشار عقاري جديد" : _nameController.text.trim(),
        'email': isSkipped ? "" : _emailController.text.trim(),
        'experience': isSkipped ? "0" : _expController.text.trim(),
        'phone': user?.phoneNumber,
        'points': 0, // النقاط تبدأ من الصفر
        'level': 'مبتدئ عقاري', // المستوى الافتراضي
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        // الانتقال للهوم وحذف شاشة الإدخال من الذاكرة
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
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
        title: Text("إكمال الملف", style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => _saveData(isSkipped: true),
            child: Text("تخطي", style: GoogleFonts.cairo(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.bold)),
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
            // أيقونة ترحيبية
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
              "أهلاً بكِ مريم! أكملي بياناتك لنبدأ الرحلة", 
              style: GoogleFonts.cairo(color: Colors.grey[700], fontSize: 14, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 45),
            
            _buildInput(_nameController, "الاسم الكامل", Icons.person_outline_rounded),
            const SizedBox(height: 20),
            _buildInput(_emailController, "البريد الإلكتروني", Icons.email_outlined, type: TextInputType.emailAddress),
            const SizedBox(height: 20),
            _buildInput(_expController, "سنوات الخبرة", Icons.trending_up_rounded, type: TextInputType.number),
            
            const SizedBox(height: 60),
            
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: deepTeal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                onPressed: _isLoading ? null : () => _saveData(isSkipped: false),
                child: _isLoading 
                  ? const SizedBox(height: 25, width: 25, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text("حفظ ومتابعة", style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 17)),
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
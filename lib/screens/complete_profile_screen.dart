import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'home_screen.dart'; 

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  // استخدام الألوان الموحدة للهوية
  static const Color deepTeal = Color(0xFF1B4D57); 
  static const Color safetyOrange = Color(0xFFE67E22); 

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _expController = TextEditingController();
  bool _isLoading = false;

  Future<void> _saveData({bool isSkipped = false}) async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      
      await FirebaseFirestore.instance.collection('users').doc(user?.uid).set({
        'name': isSkipped ? "مستشار عقاري جديد" : _nameController.text.trim(),
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
      backgroundColor: deepTeal, // تغيير الخلفية لتناسب هوية التطبيق
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => _saveData(isSkipped: true),
            child: Text(
              "تخطي", 
              style: GoogleFonts.cairo(color: Colors.white60, fontSize: 14, fontWeight: FontWeight.bold)
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30.0),
        child: Column(
          children: [
            // اللوجو والجملة الشهيرة (التأكيد على البراند)
            SvgPicture.asset('assets/logo.svg', height: 80),
            const SizedBox(height: 10),
            Text(
              "المعلومة بتفرق",
              style: GoogleFonts.cairo(
                color: safetyOrange,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 40),
            
            Text(
              "أكملي بياناتكِ يا مريم", 
              style: GoogleFonts.cairo(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 35),
            
            // حقول الإدخال بتصميم داكن وراقي
            _buildInput(_nameController, "الاسم الكامل", Icons.person_outline_rounded),
            const SizedBox(height: 20),
            _buildInput(_emailController, "البريد الإلكتروني", Icons.email_outlined, type: TextInputType.emailAddress),
            const SizedBox(height: 20),
            _buildInput(_expController, "سنوات الخبرة", Icons.trending_up_rounded, type: TextInputType.number),
            
            const SizedBox(height: 50),
            
            // زر الحفظ بتصميم متناسق مع "يلا Pro"
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: safetyOrange, // استخدام البرتقالي للزر الرئيسي
                  foregroundColor: Colors.white,
                  elevation: 5,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: _isLoading ? null : () => _saveData(isSkipped: false),
                child: _isLoading 
                  ? const SizedBox(height: 25, width: 25, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text("حفظ ومتابعة", style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 17)),
              ),
            ),
            const SizedBox(height: 20),
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
      style: GoogleFonts.cairo(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.cairo(color: Colors.white60, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.white70, size: 22),
        filled: true,
        fillColor: Colors.white.withOpacity(0.08), // خلفية الحقل شفافة هادئة
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: safetyOrange, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      ),
    );
  }
}
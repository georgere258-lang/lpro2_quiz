import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
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
  static const Color deepTeal = Color(0xFF1B4D57); 
  static const Color safetyOrange = Color(0xFFE67E22); 

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _expController = TextEditingController();
  bool _isLoading = false;

  String _replaceArabicNumbers(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    for (int i = 0; i < arabic.length; i++) {
      input = input.replaceAll(arabic[i], english[i]);
    }
    return input;
  }

  Future<void> _saveData({bool isSkipped = false}) async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      String processedExp = isSkipped ? "0" : _replaceArabicNumbers(_expController.text.trim());

      await FirebaseFirestore.instance.collection('users').doc(user?.uid).set({
        'name': isSkipped ? "مستشار عقاري جديد" : _nameController.text.trim(),
        'email': isSkipped ? "" : _emailController.text.trim(),
        'experience': processedExp,
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
      backgroundColor: deepTeal,
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
            
            _buildInput(_nameController, "الاسم الكامل", Icons.person_outline_rounded),
            const SizedBox(height: 20),
            _buildInput(_emailController, "البريد الإلكتروني", Icons.email_outlined, type: TextInputType.emailAddress),
            const SizedBox(height: 20),
            
            _buildInput(
              _expController, 
              "سنوات الخبرة", 
              Icons.trending_up_rounded, 
              type: TextInputType.number,
              isNumeric: true,
            ),
            
            const SizedBox(height: 50),
            
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: safetyOrange,
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

  Widget _buildInput(TextEditingController controller, String label, IconData icon, 
      {TextInputType type = TextInputType.text, bool isNumeric = false}) {
    return Directionality(
      textDirection: TextDirection.rtl, // حل مشكلة اتجاه الكتابة بالعربي
      child: TextField(
        controller: controller,
        keyboardType: type,
        textAlign: TextAlign.right,
        style: isNumeric 
            ? GoogleFonts.poppins(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)
            : GoogleFonts.cairo(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w600),
        
        inputFormatters: isNumeric ? [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
        ] : null,

        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.cairo(color: Colors.white60, fontSize: 14),
          prefixIcon: Icon(icon, color: Colors.white70, size: 22),
          filled: true,
          fillColor: Colors.white.withOpacity(0.08),
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
      ),
    );
  }
}
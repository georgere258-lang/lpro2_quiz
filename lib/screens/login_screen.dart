import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main_wrapper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isCodeSent = false;
  final Color deepTeal = const Color(0xFF1B4D57);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: deepTeal,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            children: [
              Image.asset('assets/top_brand.png', height: 100, colorBlendMode: BlendMode.dstATop, color: deepTeal),
              const SizedBox(height: 40),
              Text(isCodeSent ? "أدخل كود التحقق" : "سجل دخولك",
                style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 30),
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                child: TextField(
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    prefixIcon: isCodeSent ? null : const Padding(padding: EdgeInsets.all(15), child: Text("+20 ", style: TextStyle(fontWeight: FontWeight.bold))),
                    hintText: isCodeSent ? "0 0 0 0" : "رقم الموبايل",
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(15),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8C00), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  onPressed: () {
                    if (!isCodeSent) { setState(() => isCodeSent = true); }
                    else { Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const MainWrapper())); }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(isCodeSent ? "تأكيد" : "إرسال الكود", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
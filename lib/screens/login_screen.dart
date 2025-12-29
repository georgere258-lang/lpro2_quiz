import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'complete_profile_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isOtpStage = false;
  String selectedCountry = "🇪🇬 +20";
  final Color deepTeal = const Color(0xFF1B4D57);
  final Color safetyOrange = const Color(0xFFE67E22);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: deepTeal,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            children: [
              const SizedBox(height: 80), // تقليل المسافة قليلاً لتناسب الجملة الجديدة
              SvgPicture.asset('assets/logo.svg', height: 110), // حجم اللوجو متناسق
              
              const SizedBox(height: 12),
              
              // إضافة جملة المعلومة بتفرق تحت اللوجو مباشرة
              Text(
                "المعلومة بتفرق",
                style: GoogleFonts.cairo(
                  color: safetyOrange,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),

              const SizedBox(height: 40),
              
              Text(
                isOtpStage ? "تأكيد الرمز" : "تسجيل الدخول",
                style: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 40),
              
              // المربعات مجبورة على اتجاه اليسار للأرقام (LTR)
              Directionality(
                textDirection: TextDirection.ltr, 
                child: isOtpStage ? _buildOtpInput() : _buildPhoneInput(),
              ),
              
              const SizedBox(height: 40),
              
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: safetyOrange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: () {
                    if (!isOtpStage) {
                      setState(() => isOtpStage = true);
                    } else {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (c) => const CompleteProfileScreen()),
                      );
                    }
                  },
                  child: Text(
                    isOtpStage ? "تأكيد" : "إرسال الرمز",
                    style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneInput() {
    return TextField(
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 2),
      textAlign: TextAlign.left,
      decoration: InputDecoration(
        hintText: "010XXXXXXXX",
        hintStyle: const TextStyle(color: Colors.white38, letterSpacing: 0),
        prefixIcon: PopupMenuButton<String>(
          initialValue: selectedCountry,
          onSelected: (val) => setState(() => selectedCountry = val),
          itemBuilder: (context) => [
            const PopupMenuItem(value: "🇪🇬 +20", child: Text("مصر 🇪🇬")),
            const PopupMenuItem(value: "🇦🇪 +971", child: Text("الإمارات 🇦🇪")),
            const PopupMenuItem(value: "🇸🇦 +966", child: Text("السعودية 🇸🇦")),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(selectedCountry, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const Icon(Icons.arrow_drop_down, color: Colors.white),
              ],
            ),
          ),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildOtpInput() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(4, (index) => SizedBox(
        width: 60,
        child: TextField(
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            counterText: "",
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      )),
    );
  }
}
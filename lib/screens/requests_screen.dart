import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RequestsScreen extends StatelessWidget {
  const RequestsScreen({super.key});

  // --- ميثاق ألوان باكدج 3 المعتمد (LPro Deep Teal) ---
  static const Color deepTeal = Color(0xFF005F6B);     // اللون القائد
  static const Color safetyOrange = Color(0xFFFF8C00); // لون الأكشن والمثلث
  static const Color iceWhite = Color(0xFFF8F9FA);     // الخلفية
  static const Color darkTealText = Color(0xFF002D33); // نصوص العناوين

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: iceWhite,
      appBar: AppBar(
        title: Text(
          "إرسال طلب جديد",
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: deepTeal,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // [المطلوب]: الجملة التحفيزية الخاصة بإرسال البيانات
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: safetyOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: safetyOrange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.stars_rounded, color: safetyOrange),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "يا وحش العقارات، كل طلب ترسليه يقربكِ أكثر من صدارة الدوري! 🚀",
                      style: GoogleFonts.cairo(
                        fontSize: 12, 
                        fontWeight: FontWeight.bold, 
                        color: deepTeal
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            Text(
              "بيانات العميل المستهدف",
              style: GoogleFonts.cairo(
                fontSize: 16, 
                fontWeight: FontWeight.bold, 
                color: deepTeal
              ),
            ),
            const SizedBox(height: 25),
            
            _buildInputField(
              label: "اسم العميل", 
              icon: Icons.person_outline_rounded,
              hint: "أدخل الاسم الرباعي للعميل"
            ),
            const SizedBox(height: 20),
            
            _buildInputField(
              label: "رقم هاتف العميل", 
              icon: Icons.phone_android_rounded,
              hint: "01xxxxxxxxx",
              type: TextInputType.phone
            ),
            const SizedBox(height: 20),
            
            _buildInputField(
              label: "ملاحظات إضافية", 
              icon: Icons.note_alt_outlined,
              hint: "اذكر اهتمامات العميل أو المنطقة المطلوبة بالتفصيل",
              maxLines: 4
            ),
            
            const SizedBox(height: 40),
            
            // [تثبيت]: زر الإرسال بلون المثلث البرتقالي الساطع
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () {
                  // سيتم ربط منطق Firestore هنا
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: safetyOrange,
                  foregroundColor: Colors.white,
                  elevation: 5,
                  shadowColor: safetyOrange.withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(
                  "تأكيد وإرسال البيانات",
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold, 
                    fontSize: 17
                  ),
                ),
              ),
            ),
            const SizedBox(height: 25),
            Center(
              child: Column(
                children: [
                  const Icon(Icons.security_rounded, size: 20, color: Colors.green),
                  const SizedBox(height: 5),
                  Text(
                    "بيانات العميل مشفرة ومحمية بالكامل",
                    style: GoogleFonts.cairo(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label, 
    required IconData icon, 
    String? hint, 
    int maxLines = 1,
    TextInputType type = TextInputType.text
  }) {
    return TextField(
      maxLines: maxLines,
      keyboardType: type,
      textAlign: TextAlign.right,
      style: GoogleFonts.cairo(fontSize: 15, color: darkTealText, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.cairo(color: deepTeal, fontSize: 14, fontWeight: FontWeight.bold),
        hintText: hint,
        hintStyle: GoogleFonts.cairo(color: Colors.grey[400], fontSize: 13),
        prefixIcon: Icon(icon, color: deepTeal, size: 22),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: deepTeal.withOpacity(0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: deepTeal, width: 2),
        ),
        contentPadding: const EdgeInsets.all(18),
      ),
    );
  }
}
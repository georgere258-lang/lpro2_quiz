import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MasterPlanScreen extends StatefulWidget {
  const MasterPlanScreen({super.key});

  @override
  State<MasterPlanScreen> createState() => _MasterPlanScreenState();
}

class _MasterPlanScreenState extends State<MasterPlanScreen> {
  static const Color deepTeal = Color(0xFF1B4D57);
  static const Color safetyOrange = Color(0xFFE67E22);

  // قائمة التحديات (يمكنك إضافة المزيد هنا)
  final List<Map<String, dynamic>> masterPlanChallenges = [
    {
      "image": "assets/top_brand.png", // تأكدي من وضع صورة المخطط الحقيقية هنا لاحقاً
      "question": "هذا المخطط يخص أي مشروع في التجمع الخامس؟",
      "options": ["ماونتن فيو آي سيتي", "بالم هيلز نيو كايرو", "ميفيدا"],
      "answer": "ماونتن فيو آي سيتي"
    },
  ];

  int currentIndex = 0;
  String? selectedOption;
  bool showFeedback = false;

  void _handleAnswer(String selected) {
    if (showFeedback) return;

    setState(() {
      selectedOption = selected;
      showFeedback = true;
    });

    // الانتظار ثانية واحدة قبل الانتقال للتحدي التالي أو إظهار النتيجة
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        // إذا كان هناك تحديات أخرى، ننتقل إليها
        // حالياً سنقوم فقط بإعادة ضبط الحالة للتجربة
        setState(() {
          showFeedback = false;
          selectedOption = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var currentChallenge = masterPlanChallenges[currentIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: deepTeal,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "تحدي الماستر بلان",
          style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: const BackButton(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              width: double.infinity,
              color: deepTeal.withOpacity(0.05),
              child: Text(
                "حلل المخطط واختر المشروع الصحيح.. المعلومة بتفرق!",
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(color: deepTeal, fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))
                  ],
                ),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                      child: Container(
                        height: 300,
                        color: Colors.grey.shade100,
                        child: InteractiveViewer(
                          minScale: 0.5,
                          maxScale: 4.0,
                          child: Image.asset(
                            currentChallenge['image'],
                            width: double.infinity,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Text(
                        currentChallenge['question'],
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: deepTeal),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                children: currentChallenge['options'].map<Widget>((option) {
                  return _buildOption(option, currentChallenge['answer']);
                }).toList(),
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(String text, String correctAnswer) {
    Color btnColor = Colors.white;
    Color textColor = deepTeal;
    BorderSide border = BorderSide(color: Colors.grey.shade200);

    if (showFeedback) {
      if (text == correctAnswer) {
        btnColor = Colors.green.shade500;
        textColor = Colors.white;
        border = BorderSide.none;
      } else if (text == selectedOption) {
        btnColor = Colors.red.shade400;
        textColor = Colors.white;
        border = BorderSide.none;
      }
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 15),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: btnColor,
          foregroundColor: textColor,
          elevation: showFeedback ? 0 : 2,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: border,
          ),
        ),
        onPressed: () => _handleAnswer(text),
        child: Text(
          text,
          style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
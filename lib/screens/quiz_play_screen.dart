import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class QuizPlayScreen extends StatefulWidget {
  const QuizPlayScreen({super.key});

  @override
  State<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends State<QuizPlayScreen> {
  // --- ميثاق ألوان باكدج 3 المعتمد (LPro Deep Teal) ---
  static const Color deepTeal = Color(0xFF005F6B);     // اللون القائد
  static const Color safetyOrange = Color(0xFFFF8C00); // لون المثلث والتحفيز (10%)
  static const Color iceWhite = Color(0xFFF8F9FA);     // الخلفية (60%)
  static const Color darkTealText = Color(0xFF002D33); // نصوص العناوين

  int _currentQuestionIndex = 0;
  int _score = 0;

  final List<Map<String, dynamic>> _questions = [
    {
      "question": "ماذا يعني مصطلح ROI في الاستثمار العقاري؟",
      "options": ["العائد على الاستثمار", "ضريبة المبيعات", "مساحة الأرض", "عمولة السمسار"],
      "answer": 0
    },
    {
      "question": "أي من المناطق التالية تعتبر عاصمة مصر الإدارية الجديدة؟",
      "options": ["التجمع الخامس", "الشيخ زايد", "العاصمة الإدارية", "أكتوبر"],
      "answer": 2
    },
    {
      "question": "ما هو 'عقد البيع الابتدائي' في القانون المصري؟",
      "options": ["عقد مسجل بالشهر العقاري", "عقد يثبت الاتفاق قبل التسجيل", "عقد إيجار قديم", "شهادة ميلاد العقار"],
      "answer": 1
    },
  ];

  void _checkAnswer(int selectedIndex) {
    bool isCorrect = selectedIndex == _questions[_currentQuestionIndex]["answer"];
    if (isCorrect) _score += 100;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isCorrect ? "إجابة عبقرية! 🎉" : "للأسف خطأ ❌",
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(color: isCorrect ? deepTeal : Colors.redAccent, fontWeight: FontWeight.bold),
        ),
        // [المطلوب]: الجملة التحفيزية
        content: Text(
          isCorrect ? "وحش عقارات حقيقي! ربحت 100 نقطة خبرة" : "لا بأس، المحارب يتعلم من أخطائه. ركزي في القادم!",
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(color: const Color(0xFF4A4A4A), fontSize: 14),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isCorrect ? deepTeal : const Color(0xFF5A5A5A),
              padding: const EdgeInsets.symmetric(horizontal: 30),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context);
              _nextQuestion();
            },
            child: Text("متابعة التحدي", style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  void _nextQuestion() {
    setState(() {
      if (_currentQuestionIndex < _questions.length - 1) {
        _currentQuestionIndex++;
      } else {
        _showFinalResult();
      }
    });
  }

  void _showFinalResult() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: Text(
          "اكتملت المعركة! 🏆",
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(color: deepTeal, fontWeight: FontWeight.w900, fontSize: 24),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("أداء استثنائي يا مريم، رصيدك الآن:", style: GoogleFonts.cairo(fontSize: 15)),
            const SizedBox(height: 15),
            // [المطلوب]: عرض النقاط باللون البرتقالي (المثلث)
            Text("$_score", style: GoogleFonts.poppins(fontSize: 45, fontWeight: FontWeight.bold, color: safetyOrange)),
            Text("نقطة تميز", style: GoogleFonts.cairo(color: safetyOrange, fontWeight: FontWeight.bold)),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: safetyOrange,
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 5,
              shadowColor: safetyOrange.withOpacity(0.4),
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text("حفظ الإنجاز", style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = _questions[_currentQuestionIndex];

    return Scaffold(
      backgroundColor: iceWhite,
      appBar: AppBar(
        backgroundColor: deepTeal,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "تحدي وحوش LPro", 
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.white)
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          children: [
            // [المطلوب]: شريط التقدم البرتقالي لزيادة الحماس
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: (_currentQuestionIndex + 1) / _questions.length,
                minHeight: 12,
                backgroundColor: deepTeal.withOpacity(0.1),
                color: safetyOrange, 
              ),
            ),
            const SizedBox(height: 40),
            Text(
              currentQuestion["question"],
              style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.bold, color: darkTealText, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ...List.generate(
              currentQuestion["options"].length,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(20),
                      backgroundColor: Colors.white,
                      surfaceTintColor: Colors.white,
                      elevation: 3,
                      shadowColor: deepTeal.withOpacity(0.1),
                      side: BorderSide(color: deepTeal.withOpacity(0.15), width: 1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    onPressed: () => _checkAnswer(index),
                    child: Text(
                      currentQuestion["options"][index], 
                      style: GoogleFonts.cairo(fontSize: 16, color: darkTealText, fontWeight: FontWeight.w600)
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
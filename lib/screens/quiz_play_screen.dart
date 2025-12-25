import 'package:flutter/material.dart';

class QuizPlayScreen extends StatefulWidget {
  const QuizPlayScreen({super.key});

  @override
  State<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends State<QuizPlayScreen> {
  int _currentQuestionIndex = 0;
  int _score = 0;

  // قائمة الأسئلة (يمكنك زيادتها لاحقاً)
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
        title: Text(isCorrect ? "إجابة صحيحة! 🎉" : "للأسف خطأ ❌"),
        content: Text(isCorrect ? "حصلت على 100 نقطة" : "حاول مرة أخرى في السؤال القادم"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _nextQuestion();
            },
            child: const Text("متابعة"),
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
        title: const Text("انتهى التحدي! 🏆"),
        content: Text("إجمالي نقاطك: $_score"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // قفل الدايلوج
              Navigator.pop(context); // العودة لشاشة المستويات
            },
            child: const Text("الخروج"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = _questions[_currentQuestionIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(title: Text("سؤال ${_currentQuestionIndex + 1}")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) / _questions.length,
              backgroundColor: Colors.grey[300],
              color: Colors.blue,
            ),
            const SizedBox(height: 40),
            Text(
              currentQuestion["question"],
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
                      padding: const EdgeInsets.all(15),
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _checkAnswer(index),
                    child: Text(currentQuestion["options"][index], style: const TextStyle(fontSize: 18)),
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
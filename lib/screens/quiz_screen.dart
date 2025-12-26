import 'package:flutter/material.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  // ألوان الثيم المتفق عليها
  static const Color brandOrange = Color(0xFFFF4D00);
  static const Color electricBlue = Color(0xFF00D2FF);
  static const Color navyDark = Color(0xFF080E1D);

  int _currentIndex = 0;
  bool _showAnswer = false;

  // قائمة المعلومات الحقيقية (تقدري تعدلي الأسئلة دي بسهولة)
  final List<Map<String, String>> _questions = [
    {
      "question": "إيه هو 'التحميل' في المساحات العقارية؟",
      "answer": "هو الفرق بين المساحة الصافية للشقة والمساحة الإجمالية (بإضافة نصيبك في الأسانسير والسلم والمداخل). المعلومة الأمينة: التحميل الطبيعي بيكون من 20% لـ 25%.",
      "tip": "دايماً اسأل على المساحة الصافية (Net Area) قبل ما تمضي."
    },
    {
      "question": "يعني إيه استلام فوري 'نص تشطيب'؟",
      "answer": "يعني الشقة واصل لها كهرباء ومياه وصرف، ومحارة وحلوق خشب فقط. ده بيوفر لك فرصة تشطب على ذوقك الشخصي.",
      "tip": "اتأكد إن العدادات راكبة أو جاهزة للتركيب فوراً."
    },
    {
      "question": "ليه منطقة R7 في العاصمة الإدارية مميزة؟",
      "answer": "لأنها 'حي سكني متكامل' فيه أعلى نسبة إنجاز، وقريبة جداً من الحي الدبلوماسي والنهر الأخضر، وأسعارها حالياً تعتبر فرصة استثمارية.",
      "tip": "المنطقة دي هي أول منطقة هتسكن فعلياً في العاصمة."
    },
    {
      "question": "إيه الفرق بين المطور العقاري والمقاول؟",
      "answer": "المطور هو صاحب الفكرة والرؤية والتمويل والمسؤول أمامك، أما المقاول فهو الشركة اللي بتنفذ البناء فقط تحت إشراف المطور.",
      "tip": "دايماً دور على سابقة أعمال 'المطور' وقوته المالية."
    },
  ];

  void _nextQuestion() {
    setState(() {
      if (_currentIndex < _questions.length - 1) {
        _currentIndex++;
        _showAnswer = false;
      } else {
        // لو خلص الأسئلة يرجع للأول
        _currentIndex = 0;
        _showAnswer = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentQ = _questions[_currentIndex];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.5),
            radius: 1.2,
            colors: [Color(0xFF1E293B), navyDark],
          ),
        ),
        child: Column(
          children: [
            // AppBar مخصص
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        "نشط ذهنك عقارياً",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 48), // للتوازن
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // عداد الأسئلة
            Text(
              "معلومة ${_currentIndex + 1} من ${_questions.length}",
              style: const TextStyle(color: electricBlue, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 30),

            // كارت السؤال والجواب
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // أيقونة متغيرة
                    Icon(
                      _showAnswer ? Icons.lightbulb_rounded : Icons.help_outline_rounded,
                      color: _showAnswer ? Colors.amber : brandOrange,
                      size: 80,
                    ),
                    const SizedBox(height: 40),
                    
                    // السؤال
                    Text(
                      currentQ['question']!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, height: 1.3),
                    ),

                    if (_showAnswer) ...[
                      const SizedBox(height: 30),
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 20),
                      // الإجابة
                      Text(
                        currentQ['answer']!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
                      ),
                      const SizedBox(height: 20),
                      // نصيحة إضافية
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: electricBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          "💡 نصيحة مريم: ${currentQ['tip']}",
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: electricBlue, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // أزرار التحكم
            Padding(
              padding: const EdgeInsets.all(40),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _showAnswer ? brandOrange : electricBlue,
                  minimumSize: const Size(double.infinity, 65),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 10,
                  shadowColor: (_showAnswer ? brandOrange : electricBlue).withOpacity(0.4),
                ),
                onPressed: () {
                  if (!_showAnswer) {
                    setState(() => _showAnswer = true);
                  } else {
                    _nextQuestion();
                  }
                },
                child: Text(
                  _showAnswer ? "المعلومة التالية" : "اعرف الحقيقة",
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
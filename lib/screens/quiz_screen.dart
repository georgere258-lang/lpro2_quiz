import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

class QuizScreen extends StatefulWidget {
  final String categoryTitle;
  final bool isTextQuiz;

  const QuizScreen({super.key, required this.categoryTitle, this.isTextQuiz = false});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  // تم حذف const هنا لأن الألوان تُستخدم في ويدجيتس غير ثابتة
  final Color deepTeal = const Color(0xFF1B4D57);
  final Color safetyOrange = const Color(0xFFE67E22);
  final TextEditingController _ansController = TextEditingController();

  int currentQuestionIndex = 0;
  int score = 0;
  int timeLeft = 25;
  Timer? timer;
  bool gameStarted = false;
  String? selectedOption; 
  bool isCorrect = false; 
  bool showFeedback = false; 

  late List<Map<String, dynamic>> questions;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  // دالة توحيد الحروف العربية لضمان صحة المقارنة
  String normalizeArabic(String text) {
    text = text.trim(); 
    text = text.replaceAll(RegExp(r'[أإآ]'), 'ا');
    text = text.replaceAll(RegExp(r'[ى]'), 'ي');
    text = text.replaceAll(RegExp(r'[ة]'), 'ه');
    return text.toLowerCase(); 
  }

  void _loadQuestions() {
    if (widget.categoryTitle == "نشط ذهنك") {
      questions = [
        {"q": "كم عدد الأمتار في الفدان العقاري؟", "options": ["4200", "3500", "4000"], "a": "4200"},
        {"q": "ما هي أكبر مدينة سكنية في مصر؟", "options": ["6 أكتوبر", "القاهرة الجديدة", "العاصمة الإدارية"], "a": "6 أكتوبر"},
      ];
    } else {
      questions = [
        {"q": "أين تقع منطقة الجولدن سكوير؟", "options": ["التجمع", "زايد", "أكتوبر"], "a": "التجمع"},
        {"q": "ما هو اختصار العائد على الاستثمار؟", "options": ["ROI", "ROE", "ROA"], "a": "ROI"},
        {"q": "أكبر مطور عقاري في مصر من حيث محفظة الأراضي؟", "options": ["طلعت مصطفى", "سوديك", "إعمار"], "a": "طلعت مصطفى"},
      ];
    }
  }

  void _startTimer() {
    timeLeft = 25;
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (timeLeft > 0) {
        setState(() => timeLeft--);
      } else {
        _handleAnswer(""); 
      }
    });
  }

  void _handleAnswer(String selected) {
    if (showFeedback) return; 

    timer?.cancel();
    setState(() {
      selectedOption = selected;
      showFeedback = true;
      
      String normalizedUserAns = normalizeArabic(selected);
      String normalizedCorrectAns = normalizeArabic(questions[currentQuestionIndex]['a']);
      
      isCorrect = (normalizedUserAns == normalizedCorrectAns);
      if (isCorrect) score += 10;
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _nextStep();
      }
    });
  }

  void _nextStep() {
    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        showFeedback = false;
        selectedOption = null;
        _ansController.clear();
      });
      _startTimer();
    } else {
      _showResult();
    }
  }

  void _showResult() {
    timer?.cancel();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: Text("انتهى التحدي 🏆", textAlign: TextAlign.center, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: deepTeal)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("المعلومة فرقت معاك!", style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 15),
            Text("$score", style: GoogleFonts.poppins(fontSize: 40, fontWeight: FontWeight.w900, color: safetyOrange)),
            Text("نقطة", style: GoogleFonts.cairo(fontSize: 16, color: deepTeal)),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: deepTeal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              onPressed: () { Navigator.pop(context); Navigator.pop(context); },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text("العودة للرئيسية", style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!gameStarted) return _buildStartView();

    var q = questions[currentQuestionIndex];
    bool hasOptions = q.containsKey('options');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        backgroundColor: deepTeal,
        elevation: 0,
        centerTitle: true,
        title: Text("المعلومة بتفرق", style: GoogleFonts.cairo(color: safetyOrange, fontWeight: FontWeight.bold, fontSize: 18)),
        leading: const BackButton(color: Colors.white),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: timeLeft / 25, 
            color: timeLeft < 10 ? Colors.red : safetyOrange, 
            backgroundColor: Colors.grey.shade200,
            minHeight: 8,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(25),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("السكور: $score", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: safetyOrange, fontSize: 16)),
                      Text("سؤال ${currentQuestionIndex + 1}/${questions.length}", style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: deepTeal)),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(20),
                    width: double.infinity,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
                    child: Text(q['q'], style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: deepTeal, height: 1.5), textAlign: TextAlign.center),
                  ),
                  const SizedBox(height: 40),
                  hasOptions ? _buildOptions(q['options']) : _buildTextInput(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextInput() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: TextField(
        controller: _ansController,
        keyboardType: TextInputType.text,
        textAlign: TextAlign.right,
        style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: deepTeal),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s\u0600-\u06FF]')),
        ],
        decoration: InputDecoration(
          hintText: "اكتب إجابتك هنا...",
          hintStyle: GoogleFonts.cairo(fontSize: 16, color: Colors.grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: deepTeal)),
          filled: true, fillColor: Colors.white,
          // تم حذف كلمة const من هنا لحل مشكلة Error: Not a constant expression
          prefixIcon: Icon(Icons.edit_note, color: deepTeal),
        ),
        onSubmitted: (val) => _handleAnswer(val),
      ),
    );
  }

  Widget _buildOptions(List<dynamic> options) {
    return Column(
      children: options.map((opt) {
        Color cardColor = Colors.white;
        Color textColor = deepTeal;
        
        if (showFeedback) {
          if (opt == questions[currentQuestionIndex]['a']) {
            cardColor = Colors.green.shade400; textColor = Colors.white;
          } else if (opt == selectedOption) {
            cardColor = Colors.red.shade400; textColor = Colors.white;
          }
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 15),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            child: InkWell(
              onTap: () => _handleAnswer(opt),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
                  border: Border.all(color: showFeedback ? cardColor : Colors.grey.shade200),
                ),
                child: Text(opt, textAlign: TextAlign.center, style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStartView() {
    String headerTitle = widget.categoryTitle;
    IconData headerIcon = widget.categoryTitle == "نشط ذهنك" ? Icons.psychology : Icons.military_tech;

    return Scaffold(
      backgroundColor: deepTeal,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(headerIcon, size: 80, color: safetyOrange),
            const SizedBox(height: 20),
            Text(headerTitle, style: GoogleFonts.cairo(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 60),
            SizedBox(
              width: 220, height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: safetyOrange, 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))
                ),
                onPressed: () { setState(() => gameStarted = true); _startTimer(); },
                child: Text("يلا بينا", style: GoogleFonts.cairo(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() { 
    timer?.cancel(); 
    _ansController.dispose(); 
    super.dispose(); 
  }
}
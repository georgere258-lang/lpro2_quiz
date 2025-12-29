import 'package:flutter/material.dart';
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
  final Color deepTeal = const Color(0xFF1B4D57);
  final Color safetyOrange = const Color(0xFFE67E22);
  final Color darkOrange = const Color(0xFFD35400); 
  final TextEditingController _ansController = TextEditingController();

  int currentQuestionIndex = 0;
  int score = 0;
  int timeLeft = 25;
  Timer? timer;
  bool isAnswered = false;
  bool gameStarted = false;
  late List<Map<String, dynamic>> questions;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  void _loadQuestions() {
    questions = [
      {"q": "أين تقع منطقة الجولدن سكوير؟", "options": ["التجمع", "زايد", "أكتوبر"], "a": "التجمع"},
      {"q": "ما هو اختصار العائد على الاستثمار؟", "a": "ROI"},
    ];
  }

  void _startTimer() {
    timeLeft = 25;
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (timeLeft > 0) { setState(() => timeLeft--); } else { _nextStep(); }
    });
  }

  void _nextStep() {
    if (currentQuestionIndex < questions.length - 1) {
      setState(() { currentQuestionIndex++; isAnswered = false; _ansController.clear(); });
      _startTimer();
    } else { _showResult(); }
  }

  void _showResult() {
    timer?.cancel();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("انتهى التحدي 🏆", style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: Text("نقاطك: $score", textAlign: TextAlign.center, style: GoogleFonts.cairo(fontSize: 18)),
        actions: [
          Center(child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: deepTeal),
            onPressed: () { Navigator.pop(context); Navigator.pop(context); },
            child: Text("الرئيسية", style: GoogleFonts.cairo(color: Colors.white)),
          ))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!gameStarted) return _buildStartView();

    var q = questions[currentQuestionIndex];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: deepTeal,
        centerTitle: true,
        title: Text("المعلومة بتفرق", style: GoogleFonts.cairo(color: safetyOrange, fontWeight: FontWeight.bold)),
        leading: const BackButton(color: Colors.white),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(value: timeLeft / 25, color: safetyOrange, minHeight: 6),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(25),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Text("سؤال ${currentQuestionIndex + 1}", style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: deepTeal)),
                  const SizedBox(height: 20),
                  Text(q['q'], style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                  const SizedBox(height: 40),
                  widget.isTextQuiz ? _buildTextInput() : _buildOptions(q['options']),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextInput() {
    return TextField(
      controller: _ansController,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        hintText: "أدخل الرقم هنا",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        filled: true, fillColor: Colors.white,
      ),
      onSubmitted: (val) => _nextStep(),
    );
  }

  Widget _buildOptions(List<dynamic> options) {
    return Column(
      children: options.map((opt) => Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: InkWell(
          onTap: () => _nextStep(),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(opt, textAlign: TextAlign.center, style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: deepTeal)),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildStartView() {
    String headerTitle = "";
    String buttonText = "";

    if (widget.categoryTitle == "نشط ذهنك") {
      headerTitle = "نشط ذهنك"; buttonText = "يلا بينا";
    } else if (widget.categoryTitle == "دوري المحترفين") {
      headerTitle = "دوري المحترفين"; buttonText = "يله يا كبير";
    } else {
      headerTitle = "دوري النجوم"; buttonText = "يله يا نجم";
    }

    return Scaffold(
      backgroundColor: deepTeal,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        title: Text("المعلومة بتفرق", style: GoogleFonts.cairo(color: darkOrange, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(headerTitle, style: GoogleFonts.cairo(fontSize: 35, color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("المعلومة بتفرق", style: GoogleFonts.cairo(fontSize: 18, color: darkOrange, fontWeight: FontWeight.w600)),
            const SizedBox(height: 60),
            SizedBox(
              width: 200, height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: safetyOrange, 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))
                ),
                onPressed: () { setState(() => gameStarted = true); _startTimer(); },
                child: Text(buttonText, style: GoogleFonts.cairo(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() { timer?.cancel(); _ansController.dispose(); super.dispose(); }
}
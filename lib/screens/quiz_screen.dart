import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class QuizScreen extends StatefulWidget {
  final String categoryTitle;
  const QuizScreen({super.key, required this.categoryTitle});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final Color deepTeal = const Color(0xFF1B4D57);
  final Color safetyOrange = const Color(0xFFE67E22);

  int currentQuestionIndex = 0;
  int score = 0;
  int timeLeft = 25;
  Timer? timer;
  bool gameStarted = false;
  String? selectedOption;
  bool showFeedback = false;
  bool isLoading = true;

  List<Map<String, dynamic>> questions = [];

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('quizzes')
          .where('category', isEqualTo: widget.categoryTitle)
          .get();

      if (mounted) {
        setState(() {
          questions = snapshot.docs
              .map((doc) => {
                    "q": doc['question'],
                    "options": doc['options'],
                    "a": doc['options'][doc['correctAnswer']],
                  })
              .toList();
          questions.shuffle();
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("خطأ في جلب الأسئلة: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _startTimer() {
    timeLeft = 25;
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (timeLeft > 0) {
        if (mounted) setState(() => timeLeft--);
      } else {
        _handleAnswer("");
      }
    });
  }

  void _handleAnswer(String selected) {
    if (showFeedback) return;

    timer?.cancel();
    bool isCorrect = _normalize(selected) ==
        _normalize(questions[currentQuestionIndex]['a'] ?? "");

    if (isCorrect) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.heavyImpact();
    }

    setState(() {
      selectedOption = selected;
      showFeedback = true;

      if (isCorrect) {
        int basePoints = (widget.categoryTitle == "دوري النجوم") ? 20 : 10;
        int speedBonus = (timeLeft > 20) ? 5 : 0;
        score += basePoints + speedBonus;
      }
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) _nextStep();
    });
  }

  String _normalize(String text) {
    return text
        .trim()
        .replaceAll(RegExp(r'[أإآ]'), 'ا')
        .replaceAll(RegExp(r'[ى]'), 'ي')
        .replaceAll(RegExp(r'[ة]'), 'ه')
        .toLowerCase();
  }

  void _nextStep() {
    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        showFeedback = false;
        selectedOption = null;
      });
      _startTimer();
    } else {
      _saveScoreAndFinish();
    }
  }

  Future<void> _saveScoreAndFinish() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && score > 0) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'points': FieldValue.increment(score),
        'lastQuiz': DateTime.now(),
      });
    }
    _showResult();
  }

  void _showResult() {
    String rankMsg =
        score > 50 ? "وحش عقارات حقيقي! 🦁" : "بداية ممتازة يا بطل ✨";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, size: 80, color: Colors.amber),
            const SizedBox(height: 15),
            Text("تحدي مكتمل",
                style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: deepTeal)),
            Text(rankMsg,
                style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
              decoration: BoxDecoration(
                  color: safetyOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20)),
              child: Text("+$score",
                  style: GoogleFonts.poppins(
                      fontSize: 35,
                      fontWeight: FontWeight.w900, // تم التعديل من black
                      color: safetyOrange)),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: deepTeal,
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(15)), // تم الإصلاح هنا
                    padding: const EdgeInsets.all(12)),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: Text("العودة للرئيسية",
                    style: GoogleFonts.cairo(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
          backgroundColor: deepTeal,
          body: const Center(
              child: CircularProgressIndicator(color: Colors.white)));
    }
    if (questions.isEmpty) return _buildEmptyView();
    if (!gameStarted) return _buildStartView();

    var q = questions[currentQuestionIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        backgroundColor: deepTeal,
        elevation: 0,
        centerTitle: true,
        title: Text(widget.categoryTitle,
            style: GoogleFonts.cairo(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context)),
      ),
      body: Column(
        children: [
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 500),
            tween: Tween(begin: 0, end: timeLeft / 25),
            builder: (context, value, _) => LinearProgressIndicator(
              value: value,
              backgroundColor: Colors.grey[200],
              color: value < 0.3 ? Colors.red : safetyOrange,
              minHeight: 6,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(25),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _infoBadge("السكور: $score", safetyOrange),
                      _infoBadge(
                          "سؤال ${currentQuestionIndex + 1}/${questions.length}",
                          deepTeal),
                    ],
                  ),
                  const SizedBox(height: 30),
                  _buildQuestionCard(q['q']),
                  const SizedBox(height: 40),
                  _buildOptions(q['options']),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12)),
      child: Text(text,
          style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold, color: color, fontSize: 13)),
    );
  }

  Widget _buildQuestionCard(String question) {
    return Container(
      padding: const EdgeInsets.all(25),
      width: double.infinity,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5))
          ]),
      child: Text(question,
          style: GoogleFonts.cairo(
              fontSize: 19, fontWeight: FontWeight.bold, color: deepTeal),
          textAlign: TextAlign.center),
    );
  }

  Widget _buildOptions(List<dynamic> options) {
    return Column(
      children: options.map((opt) {
        bool isCorrect =
            showFeedback && opt == questions[currentQuestionIndex]['a'];
        bool isWrong = showFeedback &&
            opt == selectedOption &&
            opt != questions[currentQuestionIndex]['a'];

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 15),
          child: InkWell(
            onTap: () => _handleAnswer(opt),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isCorrect
                    ? Colors.green.shade500
                    : (isWrong ? Colors.red.shade500 : Colors.white),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: isCorrect || isWrong
                        ? Colors.transparent
                        : Colors.grey.shade200),
                boxShadow: isCorrect || isWrong
                    ? [
                        BoxShadow(
                            color: (isCorrect ? Colors.green : Colors.red)
                                .withOpacity(0.3),
                            blurRadius: 10)
                      ]
                    : null,
              ),
              child: Text(opt,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: (isCorrect || isWrong) ? Colors.white : deepTeal)),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStartView() {
    return Scaffold(
      backgroundColor: deepTeal,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                colors: [deepTeal, const Color(0xFF0D2A30)])),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.psychology, size: 100, color: Colors.amber),
            const SizedBox(height: 20),
            Text(widget.categoryTitle,
                style: GoogleFonts.cairo(
                    fontSize: 32,
                    color: Colors.white,
                    fontWeight: FontWeight.bold)),
            Text("استعد للاختبار وتجميع النقاط",
                style: GoogleFonts.cairo(color: Colors.white60)),
            const SizedBox(height: 60),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: safetyOrange,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 60, vertical: 15)),
              onPressed: () {
                setState(() => gameStarted = true);
                _startTimer();
              },
              child: Text("ابدأ التحدي",
                  style: GoogleFonts.cairo(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Scaffold(
        backgroundColor: deepTeal,
        body: Center(
            child: Text("لا توجد أسئلة حالياً لهذا القسم",
                style: GoogleFonts.cairo(color: Colors.white))));
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
}

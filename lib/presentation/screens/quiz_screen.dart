import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/sound_manager.dart';
import '../home/widgets/section_identity_card.dart';

class QuizScreen extends StatefulWidget {
  final String categoryTitle;

  const QuizScreen({super.key, required this.categoryTitle});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final Color primaryColor = AppColors.primaryDeepTeal;
  final Color accentColor = AppColors.secondaryOrange;

  int currentQuestionIndex = 0;
  int questionsInRound = 0;
  int roundNumber = 1;
  int roundScore = 0;

  int timeLeft = 0;
  Timer? timer;

  bool gameStarted = false;
  bool showFeedback = false;
  String? selectedOption;
  bool isLoading = true;

  List<Map<String, dynamic>> questions = [];

  @override
  void initState() {
    super.initState();
    _loadQuestions();
    _resetTimer();
  }

  void _resetTimer() {
    timeLeft = widget.categoryTitle == "دوري المحترفين" ? 15 : 25;
  }

  Future<void> _loadQuestions() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('quizzes')
          .where('category', isEqualTo: widget.categoryTitle)
          .get();

      questions = snapshot.docs.map((d) => d.data()).toList();
      questions.shuffle();

      setState(() => isLoading = false);
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _startTimer() {
    _resetTimer();
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (timeLeft > 0) {
        setState(() => timeLeft--);
      } else {
        _handleAnswer("");
      }
    });
  }

  void _handleAnswer(String answer) {
    if (showFeedback) return;

    timer?.cancel();
    final q = questions[currentQuestionIndex];
    bool isCorrect = answer == q['options'][q['correctAnswer']];

    setState(() {
      selectedOption = answer;
      showFeedback = true;
      questionsInRound++;

      if (isCorrect) {
        SoundManager.playCorrect();
        roundScore += widget.categoryTitle == "دوري النجوم" ? 2 : 5;
      } else {
        SoundManager.playWrong();
      }
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (questionsInRound >= 5) {
        _finishRound();
      } else {
        _nextQuestion();
      }
    });
  }

  void _nextQuestion() {
    setState(() {
      currentQuestionIndex++;
      showFeedback = false;
      selectedOption = null;
    });
    _startTimer();
  }

  Future<void> _finishRound() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final leagueField =
          widget.categoryTitle == "دوري النجوم" ? 'starsPoints' : 'proPoints';

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'points': FieldValue.increment(roundScore),
        leagueField: FieldValue.increment(roundScore),
        'dailyQuestionsCount': FieldValue.increment(5),
        'lastQuizDate': FieldValue.serverTimestamp(),
      });
    }

    _showResultSheet();
  }

  void _showResultSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(30),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("نتيجة الجولة $roundNumber",
                style: GoogleFonts.cairo(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: primaryColor)),
            const SizedBox(height: 15),
            Text("حصلت على $roundScore نقطة ⭐",
                style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: accentColor)),
            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  roundNumber++;
                  questionsInRound = 0;
                  roundScore = 0;
                  currentQuestionIndex++;
                  showFeedback = false;
                  selectedOption = null;
                });
                _startTimer();
              },
              child: const Text("استكمال الجولة"),
            ),
            TextButton(
              onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
              child: const Text("العودة للرئيسية"),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!gameStarted) return _buildIntro();

    final q = questions[currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(title: Text(widget.categoryTitle)),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            LinearProgressIndicator(
              value: timeLeft /
                  (widget.categoryTitle == "دوري المحترفين" ? 15 : 25),
              color: accentColor,
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(q['question'],
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                      fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            ...List.generate(q['options'].length, (i) {
              final opt = q['options'][i];
              final correct = q['options'][q['correctAnswer']];

              Color bg = Colors.white;
              if (showFeedback && opt == correct) bg = Colors.green;
              if (showFeedback && opt == selectedOption && opt != correct) {
                bg = Colors.red;
              }

              return GestureDetector(
                onTap: () => _handleAnswer(opt),
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Center(
                    child: Text(opt,
                        style: GoogleFonts.cairo(
                            color: bg == Colors.white
                                ? primaryColor
                                : Colors.white,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              );
            })
          ],
        ),
      ),
    );
  }

  Widget _buildIntro() {
    return Scaffold(
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SectionIdentityCard(
                sectionKey: widget.categoryTitle,
                icon: Icons.workspace_premium,
                title: widget.categoryTitle,
                description: "اختبر نفسك واطور مستواك يومياً",
                benefits: const [
                  "تحدي معرفي حقيقي",
                  "نقاط وترتيب",
                  "تطور يومي ثابت"
                ],
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  SoundManager.playTap();
                  setState(() => gameStarted = true);
                  _startTimer();
                },
                child: const Text("ابدأ التحدي"),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
}

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

  final List<String> _dailyWorkTasks = [
    "إيه رأيك تراجع مشروع 'سوديك' الجديد النهاردة؟ 🏗️",
    "ما تيجي تبص بصه على خريطة التجمع (منطقة النرجس)؟ 🗺️",
    "راجع مشاريع شركة 'إعمار' عشان تقارن الأسعار.. 💰",
    "وقت مراجعة الماستر بلان لبيت الوطن.. المعلومة بتفرق! 🚀",
    "إيه رأيك تتابع تطورات الأعمال في العاصمة الإدارية؟ 🏙️",
  ];

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

    setState(() {
      selectedOption = selected;
      showFeedback = true;
      if (isCorrect) {
        int pointsToAdd = (widget.categoryTitle == "دوري النجوم") ? 2 : 5;
        score += pointsToAdd;
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.heavyImpact();
      }
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        if ((currentQuestionIndex + 1) % 5 == 0 &&
            currentQuestionIndex != questions.length - 1) {
          _showInterimResult();
        } else {
          _nextStep();
        }
      }
    });
  }

  void _showInterimResult() {
    String msg = score >= 10
        ? "أداء مذهل يا بطل.. كمل الصدارة!"
        : "بداية جيدة.. ركز أكتر في الأسئلة الجاية!";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: Text("عاش يا وحش!",
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold, color: deepTeal)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(msg, textAlign: TextAlign.center, style: GoogleFonts.cairo()),
            const SizedBox(height: 20),
            Text("نقاطك: $score",
                style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: safetyOrange)),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: deepTeal,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              onPressed: () {
                Navigator.pop(context);
                _nextStep();
              },
              child: Text("كمل التحدي",
                  style: GoogleFonts.cairo(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
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

  Future<void> _saveScoreAndFinish({bool isExiting = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && score > 0) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'points': FieldValue.increment(score),
        'lastQuizDate': FieldValue.serverTimestamp(),
        'category_last_played': widget.categoryTitle,
      });
    }
    if (isExiting) {
      Navigator.pop(context);
      Navigator.pop(context);
    } else {
      _showFinalResult();
    }
  }

  void _showFinalResult() {
    String randomTask = (_dailyWorkTasks..shuffle()).first;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.stars_rounded, size: 80, color: Colors.amber),
            const SizedBox(height: 15),
            Text("المهمة تمت بنجاح!",
                style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 10),
            Text("لقد أثبتّ أنك بطل Pro حقيقي",
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: deepTeal.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(15)),
              child: Text("نصيحة اليوم: $randomTask",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                      color: deepTeal,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ),
            const SizedBox(height: 25),
            Text("مجموع نقاطك: $score",
                style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w900,
                    color: safetyOrange,
                    fontSize: 22)),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: deepTeal,
                    padding: const EdgeInsets.all(15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15))),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: Text("العودة للأبطال",
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
    if (isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (questions.isEmpty) return _buildEmptyView();
    if (!gameStarted) return _buildStartView();

    var q = questions[currentQuestionIndex];
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
          backgroundColor: deepTeal,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text("تحدي ${widget.categoryTitle}",
              style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white)),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white)),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            LinearProgressIndicator(
                value: timeLeft / 25,
                color: safetyOrange,
                backgroundColor: Colors.grey[200]),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  children: [
                    _buildQuestionCard(q['q']),
                    const SizedBox(height: 30),
                    Expanded(child: _buildOptions(q['options'])),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartView() {
    String subTitle = widget.categoryTitle == "دوري النجوم"
        ? "دائماً المعلومة بتفرق"
        : "أنت عارف قوة المعلومة";

    String btnText = widget.categoryTitle == "دوري النجوم"
        ? "يلا يا نجم 🚀"
        : "اتفضل Pro 🔥";

    // إعدادات البادج
    Color badgeColor = widget.categoryTitle == "دوري النجوم"
        ? const Color(0xFF3498DB)
        : const Color(0xFFE67E22);
    String badgeText =
        widget.categoryTitle == "دوري النجوم" ? "Fresh ✨" : "Pro 🔥";

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [deepTeal, const Color(0xFF0D2A30)])),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // البادج الجديد بتنسيق الكارت وحجم أكبر
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Text(
                badgeText,
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 30),
            Text(widget.categoryTitle,
                style: GoogleFonts.cairo(
                    fontSize: 32,
                    color: Colors.white,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            Text(subTitle,
                style: GoogleFonts.cairo(fontSize: 18, color: Colors.white70)),
            const SizedBox(height: 60),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: safetyOrange,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 60, vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30))),
              onPressed: () {
                setState(() => gameStarted = true);
                _startTimer();
              },
              child: Text(btnText,
                  style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(String text) {
    return Container(
      padding: const EdgeInsets.all(25),
      width: double.infinity,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10))
          ]),
      child: Text(text,
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(
              fontSize: 18, fontWeight: FontWeight.bold, color: deepTeal)),
    );
  }

  Widget _buildOptions(List<dynamic> options) {
    return ListView(
      children: options.map((opt) {
        bool isCorrect =
            showFeedback && opt == questions[currentQuestionIndex]['a'];
        bool isWrong = showFeedback &&
            opt == selectedOption &&
            opt != questions[currentQuestionIndex]['a'];

        return GestureDetector(
          onTap: () => _handleAnswer(opt),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.only(bottom: 15),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
                color: isCorrect
                    ? Colors.green
                    : (isWrong ? Colors.red : Colors.white),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  if (!showFeedback)
                    BoxShadow(
                        color: Colors.black.withOpacity(0.03), blurRadius: 10)
                ],
                border: Border.all(
                    color: isCorrect || isWrong
                        ? Colors.transparent
                        : Colors.grey.shade200)),
            child: Text(opt,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                    color: (isCorrect || isWrong) ? Colors.white : deepTeal,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyView() {
    return Scaffold(
        appBar: AppBar(
            backgroundColor: deepTeal,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            iconTheme: const IconThemeData(color: Colors.white)),
        body: Center(
            child: Text("البطولة ستبدأ قريباً.. لا توجد أسئلة حالياً",
                style: GoogleFonts.cairo())));
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
}

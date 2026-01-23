// PATH: lib/presentation/screens/quiz_screen.dart
// STATUS: FULL COMPLETED FILE – ✅ Answer Selection Fixed ✅ Premium UI Applied

import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/sound_manager.dart';
import '../home/widgets/section_identity_card.dart';
import '../widgets/lpro_bottom_nav_bar.dart';
import 'main_wrapper.dart';

class QuizScreen extends StatefulWidget {
  final String categoryTitle;

  const QuizScreen({super.key, required this.categoryTitle});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  static const int _roundsPerDay = 4;
  static const int _questionsPerRound = 5;

  final Color primaryColor = AppColors.primaryDeepTeal;
  final Color accentColor = AppColors.secondaryOrange;

  bool get _isStars => widget.categoryTitle == "دوري النجوم";
  String get _enterButtonText => _isStars ? "انت نجم Pro ⭐" : "ملعبك يا Pro 🔥";
  int get _secondsPerQuestion => _isStars ? 25 : 15;

  List<Map<String, dynamic>> _questions = [];
  bool _isLoading = true;
  bool _gameStarted = false;
  bool _showFeedback = false;
  String? _selectedOption;
  int _currentQuestionIndex = 0;
  int _questionIndexInRound = 0;
  int _roundScore = 0;
  int _correctAnswersCount = 0;
  int _roundsDoneToday = 0;
  Timer? _timer;
  int _timeLeft = 0;
  bool _isFreePlaySession = false;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController =
        AnimationController(vsync: this, duration: const Duration(seconds: 9))
          ..repeat(reverse: true);
    _loadQuestions();
    _loadUserDailyProgress();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('quizzes')
          .where('category', isEqualTo: widget.categoryTitle)
          .get();
      _questions = snapshot.docs.map((d) => d.data()).toList();
      _questions.shuffle();
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadUserDailyProgress() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final Timestamp? lastTs = data['lastQuizDate'] as Timestamp?;
        final int currentCount = data['dailyQuestionsCount'] ?? 0;

        final now = DateTime.now();
        bool isSameDay = false;

        if (lastTs != null) {
          final lastDate = lastTs.toDate();
          isSameDay = lastDate.day == now.day &&
              lastDate.month == now.month &&
              lastDate.year == now.year;
        }

        if (!isSameDay && currentCount > 0) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({
            'dailyQuestionsCount': 0,
          });
          if (mounted) setState(() => _roundsDoneToday = 0);
        } else {
          if (mounted) {
            setState(() => _roundsDoneToday =
                (currentCount ~/ _questionsPerRound).clamp(0, _roundsPerDay));
          }
        }
      }
    } catch (e) {
      debugPrint("Error loading progress: $e");
    }
  }

  void _startTimer() {
    _timeLeft = _secondsPerQuestion;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        _handleAnswer("");
      }
    });
  }

  void _startRound({required bool freePlay}) {
    if (_questions.isEmpty) return;
    setState(() {
      _isFreePlaySession = freePlay;
      _gameStarted = true;
      _showFeedback = false;
      _selectedOption = null;
      _questionIndexInRound = 0;
      _roundScore = 0;
      _correctAnswersCount = 0;
    });
    _startTimer();
  }

  void _handleAnswer(String answer) {
    if (_showFeedback) return;
    _timer?.cancel();
    final q = _questions[_currentQuestionIndex];
    final options = (q['options'] as List?)?.cast<String>() ?? [];
    final correct = options[q['correctAnswer'] ?? -1];
    setState(() {
      _selectedOption = answer;
      _showFeedback = true;
      if (answer == correct) {
        SoundManager.playCorrect();
        _roundScore += _isStars ? 2 : 5;
        _correctAnswersCount++;
      } else {
        SoundManager.playWrong();
      }
    });
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      if (_questionIndexInRound + 1 >= _questionsPerRound) {
        _finishRound();
      } else {
        _nextQuestion();
      }
    });
  }

  void _nextQuestion() {
    setState(() {
      _showFeedback = false;
      _selectedOption = null;
      _questionIndexInRound++;
      _currentQuestionIndex++;
      if (_currentQuestionIndex >= _questions.length) {
        _questions.shuffle();
        _currentQuestionIndex = 0;
      }
    });
    _startTimer();
  }

  Future<void> _finishRound() async {
    _currentQuestionIndex = (_currentQuestionIndex + 1) %
        (_questions.isEmpty ? 1 : _questions.length);
    if (!_isFreePlaySession) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'points': FieldValue.increment(_roundScore),
          _isStars ? 'starsPoints' : 'proPoints':
              FieldValue.increment(_roundScore),
          'dailyQuestionsCount': FieldValue.increment(_questionsPerRound),
          'lastQuizDate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      setState(() =>
          _roundsDoneToday = (_roundsDoneToday + 1).clamp(0, _roundsPerDay));
    }
    _showResultSheet();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_questions.isEmpty) return _buildEmptyState();
    if (!_gameStarted) return _buildIntro();

    final q = _questions[_currentQuestionIndex];
    final options = (q['options'] as List?)?.cast<String>() ?? [];
    final correct = options[q['correctAnswer'] ?? -1];

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
          title: Text(widget.categoryTitle,
              style: GoogleFonts.cairo(fontWeight: FontWeight.w900)),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.5),
                radius: 1.5,
                colors: [const Color(0xFF136161), primaryColor],
              ),
            ),
          ),
          foregroundColor: Colors.white,
          centerTitle: true),
      bottomNavigationBar: LProBottomNavBar(
        activeIndex: 1,
        onTap: (index) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => MainWrapper(initialIndex: index),
            ),
            (route) => false,
          );
        },
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Stack(
          children: [
            _animatedGlowBackground(),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _pill(
                          icon: Icons.quiz_outlined,
                          text:
                              "سؤال ${_questionIndexInRound + 1}/$_questionsPerRound",
                          color: primaryColor),
                      const SizedBox(width: 12),
                      _counterPill(_timeLeft.toString()),
                      const SizedBox(width: 12),
                      _pill(
                          icon: Icons.emoji_events_outlined,
                          text: _isFreePlaySession
                              ? "وضع التدريب"
                              : "جولة ${_roundsDoneToday + 1}",
                          color: primaryColor),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Column(
                      children: [
                        Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _questionCard(
                                child: Text(q['question'] ?? '',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.cairo(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                        color: primaryColor)))),
                        const SizedBox(height: 20),
                        Expanded(
                            child: ListView.separated(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 0, 20, 20),
                                itemCount: options.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, i) {
                                  final opt = options[i];
                                  Color bg = Colors.white;
                                  Color fg = primaryColor;
                                  if (_showFeedback && opt == correct) {
                                    bg = Colors.green;
                                    fg = Colors.white;
                                  }
                                  if (_showFeedback &&
                                      opt == _selectedOption &&
                                      opt != correct) {
                                    bg = Colors.red;
                                    fg = Colors.white;
                                  }
                                  // ✅ الإصلاح: إضافة GestureDetector لربط الضغطة بالدالة
                                  return GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => _handleAnswer(opt),
                                    child: _optionTile(opt, bg, fg),
                                  );
                                })),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntro() {
    final bool locked = _roundsDoneToday >= _roundsPerDay;
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
          backgroundColor: primaryColor,
          elevation: 0,
          centerTitle: true,
          automaticallyImplyLeading: false,
          toolbarHeight: 65,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.5),
                radius: 1.5,
                colors: [const Color(0xFF136161), primaryColor],
              ),
            ),
          ),
          title: Image.asset('assets/top_brand.png',
              height: 22, fit: BoxFit.contain)),
      bottomNavigationBar: LProBottomNavBar(
        activeIndex: 1,
        onTap: (index) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => MainWrapper(initialIndex: index),
            ),
            (route) => false,
          );
        },
      ),
      body: Stack(
        children: [
          _animatedGlowBackground(),
          Directionality(
            textDirection: TextDirection.rtl,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("الدوريات",
                        style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: primaryColor)),
                    const SizedBox(height: 14),
                    SectionIdentityCard(
                      sectionKey: widget.categoryTitle,
                      icon: _isStars
                          ? Icons.auto_awesome_rounded
                          : Icons.workspace_premium,
                      title: widget.categoryTitle,
                      description: _isStars ? "تثبيت الأساس…" : "اختبار حقيقي…",
                      benefits: _isStars
                          ? const ["مناسب للفريش", "ثبات وسط ضغط السوق"]
                          : const ["مناسب للمحترفين", "اختبار الفهم"],
                    ),
                    const SizedBox(height: 14),
                    _glassCard(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.emoji_events_outlined,
                                  color: primaryColor, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                  locked
                                      ? "أنهيت جولات اليوم ✅"
                                      : "تحدي اليوم: $_roundsDoneToday/$_roundsPerDay جولات",
                                  style: GoogleFonts.cairo(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      color:
                                          locked ? Colors.green : primaryColor))
                            ])),
                    const SizedBox(height: 16),
                    Center(
                        child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 280),
                            child: SizedBox(
                                height: 50,
                                width: double.infinity,
                                child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: accentColor,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(25)),
                                      elevation: 0,
                                    ),
                                    onPressed: () {
                                      SoundManager.playTap();
                                      _openDailyChallengeSheet();
                                    },
                                    child: FittedBox(
                                        child: Text(_enterButtonText,
                                            style: GoogleFonts.cairo(
                                                color: Colors.white,
                                                fontWeight:
                                                    FontWeight.w900))))))),
                    const SizedBox(height: 10),
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text("رجوع",
                            style: GoogleFonts.cairo(
                                fontWeight: FontWeight.w800,
                                color: Colors.blueGrey))),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openDailyChallengeSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final locked = _roundsDoneToday >= _roundsPerDay;
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(26))),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10))),
                  const SizedBox(height: 14),
                  Text("تحدي اليوم",
                      style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: primaryColor)),
                  const SizedBox(height: 8),
                  Text(
                      locked
                          ? "أنهيت حصتك الرسمية ✅"
                          : "جولتك القادمة: ${_roundsDoneToday + 1}/$_roundsPerDay",
                      style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: locked ? Colors.green : accentColor)),
                  const SizedBox(height: 16),
                  Center(
                      child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 280),
                          child: Column(children: [
                            SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: accentColor,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(25))),
                                    onPressed: locked
                                        ? null
                                        : () {
                                            Navigator.pop(context);
                                            _startRound(freePlay: false);
                                          },
                                    child: FittedBox(
                                        child: Text("ابدأ الجولة الآن",
                                            style: GoogleFonts.cairo(
                                                color: Colors.white,
                                                fontWeight:
                                                    FontWeight.w900))))),
                            const SizedBox(height: 12),
                            SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                        side: BorderSide(color: primaryColor),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(25))),
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _startRound(freePlay: true);
                                    },
                                    child: FittedBox(
                                        child: Text("Free Play — تدريب",
                                            style: GoogleFonts.cairo(
                                                fontWeight: FontWeight.w900,
                                                color: primaryColor))))),
                          ]))),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showResultSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final bool canPlayMore =
            !_isFreePlaySession && (_roundsDoneToday < _roundsPerDay);
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_isFreePlaySession ? "ملخص التدريب ✅" : "نتيجة الجولة",
                  style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: primaryColor)),
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                _resultDetail("النقاط", "+$_roundScore", accentColor),
                _resultDetail("الدقة",
                    "$_correctAnswersCount/$_questionsPerRound", Colors.green),
              ]),
              const SizedBox(height: 25),
              Center(
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 280),
                      child: Column(children: [
                        if (canPlayMore) ...[
                          SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _startRound(freePlay: false);
                                  },
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: accentColor,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(25))),
                                  child: FittedBox(
                                      child: Text("لعب جولة أخرى",
                                          style: GoogleFonts.cairo(
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white))))),
                          const SizedBox(height: 12),
                        ],
                        if (_isFreePlaySession) ...[
                          SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _startRound(freePlay: true);
                                  },
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: accentColor,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(25))),
                                  child: FittedBox(
                                      child: Text("جولة تدريب أخرى",
                                          style: GoogleFonts.cairo(
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white))))),
                          const SizedBox(height: 12),
                        ],
                        SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  setState(() {
                                    _gameStarted = false;
                                    _isFreePlaySession = false;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(25))),
                                child: FittedBox(
                                    child: Text("الخروج للبداية",
                                        style: GoogleFonts.cairo(
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white))))),
                      ]))),
              const SizedBox(height: 10),
              TextButton(
                  onPressed: () =>
                      Navigator.popUntil(context, (r) => r.isFirst),
                  child: Text("العودة للرئيسية",
                      style: GoogleFonts.cairo(fontWeight: FontWeight.w800))),
            ],
          ),
        );
      },
    );
  }

  Widget _resultDetail(String l, String v, Color c) => Column(children: [
        Text(l,
            style: GoogleFonts.cairo(
                fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
        Text(v,
            style: GoogleFonts.poppins(
                fontSize: 24, fontWeight: FontWeight.w900, color: c))
      ]);
  Widget _optionTile(String t, Color b, Color f) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
          color: b,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 4))
          ]),
      child: Center(
          child: Text(t,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                  fontSize: 13.5, fontWeight: FontWeight.w800, color: f))));
  Widget _pill(
          {required IconData icon,
          required String text,
          required Color color}) =>
      Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.15))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 5),
            Text(text,
                style: GoogleFonts.cairo(
                    fontSize: 11, fontWeight: FontWeight.w800))
          ]));
  Widget _counterPill(String v) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accentColor.withValues(alpha: 0.25))),
      child: Text(v,
          style: GoogleFonts.poppins(
              fontSize: 22, fontWeight: FontWeight.w800, color: accentColor)));

  Widget _questionCard({required Widget child}) => Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: primaryColor.withValues(alpha: 0.2), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 6))
          ]),
      child: child);

  Widget _animatedGlowBackground() => AnimatedBuilder(
      animation: _glowController,
      builder: (_, __) => Stack(children: [
            Container(color: const Color(0xFFFDFBF7)),
            Positioned(
                top: -90 + (55 * _glowController.value),
                left: -90 + (95 * _glowController.value),
                child: Container(
                    width: 380,
                    height: 380,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [
                          accentColor.withValues(alpha: 0.10),
                          Colors.transparent
                        ])))),
            Positioned(
                bottom: -120 + (60 * _glowController.value),
                right: -120 + (90 * _glowController.value),
                child: Container(
                    width: 420,
                    height: 420,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [
                          primaryColor.withValues(alpha: 0.10),
                          Colors.transparent
                        ]))))
          ]));
  Widget _buildEmptyState() => Scaffold(
      appBar: AppBar(
          title: Text(widget.categoryTitle),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.5),
                radius: 1.5,
                colors: [const Color(0xFF136161), primaryColor],
              ),
            ),
          ),
          centerTitle: true),
      body: Center(
          child: Text("لا توجد أسئلة حاليًا.",
              style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w900, color: primaryColor))));
  Widget _glassCard(
          {required Widget child,
          EdgeInsets padding = const EdgeInsets.all(18)}) =>
      Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.black.withValues(alpha: 0.04))),
          child: child);
}

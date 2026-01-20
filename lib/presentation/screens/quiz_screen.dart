// PATH: lib/presentation/screens/quiz_screen.dart
// STATUS: Full File – ✅ Apply requested changes ONLY:
//        1) Remove logo + sentences footer from ALL quiz/league pages (no signature/footer)
//        2) Intro: shrink "انت نجم Pro ⭐ / ملعبك يا Pro 🔥" button (NOT full width)
//        3) BottomSheet: shrink "ابدأ الجولة الآن" button (NOT full width) + keep all buttons not full width
//        4) Quiz question+answers block moved DOWN with better spacing (no other UI changes)

import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/sound_manager.dart';
import '../home/widgets/section_identity_card.dart';

class QuizScreen extends StatefulWidget {
  final String categoryTitle; // "دوري النجوم" | "دوري المحترفين"

  const QuizScreen({super.key, required this.categoryTitle});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  // ================== CONFIG ==================
  static const int _roundsPerDay = 4;
  static const int _questionsPerRound = 5;

  final Color primaryColor = AppColors.primaryDeepTeal;
  final Color accentColor = AppColors.secondaryOrange;

  bool get _isStars => widget.categoryTitle == "دوري النجوم";
  String get _badgeText => _isStars ? "FRESH" : "PRO";
  String get _badgeEmoji => _isStars ? "✨" : "🔥";
  Color get _badgeColor => _isStars ? const Color(0xFF3498DB) : accentColor;

  String get _enterButtonText => _isStars ? "انت نجم Pro ⭐" : "ملعبك يا Pro 🔥";
  int get _secondsPerQuestion => _isStars ? 25 : 15;

  // ================== STATE ==================
  List<Map<String, dynamic>> _questions = [];
  bool _isLoading = true;

  bool _gameStarted = false;
  bool _showFeedback = false;
  String? _selectedOption;

  int _currentQuestionIndex = 0;
  int _questionIndexInRound = 0;
  int _roundScore = 0;

  // progress today
  int _roundsDoneToday = 0;
  DateTime? _lastQuizDate;

  // timer
  int _timeLeft = 0;
  Timer? _timer;

  // Free play
  bool _isFreePlaySession = false;

  late AnimationController _glowController;

  // ================== LIFECYCLE ==================
  @override
  void initState() {
    super.initState();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat(reverse: true);

    _loadQuestions();
    _loadUserDailyProgress();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _glowController.dispose();
    super.dispose();
  }

  // ================== FIRESTORE ==================
  Future<void> _loadQuestions() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('quizzes')
          .where('category', isEqualTo: widget.categoryTitle)
          .get();

      _questions = snapshot.docs.map((d) => d.data()).toList();
      _questions.shuffle();
    } catch (_) {
      // ignore
    }

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

      int dailyQuestionsCount = 0;
      DateTime? last;

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;

        final dq = data['dailyQuestionsCount'];
        if (dq is int) dailyQuestionsCount = dq;

        final ts = data['lastQuizDate'];
        if (ts is Timestamp) last = ts.toDate();
      }

      final now = DateTime.now();
      final sameDay = (last != null) && _isSameDay(now, last);

      final roundsDone =
          sameDay ? (dailyQuestionsCount ~/ _questionsPerRound) : 0;

      if (mounted) {
        setState(() {
          _roundsDoneToday = roundsDone.clamp(0, _roundsPerDay);
          _lastQuizDate = last;
        });
      }
    } catch (_) {
      // ignore
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // ================== GAME FLOW ==================
  void _resetTimer() => _timeLeft = _secondsPerQuestion;

  void _startTimer() {
    _resetTimer();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        _handleAnswer(""); // وقت انتهى
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

      if (_currentQuestionIndex >= _questions.length) _currentQuestionIndex = 0;
    });

    _startTimer();
  }

  void _handleAnswer(String answer) {
    if (_showFeedback) return;
    if (_questions.isEmpty) return;

    _timer?.cancel();

    if (_currentQuestionIndex >= _questions.length) _currentQuestionIndex = 0;

    final q = _questions[_currentQuestionIndex];

    final options = (q['options'] as List?)?.cast<String>() ?? <String>[];
    final correctIndex =
        q['correctAnswer'] is int ? q['correctAnswer'] as int : -1;

    final correct = (correctIndex >= 0 && correctIndex < options.length)
        ? options[correctIndex]
        : null;

    final isCorrect = (correct != null) && (answer == correct);

    setState(() {
      _selectedOption = answer;
      _showFeedback = true;

      if (isCorrect) {
        SoundManager.playCorrect();
        _roundScore += _isStars ? 2 : 5;
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

      if (_questions.isNotEmpty && _currentQuestionIndex >= _questions.length) {
        _questions.shuffle();
        _currentQuestionIndex = 0;
      }
    });

    _startTimer();
  }

  void _advanceIndexAfterRound() {
    // ✅ يمنع تكرار آخر سؤال عند بدء جولة جديدة
    if (_questions.isEmpty) return;

    _currentQuestionIndex++;

    if (_currentQuestionIndex >= _questions.length) {
      _questions.shuffle();
      _currentQuestionIndex = 0;
    }
  }

  Future<void> _finishRound() async {
    // ✅ جهّز السؤال التالي قبل ما تفتح النتيجة (عشان الجولة الجديدة ما تبدأش بنفس آخر سؤال)
    _advanceIndexAfterRound();

    // ✅ Free Play: تدريب فقط – بدون تأثير على النقاط / الليدر بورد / الحد اليومي
    if (_isFreePlaySession) {
      _showResultSheet();
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final leagueField = _isStars ? 'starsPoints' : 'proPoints';

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'points': FieldValue.increment(_roundScore),
        leagueField: FieldValue.increment(_roundScore),
        'dailyQuestionsCount': FieldValue.increment(_questionsPerRound),
        'lastQuizDate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    setState(() {
      _roundsDoneToday = (_roundsDoneToday + 1).clamp(0, _roundsPerDay);
    });

    _showResultSheet();
  }

  // ================== UI BUILD ==================
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_questions.isEmpty) return _buildEmptyState();

    if (!_gameStarted) return _buildIntro();

    if (_currentQuestionIndex >= _questions.length) _currentQuestionIndex = 0;

    final q = _questions[_currentQuestionIndex];
    final options = (q['options'] as List?)?.cast<String>() ?? <String>[];
    final correctIndex =
        q['correctAnswer'] is int ? q['correctAnswer'] as int : -1;
    final correct = (correctIndex >= 0 && correctIndex < options.length)
        ? options[correctIndex]
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        title: Text(
          widget.categoryTitle,
          style: GoogleFonts.cairo(fontWeight: FontWeight.w900),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
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
                      // ترتيب معكوس: سؤال (يمين) - العداد (وسط) - Free Play (يسار)
                      _pill(
                        icon: Icons.quiz_outlined,
                        text: "سؤال ${_questionIndexInRound + 1}/$_questionsPerRound",
                        color: primaryColor,
                      ),
                      const SizedBox(width: 12),
                      _counterPill(_timeLeft.toString()),
                      const SizedBox(width: 12),
                      _pill(
                        icon: Icons.emoji_events_outlined,
                        text: _isFreePlaySession ? "Free Play" : "اليوم",
                        color: primaryColor,
                      ),
                    ],
                  ),
                ),

                // ✅ بلوك السؤال والإجابات (top align مع padding 24)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _questionCard(
                            child: Text(
                              (q['question'] ?? '').toString(),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.cairo(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                height: 1.6,
                                color: primaryColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    physics: const BouncingScrollPhysics(),
                    itemCount: options.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final opt = options[i];

                      Color bg = Colors.white;
                      Color fg = primaryColor;

                      if (_showFeedback && correct != null && opt == correct) {
                        bg = Colors.green;
                        fg = Colors.white;
                      }
                      if (_showFeedback &&
                          opt == _selectedOption &&
                          opt != correct) {
                        bg = Colors.red;
                        fg = Colors.white;
                      }

                      return GestureDetector(
                        onTap: () => _handleAnswer(opt),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: bg == Colors.white
                                  ? primaryColor.withValues(alpha: 0.10)
                                  : Colors.transparent,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              opt,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.cairo(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: fg,
                              ),
                            ),
                          ),
                        ),
                      );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ✅ شيلنا اللوجو والجمل من أسفل (مفيش Footer)
                const SizedBox(height: 14),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ================== INTRO ==================
  Widget _buildIntro() {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      body: Stack(
        children: [
          _animatedGlowBackground(),
          Directionality(
            textDirection: TextDirection.rtl,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                child: Transform.translate(
                  offset: const Offset(0, -32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "الدوريات",
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Stack(
                        children: [
                          SectionIdentityCard(
                            sectionKey: widget.categoryTitle,
                            icon: _isStars
                                ? Icons.auto_awesome_rounded
                                : Icons.workspace_premium,
                            title: widget.categoryTitle,
                            description: _isStars
                                ? "تثبيت الأساس… وتطوير يومي بدون ضغط."
                                : "اختبار حقيقي… يقتل الحفظ ويقوّي الفهم.",
                            benefits: _isStars
                                ? const [
                                    "مناسب للفريش",
                                    "يزود ثقتك خطوة بخطوة",
                                    "يخليك ثابت وسط ضغط السوق"
                                  ]
                                : const [
                                    "مناسب للمحترفين",
                                    "يختبر الفهم مش المعلومات",
                                    "يرفع مستوى القرار تحت الضغط"
                                  ],
                          ),
                          Positioned(
                            top: 18,
                            left: 18,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _badgeColor,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  )
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(_badgeEmoji,
                                      style: const TextStyle(fontSize: 12)),
                                  const SizedBox(width: 6),
                                  Text(
                                    _badgeText,
                                    style: GoogleFonts.cairo(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _glassCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.emoji_events_outlined,
                              color: primaryColor,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "تحدي اليوم: $_roundsDoneToday/$_roundsPerDay جوالات",
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ✅ تصغير زر "انت نجم..." (ممنوع full width)
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 320),
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () {
                                SoundManager.playTap();
                                _openDailyChallengeSheet();
                              },
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 18),
                              ),
                              child: Text(
                                _enterButtonText,
                                style: GoogleFonts.cairo(
                                    fontWeight: FontWeight.w900),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          "رجوع",
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.w800,
                            color: Colors.blueGrey,
                          ),
                        ),
                      ),

                      // ✅ شيلنا اللوجو والجمل من أسفل صفحات الدوريات
                    ],
                  ),
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
      isDismissible: true,
      builder: (_) {
        final locked = _roundsDoneToday >= _roundsPerDay;
        final currentRound = (_roundsDoneToday + 1).clamp(1, _roundsPerDay);

        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(26)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    "تحدي اليوم",
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "عدد الجوالات: $_roundsPerDay\nكل جولة: $_questionsPerRound أسئلة",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      height: 1.8,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    locked
                        ? "أنت خلصت 4 جوالات النهاردة ✅"
                        : "جولتك الحالية: $currentRound/$_roundsPerDay",
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: locked ? Colors.green : accentColor,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ✅ تصغير زر "ابدأ الجولة الآن" (ممنوع full width)
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: locked
                              ? null
                              : () {
                                  Navigator.pop(context);
                                  _startRound(freePlay: false);
                                },
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                          ),
                          child: Text(
                            locked ? "تم إنهاء تحدي اليوم" : "ابدأ الجولة الآن",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                GoogleFonts.cairo(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ✅ Free Play button (NOT full width)
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _startRound(freePlay: true);
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                                color: primaryColor.withValues(alpha: 0.25)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                          ),
                          child: Text(
                            "Free Play — تدريب بدون نقاط",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.w900,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ================== RESULT SHEET ==================
  void _showResultSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(22),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _isFreePlaySession
                  ? "Free Play ✅"
                  : "نتيجة الجولة ${_roundsDoneToday.clamp(1, _roundsPerDay)}/$_roundsPerDay",
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "حصلت على $_roundScore نقطة ⭐",
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 8),
            if (_isFreePlaySession)
              Text(
                "دي نقاط تدريب فقط — مش بتتحسب في الليدر بورد.",
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  height: 1.6,
                  fontWeight: FontWeight.w700,
                  color: Colors.black54,
                ),
              ),
            const SizedBox(height: 16),

            // ✅ Free Play: زر جولة أخرى (بدون خروج) — أصلاً مش full width
            if (_isFreePlaySession)
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 280),
                  child: SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          _showFeedback = false;
                          _selectedOption = null;
                          _questionIndexInRound = 0;
                          _roundScore = 0;
                        });
                        _startRound(freePlay: true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondaryOrange,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        "جولة أخرى (Free Play)",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          height: 1.2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            if (_isFreePlaySession) const SizedBox(height: 10),

            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: SizedBox(
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        _gameStarted = false;
                        _showFeedback = false;
                        _selectedOption = null;
                        _isFreePlaySession = false;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      "رجوع لصفحة البداية",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        height: 1.2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
              child: Text(
                "العودة للرئيسية",
                style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================== EMPTY ==================
  Widget _buildEmptyState() {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        title: Text(
          widget.categoryTitle,
          style: GoogleFonts.cairo(fontWeight: FontWeight.w900),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          _animatedGlowBackground(),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: _glassCard(
                child: Text(
                  "لا توجد أسئلة حاليًا.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    height: 1.8,
                    fontWeight: FontWeight.w900,
                    color: primaryColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================== BUILDING BLOCKS ==================
  Widget _animatedGlowBackground() {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (_, __) {
        return Stack(
          children: [
            Container(color: const Color(0xFFFDFBF7)),
            Positioned(
              top: -90 + (55 * _glowController.value),
              left: -90 + (95 * _glowController.value),
              child: Container(
                width: 380,
                height: 380,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      accentColor.withValues(alpha: 0.10),
                      accentColor.withValues(alpha: 0.00),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -120 + (60 * _glowController.value),
              right: -120 + (90 * _glowController.value),
              child: Container(
                width: 420,
                height: 420,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      primaryColor.withValues(alpha: 0.10),
                      primaryColor.withValues(alpha: 0.00),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _glassCard({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(18),
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _pill({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: GoogleFonts.cairo(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // Counter pill for timer (centered large number)
  Widget _counterPill(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Text(
        value,
        style: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: accentColor,
        ),
      ),
    );
  }

  // Question card (cleaner style)
  Widget _questionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: primaryColor.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

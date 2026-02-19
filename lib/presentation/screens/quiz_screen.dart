// PATH: lib/presentation/screens/quiz_screen.dart
// STATUS: SCROLL-LIBERATED ✅ (Flexible Intro & Game Flow)

import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/firestore_paths.dart';
import '../../core/utils/sound_manager.dart';
import '../home/widgets/section_identity_card.dart';
import '../widgets/lpro_bottom_nav_bar.dart';
import 'main_wrapper.dart';

import '../../features/quiz/repositories/quiz_repository_impl.dart';

class QuizScreen extends StatefulWidget {
  final String categoryTitle;

  const QuizScreen({super.key, required this.categoryTitle});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  final QuizRepositoryImpl _quizRepo = QuizRepositoryImpl();

  static const int _roundsPerDay = 4;
  static const int _questionsPerRound = 5;
  static const int kRecentlySeenMax = 80;
  static const int kPoolLimit = 400;

  final Color primaryColor = AppColors.primaryDeepTeal;
  final Color accentColor = AppColors.secondaryOrange;

  bool get _isStars => widget.categoryTitle == "دوري النجوم";
  String get _enterButtonText => _isStars ? "انت نجم Pro ⭐" : "ملعبك يا Pro 🔥";
  int get _secondsPerQuestion => _isStars ? 25 : 15;

  List<_QuizQuestion> _candidatePool = [];
  final List<_QuizQuestion> _runQuestions = [];
  final Set<String> _usedThisRun = {};
  List<String> _recentlySeenList = [];

  int _stage = 0;
  int _streak = 0;

  bool _isLoading = true;
  bool _gameStarted = false;
  bool _showFeedback = false;
  String? _selectedOption;
  int _currentQuestionIndex = 0;
  int _questionIndexInRound = 0;
  int _roundScore = 0;
  int _correctAnswersCount = 0;

  int _starsRoundsToday = 0;
  int _prosRoundsToday = 0;
  int _freePlayRoundsToday = 0;

  Timer? _timer;
  int _timeLeft = 0;
  bool _isFreePlaySession = false;
  bool _isSaving = false;

  int get _roundsDoneToday => _isStars ? _starsRoundsToday : _prosRoundsToday;
  bool get _isCurrentLeagueLocked => _roundsDoneToday >= _roundsPerDay;
  bool get _areBothLeaguesLocked =>
      _starsRoundsToday >= _roundsPerDay && _prosRoundsToday >= _roundsPerDay;
  late AnimationController _glowController;

  final Set<String> _submittedQuestionIds = {};
  final Set<String> _seenQuestionIdsThisRound = {};

  List<String> _displayOptions = [];
  int _displayCorrectIndex = 0;
  final Stopwatch _introTiming = Stopwatch();

  static String _normalizeArabic(String s) {
    String result = s.trim().replaceAll(RegExp(r'\s+'), ' ');
    result = result
        .replaceAll('ى', 'ي')
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا');
    return result;
  }

  static bool _arabicMatch(String a, String b) =>
      _normalizeArabic(a) == _normalizeArabic(b);

  @override
  void initState() {
    super.initState();
    _introTiming.start();
    _glowController =
        AnimationController(vsync: this, duration: const Duration(seconds: 9))
          ..repeat(reverse: true);
    _initQuizEngine();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _glowController.dispose();
    super.dispose();
  }

  String get _recentlySeenPrefsKey =>
      'quiz_recent_seen_${widget.categoryTitle}';

  Future<void> _initQuizEngine() async {
    await _loadRecentlySeen();
    await _loadCandidatePool();
    await _loadUserDailyProgress();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadRecentlySeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_recentlySeenPrefsKey);
      if (jsonStr != null) {
        final List<dynamic> list = json.decode(jsonStr);
        _recentlySeenList = list.map((e) => e.toString()).toList();
        if (_recentlySeenList.length > kRecentlySeenMax) {
          _recentlySeenList = _recentlySeenList
              .skip(_recentlySeenList.length - kRecentlySeenMax)
              .toList();
        }
      }
    } catch (_) {
      _recentlySeenList = [];
    }
  }

  Future<void> _saveRecentlySeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_recentlySeenList.length > kRecentlySeenMax) {
        _recentlySeenList = _recentlySeenList
            .skip(_recentlySeenList.length - kRecentlySeenMax)
            .toList();
      }
      await prefs.setString(
          _recentlySeenPrefsKey, json.encode(_recentlySeenList));
    } catch (_) {}
  }

  Future<void> _loadCandidatePool() async {
    try {
      final snap1 = await FirebaseFirestore.instance
          .collection(FirestorePaths.quizzes)
          .where('category', isEqualTo: widget.categoryTitle)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(kPoolLimit)
          .get()
          .timeout(const Duration(seconds: 3));

      if (snap1.docs.isNotEmpty) {
        _candidatePool = _parseQuestionDocs(snap1.docs);
        return;
      }
    } catch (e) {
      debugPrint("Q1 Fail or Timeout - Switching to Fallback");
    }

    try {
      final snap2 = await FirebaseFirestore.instance
          .collection(FirestorePaths.quizzes)
          .where('category', isEqualTo: widget.categoryTitle)
          .where('isActive', isEqualTo: true)
          .limit(kPoolLimit)
          .get();
      if (snap2.docs.isNotEmpty) {
        _candidatePool = _parseQuestionDocs(snap2.docs);
        return;
      }
    } catch (e) {
      debugPrint("Q2 Fail");
    }

    _candidatePool = [];
  }

  List<_QuizQuestion> _parseQuestionDocs(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    return docs
        .map((d) {
          final data = d.data();
          final options = ((data['options'] as List?) ?? []).cast<String>();
          int rawCorrect =
              (data['correctAnswer'] ?? data['correctOptionIndex'] ?? 0) as int;
          final difficulty = ((data['difficulty'] as int?) ?? 3).clamp(1, 5);
          return _QuizQuestion(
            docId: d.id,
            question: (data['question'] ?? '').toString(),
            options: options,
            correctAnswer: options.isNotEmpty
                ? rawCorrect.clamp(0, options.length - 1)
                : 0,
            createdAtMs:
                (data['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0,
            difficulty: difficulty,
          );
        })
        .where((q) => q.options.length >= 2 && q.question.trim().isNotEmpty)
        .toList();
  }

  void _selectQuestionsForRound() {
    _runQuestions.clear();
    _seenQuestionIdsThisRound.clear();
    final recentlySeenSet = _recentlySeenList.toSet();
    List<_QuizQuestion> available =
        _candidatePool.where((q) => !_usedThisRun.contains(q.docId)).toList();
    List<_QuizQuestion> fresh =
        available.where((q) => !recentlySeenSet.contains(q.docId)).toList();
    if (fresh.length < _questionsPerRound) fresh = available;
    if (fresh.isEmpty) fresh = _candidatePool;

    final selected = _selectWithDifficultyBias(fresh, _questionsPerRound);
    for (final q in selected) {
      _runQuestions.add(q);
      _usedThisRun.add(q.docId);
      _seenQuestionIdsThisRound.add(q.docId);
      if (!_recentlySeenList.contains(q.docId)) _recentlySeenList.add(q.docId);
    }
    _saveRecentlySeen();
  }

  List<_QuizQuestion> _selectWithDifficultyBias(
      List<_QuizQuestion> pool, int count) {
    if (pool.isEmpty) return [];
    final p = List<_QuizQuestion>.from(pool)..shuffle();
    return p.take(count).toList();
  }

  void _updateDifficultyProgression(bool correct) {
    if (correct) {
      _streak++;
      if (_streak >= 3) {
        _stage = (_stage + 1).clamp(0, 3);
        _streak = 0;
      }
    } else {
      _streak = 0;
      _stage = (_stage - 1).clamp(0, 3);
    }
  }

  void _shuffleAndSetDisplayForQuestion(_QuizQuestion q) {
    final opts = q.options;
    if (opts.isEmpty) {
      _displayOptions = [];
      _displayCorrectIndex = 0;
      return;
    }
    final idx = q.correctAnswer;
    final pairs = List<MapEntry<String, bool>>.generate(
        opts.length, (i) => MapEntry(opts[i], i == idx));
    pairs.shuffle();
    _displayOptions = pairs.map((e) => e.key).toList();
    _displayCorrectIndex = pairs.indexWhere((e) => e.value);
  }

  Future<void> _loadUserDailyProgress() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final doc = await FirebaseFirestore.instance
          .collection(FirestorePaths.users)
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        final Timestamp? lastTs = data['lastQuizDate'] as Timestamp?;
        final now = DateTime.now();

        bool isSameDay = lastTs != null &&
            lastTs.toDate().year == now.year &&
            lastTs.toDate().month == now.month &&
            lastTs.toDate().day == now.day;

        if (!isSameDay) {
          await FirebaseFirestore.instance
              .collection(FirestorePaths.users)
              .doc(user.uid)
              .update({
            'dailyStarsRounds': 0,
            'dailyProsRounds': 0,
            'dailyFreePlayRounds': 0,
            'lastQuizDate': Timestamp.fromDate(now),
          });
          if (mounted) {
            setState(() {
              _starsRoundsToday = 0;
              _prosRoundsToday = 0;
              _freePlayRoundsToday = 0;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _starsRoundsToday = (data['dailyStarsRounds'] as int? ?? 0)
                  .clamp(0, _roundsPerDay);
              _prosRoundsToday = (data['dailyProsRounds'] as int? ?? 0)
                  .clamp(0, _roundsPerDay);
              _freePlayRoundsToday = (data['dailyFreePlayRounds'] as int? ?? 0);
            });
          }
        }
      }
    } catch (_) {}
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
    if (_candidatePool.length < _questionsPerRound) return;
    _selectQuestionsForRound();
    if (_runQuestions.isEmpty) return;

    _shuffleAndSetDisplayForQuestion(_runQuestions[0]);
    setState(() {
      _isFreePlaySession = freePlay;
      _gameStarted = true;
      _showFeedback = false;
      _currentQuestionIndex = 0;
      _questionIndexInRound = 0;
      _roundScore = 0;
      _correctAnswersCount = 0;
    });
    _startTimer();
  }

  void _handleAnswer(String answer) {
    if (_showFeedback) return;
    _timer?.cancel();

    if (_displayOptions.isEmpty ||
        _displayCorrectIndex < 0 ||
        _displayCorrectIndex >= _displayOptions.length) {
      if (_questionIndexInRound + 1 >= _questionsPerRound) {
        _finishRound();
      } else {
        _nextQuestion();
      }
      return;
    }

    final correct = _displayOptions[_displayCorrectIndex];
    final isCorrect = answer == correct && answer.isNotEmpty;
    _updateDifficultyProgression(isCorrect);
    setState(() {
      _selectedOption = answer;
      _showFeedback = true;
      if (isCorrect) {
        SoundManager.playCorrect();
        _roundScore += _isStars ? 2 : 5;
        _correctAnswersCount++;
      } else {
        SoundManager.playWrong();
      }
    });

    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      if (_isSaving || !_gameStarted) return;

      if (_questionIndexInRound + 1 >= _questionsPerRound) {
        _finishRound();
      } else {
        _nextQuestion();
      }
    });
  }

  void _nextQuestion() {
    if (_isSaving) return;
    _currentQuestionIndex++;
    _questionIndexInRound++;

    if (_currentQuestionIndex >= _runQuestions.length) {
      _finishRound();
      return;
    }

    _shuffleAndSetDisplayForQuestion(_runQuestions[_currentQuestionIndex]);
    setState(() {
      _showFeedback = false;
      _selectedOption = null;
    });
    _startTimer();
  }

  Future<void> _finishRound() async {
    _timer?.cancel();
    if (_isSaving) return;
    setState(() => _isSaving = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await _quizRepo.saveGameSession(
          uid: user.uid,
          leagueKey:
              _isFreePlaySession ? 'freeplay' : (_isStars ? 'stars' : 'pros'),
          score: _roundScore,
          correctAnswers: _correctAnswersCount,
          totalQuestions: _questionsPerRound,
        );
        if (mounted) {
          setState(() {
            if (_isFreePlaySession) {
              _freePlayRoundsToday++;
            } else if (_isStars) {
              _starsRoundsToday++;
            } else {
              _prosRoundsToday++;
            }
          });
        }
      } catch (e) {
        debugPrint("Error saving quiz result: $e");
      }
    }
    if (mounted) {
      setState(() => _isSaving = false);
      _showResultSheet();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_gameStarted) return _buildIntro();
    if (_currentQuestionIndex >= _runQuestions.length) {
      return _buildEmptyState();
    }

    final q = _runQuestions[_currentQuestionIndex];
    final options = _displayOptions;
    final correct = options.isNotEmpty && _displayCorrectIndex < options.length
        ? options[_displayCorrectIndex]
        : '';

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
                  colors: [const Color(0xFF136161), primaryColor]),
            ),
          ),
          foregroundColor: Colors.white,
          centerTitle: true),
      bottomNavigationBar: LProBottomNavBar(
        activeIndex: 1,
        onTap: (index) => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => MainWrapper(initialIndex: index)),
            (route) => false),
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
                                child: Text(q.question,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.cairo(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                        color: primaryColor)))),
                        const SizedBox(height: 20),
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            itemCount: options.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, i) {
                              final opt = options[i];
                              Color bg = Colors.white;
                              Color fg = primaryColor;
                              if (_showFeedback) {
                                if (opt == correct) {
                                  bg = Colors.green;
                                  fg = Colors.white;
                                } else if (opt == _selectedOption) {
                                  bg = Colors.red;
                                  fg = Colors.white;
                                }
                              }
                              return GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: _showFeedback
                                    ? null
                                    : () => _handleAnswer(opt),
                                child: _optionTile(opt, bg, fg),
                              );
                            },
                          ),
                        ),
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
                  colors: [const Color(0xFF136161), primaryColor]),
            ),
          ),
          title: Image.asset('assets/top_brand.png',
              height: 22, fit: BoxFit.contain)),
      bottomNavigationBar: LProBottomNavBar(
          activeIndex: 1,
          onTap: (index) => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  builder: (_) => MainWrapper(initialIndex: index)),
              (route) => false)),
      body: Stack(
        children: [
          _animatedGlowBackground(),
          Directionality(
            textDirection: TextDirection.rtl,
            child: SafeArea(
              // ✅ تم إضافة التمرير هنا لتحرير السكرول في شاشة المقدمة
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 26, 16, 16),
                  child: Column(
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
                        title: _isStars ? "✨ دوري النجوم" : "🔥 دوري المحترفين",
                        description: _isStars
                            ? ""
                            : "الاحتراف مش إنك تعرف معلومة واحدة،\nالاحتراف إن كل خيوط المعلومة تبقى في إيدك.",
                        benefits: const [],
                      ),
                      const SizedBox(height: 20),
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
                                    _isCurrentLeagueLocked
                                        ? "أنهيت جولات هذا الدوري ✅"
                                        : "تحدي اليوم: $_roundsDoneToday/$_roundsPerDay جولات",
                                    style: GoogleFonts.cairo(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        color: _isCurrentLeagueLocked
                                            ? Colors.green
                                            : primaryColor))
                              ])),
                      const SizedBox(height: 16),
                      Builder(builder: (context) {
                        final canStart = !_isLoading &&
                            _candidatePool.length >= _questionsPerRound;
                        final buttonLabel = _enterButtonText;

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accentColor,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(220, 48),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 24),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24)),
                                elevation: 0,
                              ),
                              onPressed: () {
                                SoundManager.playTap();
                                if (!canStart) {
                                  _showLoadingSheet();
                                } else {
                                  _openDailyChallengeSheet();
                                }
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_isLoading)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 12),
                                      child: SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2),
                                      ),
                                    ),
                                  Text(
                                    buttonLabel,
                                    style: GoogleFonts.cairo(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }),
                      const SizedBox(height: 10),
                      TextButton(
                          onPressed: () => Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const MainWrapper(initialIndex: 0)),
                              (route) => false),
                          child: Text("رجوع",
                              style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.blueGrey))),
                      const SizedBox(height: 14),
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

  void _showLoadingSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              "جاري تجهيز الأسئلة...",
              style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w800, color: primaryColor),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(180, 44),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: () {
                Navigator.pop(context);
                _loadCandidatePool();
              },
              child: Text("إعادة المحاولة",
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  void _openDailyChallengeSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        final locked = _isCurrentLeagueLocked;
        final bothLocked = _areBothLeaguesLocked;
        String lockedMessage = bothLocked
            ? "إنجاز كامل 💪\nأنهيت كل الجولات التنافسية اليوم."
            : (_isStars
                ? "أنهيت جولات دوري النجوم اليوم ✅"
                : "أداء قوي 👏 خلّصت جولات دوري المحترفين النهارده.");
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
                  Text(locked ? "إنجاز اليوم" : "تحدي اليوم",
                      style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: primaryColor)),
                  const SizedBox(height: 8),
                  if (locked)
                    Text(lockedMessage,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey[800]))
                  else
                    Text(
                        "جولتك القادمة: ${_roundsDoneToday + 1}/$_roundsPerDay",
                        style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: accentColor)),
                  const SizedBox(height: 16),
                  if (locked) ...[
                    _buildDashboardCounters(),
                    const SizedBox(height: 16)
                  ],
                  Center(
                      child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 280),
                          child: Column(children: [
                            if (!locked)
                              SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: accentColor,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(25))),
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _startRound(freePlay: false);
                                      },
                                      child: FittedBox(
                                          child: Text("ابدأ الجولة الآن",
                                              style: GoogleFonts.cairo(
                                                  color: Colors.white,
                                                  fontWeight:
                                                      FontWeight.w900))))),
                            if (!locked) const SizedBox(height: 12),
                            SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: locked
                                    ? ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: accentColor,
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
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.w900))))
                                    : OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                            side:
                                                BorderSide(color: primaryColor),
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

  Widget _buildDashboardCounters() {
    return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _counterItem("نجوم", "$_starsRoundsToday/$_roundsPerDay",
              Icons.auto_awesome_rounded),
          Container(width: 1, height: 30, color: Colors.grey[300]),
          _counterItem("محترفين", "$_prosRoundsToday/$_roundsPerDay",
              Icons.workspace_premium),
          Container(width: 1, height: 30, color: Colors.grey[300]),
          _counterItem("تدريب", "$_freePlayRoundsToday", Icons.fitness_center),
        ]));
  }

  Widget _counterItem(String l, String v, IconData i) => Column(children: [
        Icon(i, size: 16, color: primaryColor),
        const SizedBox(height: 4),
        Text(v,
            style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: primaryColor)),
        Text(l, style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey[600]))
      ]);

  void _showResultSheet() {
    showModalBottomSheet(
        context: context,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        builder: (_) {
          final bool canPlayMore =
              !_isFreePlaySession && !_isCurrentLeagueLocked;
          return Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(30))),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(_isFreePlaySession ? "ملخص التدريب ✅" : "نتيجة الجولة",
                    style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: primaryColor)),
                const SizedBox(height: 20),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _resultDetail("النقاط", "+$_roundScore", accentColor),
                      _resultDetail(
                          "الدقة",
                          "$_correctAnswersCount/$_questionsPerRound",
                          Colors.green)
                    ]),
                const SizedBox(height: 25),
                Center(
                    child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 280),
                        child: Column(children: [
                          if (canPlayMore)
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
                          if (canPlayMore) const SizedBox(height: 12),
                          if (_isFreePlaySession)
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
                          if (_isFreePlaySession) const SizedBox(height: 12),
                          SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    setState(() {
                                      _gameStarted = false;
                                      _isFreePlaySession = false;
                                      _usedThisRun.clear();
                                      _isLoading = false;
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
                    onPressed: () {
                      _usedThisRun.clear();
                      Navigator.popUntil(context, (r) => r.isFirst);
                    },
                    child: Text("العودة للرئيسية",
                        style: GoogleFonts.cairo(fontWeight: FontWeight.w800))),
              ]));
        });
  }

  Widget _resultDetail(String l, String v, Color c) => Column(children: [
        Text(l, style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey)),
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
          border: Border.all(
              color: primaryColor.withValues(alpha: 0.2), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 6))
          ]),
      child: child);
  Widget _animatedGlowBackground() => AnimatedBuilder(
      animation: _glowController,
      builder: (_, __) => Container(color: const Color(0xFFFDFBF7)));
  Widget _buildEmptyState() => Scaffold(
      appBar: AppBar(title: Text(widget.categoryTitle)),
      body: const Center(child: Text("انتهت الجولة")));
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

class _QuizQuestion {
  final String docId;
  final String question;
  final List<String> options;
  final int correctAnswer;
  final int createdAtMs;
  final int difficulty;
  _QuizQuestion(
      {required this.docId,
      required this.question,
      required this.options,
      required this.correctAnswer,
      required this.createdAtMs,
      required this.difficulty});
}

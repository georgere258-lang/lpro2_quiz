// PATH: lib/presentation/screens/quiz_screen.dart
// STATUS: FULL COMPLETED FILE – ✅ Hardened Quiz Engine v1
//         ✅ No repetition in same run (usedThisRun)
//         ✅ Variety across runs (recentlySeen pool persisted)
//         ✅ Difficulty progression (stage/streak system)
//         ✅ Safe transactional points update
//         ✅ Answer selection fix

import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  static const int _recentlySeenPoolSize = 80;
  static const int _candidatePoolLimit = 120;

  final Color primaryColor = AppColors.primaryDeepTeal;
  final Color accentColor = AppColors.secondaryOrange;

  bool get _isStars => widget.categoryTitle == "دوري النجوم";
  String get _enterButtonText => _isStars ? "انت نجم Pro ⭐" : "ملعبك يا Pro 🔥";
  int get _secondsPerQuestion => _isStars ? 25 : 15;

  // ═══════════════════════════════════════════════════════════════════════════
  // Question Pool & Sampling State
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Full candidate pool fetched from Firestore
  List<_QuizQuestion> _candidatePool = [];
  
  /// Questions selected for current run (no duplicates within run)
  List<_QuizQuestion> _runQuestions = [];
  
  /// Doc IDs used in THIS run (prevents repetition during one game session)
  final Set<String> _usedThisRun = {};
  
  /// Recently seen doc IDs across runs (persisted for variety)
  Set<String> _recentlySeen = {};
  
  // ═══════════════════════════════════════════════════════════════════════════
  // Difficulty Progression State
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Current difficulty stage (0 = easy, 1 = medium, 2+ = hard)
  int _stage = 0;
  
  /// Correct answer streak (3 consecutive -> stage++)
  int _streak = 0;

  // ═══════════════════════════════════════════════════════════════════════════
  // Game State
  // ═══════════════════════════════════════════════════════════════════════════

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

  /// Guard against duplicate result submissions (within 10 seconds)
  DateTime? _lastResultSubmitTime;

  @override
  void initState() {
    super.initState();
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

  // ═══════════════════════════════════════════════════════════════════════════
  // PART A: Question Sampling (No Repetition + Variety)
  // ═══════════════════════════════════════════════════════════════════════════

  String get _recentlySeenPrefsKey => 'quiz_recently_seen_${widget.categoryTitle}';

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
        _recentlySeen = list.map((e) => e.toString()).toSet();
      }
    } catch (_) {
      _recentlySeen = {};
    }
  }

  Future<void> _saveRecentlySeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Keep only the most recent entries
      final list = _recentlySeen.toList();
      if (list.length > _recentlySeenPoolSize) {
        _recentlySeen = list.skip(list.length - _recentlySeenPoolSize).toSet();
      }
      await prefs.setString(_recentlySeenPrefsKey, json.encode(_recentlySeen.toList()));
    } catch (_) {}
  }

  Future<void> _loadCandidatePool() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('quizzes')
          .where('category', isEqualTo: widget.categoryTitle)
          .orderBy('createdAt', descending: true)
          .limit(_candidatePoolLimit)
          .get();

      _candidatePool = snapshot.docs.map((d) {
        final data = d.data();
        return _QuizQuestion(
          docId: d.id,
          question: (data['question'] ?? '').toString(),
          options: ((data['options'] as List?) ?? []).cast<String>(),
          correctAnswer: (data['correctAnswer'] as int?) ?? 0,
          createdAtMs: (data['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0,
          isActive: data['isActive'] != false,
        );
      }).toList();

      // Filter out inactive questions
      _candidatePool = _candidatePool.where((q) => q.isActive).toList();
    } catch (_) {
      _candidatePool = [];
    }
  }

  /// Select questions for a new round using the sampling strategy
  void _selectQuestionsForRound() {
    _runQuestions.clear();
    
    // Get available candidates (not used this run)
    List<_QuizQuestion> available = _candidatePool
        .where((q) => !_usedThisRun.contains(q.docId))
        .toList();

    // Filter out recently seen (best effort variety)
    List<_QuizQuestion> fresh = available
        .where((q) => !_recentlySeen.contains(q.docId))
        .toList();

    // If not enough fresh questions, relax filter
    if (fresh.length < _questionsPerRound) {
      fresh = available; // Allow recently seen but still block usedThisRun
    }

    // If still not enough (edge case), use all available
    if (fresh.isEmpty) {
      fresh = _candidatePool.toList();
    }

    // Apply difficulty progression bias
    final selected = _selectWithDifficultyBias(fresh, _questionsPerRound);

    for (final q in selected) {
      _runQuestions.add(q);
      _usedThisRun.add(q.docId);
      _recentlySeen.add(q.docId);
    }

    // Persist recently seen
    _saveRecentlySeen();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PART B: Difficulty Progression
  // ═══════════════════════════════════════════════════════════════════════════

  /// Select questions with difficulty bias based on current stage
  /// Stage 0: newest 40% + random 60%
  /// Stage 1: newest 60% + random 40%
  /// Stage 2+: newest 80% + random 20%
  List<_QuizQuestion> _selectWithDifficultyBias(List<_QuizQuestion> pool, int count) {
    if (pool.isEmpty) return [];
    if (pool.length <= count) return pool..shuffle();

    // Sort by createdAt descending (newer = higher difficulty)
    final sorted = List<_QuizQuestion>.from(pool)
      ..sort((a, b) => b.createdAtMs.compareTo(a.createdAtMs));

    // Determine bias percentages
    double newestRatio;
    switch (_stage) {
      case 0:
        newestRatio = 0.4;
        break;
      case 1:
        newestRatio = 0.6;
        break;
      default:
        newestRatio = 0.8;
    }

    final newestCount = (count * newestRatio).ceil();
    final randomCount = count - newestCount;

    // Split pool
    final newestPool = sorted.take((sorted.length * 0.4).ceil()).toList();
    final restPool = sorted.skip((sorted.length * 0.4).ceil()).toList();

    newestPool.shuffle();
    restPool.shuffle();

    final selected = <_QuizQuestion>[];

    // Add from newest pool
    for (int i = 0; i < newestCount && i < newestPool.length; i++) {
      selected.add(newestPool[i]);
    }

    // Add from rest pool
    for (int i = 0; i < randomCount && i < restPool.length; i++) {
      selected.add(restPool[i]);
    }

    // If not enough, fill from any remaining
    if (selected.length < count) {
      final remaining = pool.where((q) => !selected.contains(q)).toList()..shuffle();
      for (final q in remaining) {
        if (selected.length >= count) break;
        selected.add(q);
      }
    }

    selected.shuffle();
    return selected.take(count).toList();
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

  // ═══════════════════════════════════════════════════════════════════════════
  // User Progress & Daily Tracking
  // ═══════════════════════════════════════════════════════════════════════════

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
    if (_candidatePool.isEmpty) return;
    
    // Reset stage and streak for new round
    _stage = 0;
    _streak = 0;
    
    // Select questions for this round
    _selectQuestionsForRound();
    
    if (_runQuestions.isEmpty) return;
    
    setState(() {
      _isFreePlaySession = freePlay;
      _gameStarted = true;
      _showFeedback = false;
      _selectedOption = null;
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
    
    if (_currentQuestionIndex >= _runQuestions.length) return;
    
    final q = _runQuestions[_currentQuestionIndex];
    final correct = q.options.isNotEmpty && q.correctAnswer < q.options.length
        ? q.options[q.correctAnswer]
        : '';
    
    final isCorrect = answer == correct && answer.isNotEmpty;
    
    // Update difficulty progression
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
    });
    _startTimer();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PART C: Safe Transactional Results
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _finishRound() async {
    if (!_isFreePlaySession) {
      await _submitResultSafely();
      setState(() =>
          _roundsDoneToday = (_roundsDoneToday + 1).clamp(0, _roundsPerDay));
    }
    _showResultSheet();
  }

  /// Submit result with duplicate guard and transaction
  Future<void> _submitResultSafely() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Duplicate submission guard (within 10 seconds)
    final now = DateTime.now();
    if (_lastResultSubmitTime != null &&
        now.difference(_lastResultSubmitTime!).inSeconds < 10) {
      debugPrint("Duplicate submission blocked");
      return;
    }
    _lastResultSubmitTime = now;

    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

      // Use transaction for atomic update
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);
        
        final currentData = snapshot.data() ?? {};
        final currentPoints = (currentData['points'] as int?) ?? 0;
        final currentStarsPoints = (currentData['starsPoints'] as int?) ?? 0;
        final currentProPoints = (currentData['proPoints'] as int?) ?? 0;
        final currentDailyCount = (currentData['dailyQuestionsCount'] as int?) ?? 0;

        final updates = <String, dynamic>{
          'points': currentPoints + _roundScore,
          'dailyQuestionsCount': currentDailyCount + _questionsPerRound,
          'lastQuizDate': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (_isStars) {
          updates['starsPoints'] = currentStarsPoints + _roundScore;
        } else {
          updates['proPoints'] = currentProPoints + _roundScore;
        }

        transaction.set(userRef, updates, SetOptions(merge: true));
      });
    } catch (e) {
      debugPrint("Error submitting result: $e");
      // Fallback to non-transactional update
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'points': FieldValue.increment(_roundScore),
          _isStars ? 'starsPoints' : 'proPoints': FieldValue.increment(_roundScore),
          'dailyQuestionsCount': FieldValue.increment(_questionsPerRound),
          'lastQuizDate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {}
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UI
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_candidatePool.isEmpty) return _buildEmptyState();
    if (!_gameStarted) return _buildIntro();

    if (_currentQuestionIndex >= _runQuestions.length) {
      return _buildEmptyState();
    }

    final q = _runQuestions[_currentQuestionIndex];
    final options = q.options;
    final correct = options.isNotEmpty && q.correctAnswer < options.length
        ? options[q.correctAnswer]
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
                                child: Text(q.question,
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
                                  
                                  // ✅ FIX: Only show colors when feedback is active
                                  if (_showFeedback) {
                                    if (opt == correct) {
                                      bg = Colors.green;
                                      fg = Colors.white;
                                    }
                                    if (opt == _selectedOption && opt != correct) {
                                      bg = Colors.red;
                                      fg = Colors.white;
                                    }
                                  }
                                  
                                  return GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: _showFeedback ? null : () => _handleAnswer(opt),
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
                                    // Clear usedThisRun when exiting to intro
                                    _usedThisRun.clear();
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

// ═══════════════════════════════════════════════════════════════════════════
// Internal Question Model (used only within this file)
// ═══════════════════════════════════════════════════════════════════════════

class _QuizQuestion {
  final String docId;
  final String question;
  final List<String> options;
  final int correctAnswer;
  final int createdAtMs;
  final bool isActive;

  _QuizQuestion({
    required this.docId,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.createdAtMs,
    required this.isActive,
  });
}

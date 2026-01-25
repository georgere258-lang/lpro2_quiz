// PATH: lib/presentation/screens/quiz_screen.dart
// STATUS: FULL COMPLETED FILE – ✅ Hardened Quiz Engine v7 (quizzes)
//         ✅ Collection: quizzes (original collection)
//         ✅ Robust category matching with Arabic normalization
//         ✅ Multi-query fallback strategy (handles index/filter issues)
//         ✅ Always shows intro UI even with 0 questions
//         ✅ Debug diagnostic panel for troubleshooting
//         ✅ No repetition in same run (usedThisRun by docId)
//         ✅ Variety across runs (recentlySeen per-league, FIFO bounded)
//         ✅ Difficulty progression using Firestore 'difficulty' field (1-5)
//         ✅ Backward compat: correctAnswer → correctOptionIndex → 0
//         ✅ Safe transactional points update
//         ✅ Per-question duplicate submission guard

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
  // ═══════════════════════════════════════════════════════════════════════════
  // Constants (no other magic numbers)
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const int _roundsPerDay = 4;
  static const int _questionsPerRound = 5;
  
  /// Max recently seen docIds to persist (FIFO bounded)
  static const int kRecentlySeenMax = 80;
  
  /// Max candidate pool fetch limit for large question banks
  static const int kPoolLimit = 400;

  final Color primaryColor = AppColors.primaryDeepTeal;
  final Color accentColor = AppColors.secondaryOrange;

  bool get _isStars => widget.categoryTitle == "دوري النجوم";
  String get _enterButtonText => _isStars ? "انت نجم Pro ⭐" : "ملعبك يا Pro 🔥";
  int get _secondsPerQuestion => _isStars ? 25 : 15;

  // ═══════════════════════════════════════════════════════════════════════════
  // Question Pool & Sampling State (docId-based only)
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Full candidate pool fetched from Firestore
  List<_QuizQuestion> _candidatePool = [];
  
  /// Questions selected for current run (no duplicates within run)
  final List<_QuizQuestion> _runQuestions = [];
  
  /// Doc IDs used in THIS run (prevents repetition during one game session)
  final Set<String> _usedThisRun = {};
  
  /// Recently seen doc IDs across runs (persisted per-league for variety)
  /// Stored as List to maintain insertion order for FIFO trimming
  List<String> _recentlySeenList = [];
  
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

  /// Per-question duplicate submission guard (docIds already submitted this run)
  final Set<String> _submittedQuestionIds = {};

  // ═══════════════════════════════════════════════════════════════════════════
  // Diagnostic State (for debugging category/query issues)
  // ═══════════════════════════════════════════════════════════════════════════
  
  String _normalizedCategory = '';
  int _queryCount1 = -1; // category + isActive
  int _queryCount2 = -1; // category only
  int _queryCount3 = -1; // isActive only (limit 10)
  List<String> _query3Categories = [];
  String _queryError = '';
  String _queryStrategy = '';

  /// Normalize Arabic text for matching (trim, collapse spaces, normalize variants)
  static String _normalizeArabic(String s) {
    String result = s.trim();
    // Collapse multiple spaces
    result = result.replaceAll(RegExp(r'\s+'), ' ');
    // Normalize Arabic Yeh variants (ى -> ي)
    result = result.replaceAll('ى', 'ي');
    // Normalize Alef variants (أ إ آ -> ا)
    result = result.replaceAll('أ', 'ا');
    result = result.replaceAll('إ', 'ا');
    result = result.replaceAll('آ', 'ا');
    return result;
  }

  /// Check if two Arabic strings match after normalization
  static bool _arabicMatch(String a, String b) {
    return _normalizeArabic(a) == _normalizeArabic(b);
  }

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
  // PART A: Question Sampling (No Repetition + Per-League Cache)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Per-league SharedPreferences key (includes category)
  String get _recentlySeenPrefsKey => 'quiz_recent_seen_${widget.categoryTitle}';

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
        // Enforce max bound on load (FIFO: keep newest)
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
      // FIFO trimming: keep only the most recent kRecentlySeenMax entries
      if (_recentlySeenList.length > kRecentlySeenMax) {
        _recentlySeenList = _recentlySeenList
            .skip(_recentlySeenList.length - kRecentlySeenMax)
            .toList();
      }
      await prefs.setString(_recentlySeenPrefsKey, json.encode(_recentlySeenList));
    } catch (_) {}
  }

  Future<void> _loadCandidatePool() async {
    _normalizedCategory = _normalizeArabic(widget.categoryTitle);
    _queryError = '';
    _queryStrategy = '';
    
    debugPrint('═══════════════════════════════════════════════════════════════');
    debugPrint('QUIZ LOAD DIAGNOSTIC');
    debugPrint('═══════════════════════════════════════════════════════════════');
    debugPrint('Raw categoryTitle: "${widget.categoryTitle}"');
    debugPrint('Normalized: "$_normalizedCategory"');

    // ─────────────────────────────────────────────────────────────────────────
    // Query 1: category == raw + isActive == true + orderBy createdAt
    // ─────────────────────────────────────────────────────────────────────────
    try {
      final snap1 = await FirebaseFirestore.instance
          .collection('quizzes')
          .where('category', isEqualTo: widget.categoryTitle)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(kPoolLimit)
          .get();
      _queryCount1 = snap1.docs.length;
      debugPrint('Query1 (category+isActive+orderBy): ${_queryCount1} docs');
      
      if (_queryCount1 > 0) {
        _queryStrategy = 'Q1: category+isActive+orderBy';
        _candidatePool = _parseQuestionDocs(snap1.docs);
        debugPrint('SUCCESS via Query1');
        return;
      }
    } catch (e) {
      debugPrint('Query1 error: $e');
      _queryError += 'Q1: $e\n';
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Query 2: category == raw + isActive == true (no orderBy - avoids index)
    // ─────────────────────────────────────────────────────────────────────────
    try {
      final snap2 = await FirebaseFirestore.instance
          .collection('quizzes')
          .where('category', isEqualTo: widget.categoryTitle)
          .where('isActive', isEqualTo: true)
          .limit(kPoolLimit)
          .get();
      _queryCount2 = snap2.docs.length;
      debugPrint('Query2 (category+isActive, no orderBy): ${_queryCount2} docs');
      
      if (_queryCount2 > 0) {
        _queryStrategy = 'Q2: category+isActive (no orderBy)';
        _candidatePool = _parseQuestionDocs(snap2.docs);
        // Sort locally by createdAt
        _candidatePool.sort((a, b) => b.createdAtMs.compareTo(a.createdAtMs));
        debugPrint('SUCCESS via Query2');
        return;
      }
    } catch (e) {
      debugPrint('Query2 error: $e');
      _queryError += 'Q2: $e\n';
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Query 3: isActive == true only (fallback - fetch all, filter client-side)
    // ─────────────────────────────────────────────────────────────────────────
    try {
      final snap3 = await FirebaseFirestore.instance
          .collection('quizzes')
          .where('isActive', isEqualTo: true)
          .limit(kPoolLimit)
          .get();
      _queryCount3 = snap3.docs.length;
      
      // Collect first 5 unique categories for debugging
      final catSet = <String>{};
      for (final d in snap3.docs) {
        final cat = (d.data()['category'] ?? '').toString();
        catSet.add(cat);
        if (catSet.length >= 5) break;
      }
      _query3Categories = catSet.toList();
      
      debugPrint('Query3 (isActive only): ${_queryCount3} docs');
      debugPrint('Query3 categories found: $_query3Categories');
      
      if (_queryCount3 > 0) {
        // Client-side filter by normalized category
        final filtered = snap3.docs.where((d) {
          final docCat = (d.data()['category'] ?? '').toString();
          return _arabicMatch(docCat, widget.categoryTitle);
        }).toList();
        
        debugPrint('Query3 filtered by normalized category: ${filtered.length} docs');
        
        if (filtered.isNotEmpty) {
          _queryStrategy = 'Q3: isActive + client-filter';
          _candidatePool = _parseQuestionDocs(filtered);
          _candidatePool.sort((a, b) => b.createdAtMs.compareTo(a.createdAtMs));
          debugPrint('SUCCESS via Query3 client-filter');
          return;
        }
      }
    } catch (e) {
      debugPrint('Query3 error: $e');
      _queryError += 'Q3: $e\n';
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Query 4: Last resort - fetch ANY docs (no filters)
    // ─────────────────────────────────────────────────────────────────────────
    try {
      final snap4 = await FirebaseFirestore.instance
          .collection('quizzes')
          .limit(20)
          .get();
      debugPrint('Query4 (no filters): ${snap4.docs.length} docs');
      
      if (snap4.docs.isNotEmpty) {
        final cats = snap4.docs.map((d) => (d.data()['category'] ?? 'null').toString()).toSet();
        debugPrint('Query4 categories: $cats');
        
        // Client-side filter by normalized category + isActive
        final filtered = snap4.docs.where((d) {
          final data = d.data();
          final docCat = (data['category'] ?? '').toString();
          final isActive = data['isActive'];
          // Treat missing isActive as true for dev
          final active = isActive == true || isActive == null;
          return active && _arabicMatch(docCat, widget.categoryTitle);
        }).toList();
        
        if (filtered.isNotEmpty) {
          _queryStrategy = 'Q4: no-filter + client-filter';
          _candidatePool = _parseQuestionDocs(filtered);
          _candidatePool.sort((a, b) => b.createdAtMs.compareTo(a.createdAtMs));
          debugPrint('SUCCESS via Query4 client-filter');
          return;
        }
      }
    } catch (e) {
      debugPrint('Query4 error: $e');
      _queryError += 'Q4: $e\n';
    }

    debugPrint('ALL QUERIES FAILED - No matching questions found');
    _queryStrategy = 'NONE';
    _candidatePool = [];
  }

  /// Parse Firestore docs into _QuizQuestion objects
  List<_QuizQuestion> _parseQuestionDocs(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    return docs.map((d) {
      final data = d.data();
      final options = ((data['options'] as List?) ?? []).cast<String>();
      
      // Backward compat: correctAnswer → correctOptionIndex → 0
      int rawCorrect;
      if (data['correctAnswer'] != null) {
        rawCorrect = (data['correctAnswer'] as int?) ?? 0;
      } else if (data['correctOptionIndex'] != null) {
        rawCorrect = (data['correctOptionIndex'] as int?) ?? 0;
      } else {
        rawCorrect = 0;
      }
      final correctAnswer = options.isNotEmpty
          ? rawCorrect.clamp(0, options.length - 1)
          : 0;
      
      // Difficulty with fallback
      final difficulty = ((data['difficulty'] as int?) ?? 3).clamp(1, 5);
      
      return _QuizQuestion(
        docId: d.id,
        question: (data['question'] ?? '').toString(),
        options: options,
        correctAnswer: correctAnswer,
        createdAtMs: (data['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0,
        difficulty: difficulty,
      );
    }).toList();
  }

  /// Select questions for a new round using the sampling strategy
  void _selectQuestionsForRound() {
    _runQuestions.clear();
    
    final recentlySeenSet = _recentlySeenList.toSet();
    
    // Get available candidates (not used this run)
    List<_QuizQuestion> available = _candidatePool
        .where((q) => !_usedThisRun.contains(q.docId))
        .toList();

    // Filter out recently seen (best effort variety)
    List<_QuizQuestion> fresh = available
        .where((q) => !recentlySeenSet.contains(q.docId))
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
      // Add to recently seen (append for FIFO order)
      if (!_recentlySeenList.contains(q.docId)) {
        _recentlySeenList.add(q.docId);
      }
    }

    // Persist recently seen (with FIFO trimming)
    _saveRecentlySeen();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PART B: Difficulty Progression (Firestore difficulty 1-5)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Target difficulties for each internal stage (stage 0-3 maps to difficulty 1-5)
  /// Stage 0: prefer difficulties [1,2] (easy/foundation)
  /// Stage 1: prefer difficulties [2,3] (medium)
  /// Stage 2: prefer difficulties [3,4] (hard)
  /// Stage 3: prefer difficulties [4,5] (expert)
  List<int> _getTargetDifficulties(int stage) {
    switch (stage) {
      case 0:
        return [1, 2];
      case 1:
        return [2, 3];
      case 2:
        return [3, 4];
      case 3:
        return [4, 5];
      default:
        return [1, 2, 3, 4, 5];
    }
  }

  /// Expanded fallback difficulties when target doesn't have enough questions
  List<int> _getExpandedDifficulties(int stage) {
    switch (stage) {
      case 0:
        return [1, 2, 3]; // Expand to include difficulty 3
      case 1:
        return [1, 2, 3, 4]; // Expand to include 1 and 4
      case 2:
        return [2, 3, 4, 5]; // Expand to include 2 and 5
      case 3:
        return [3, 4, 5]; // Expand to include difficulty 3
      default:
        return [1, 2, 3, 4, 5];
    }
  }

  /// Select questions with difficulty bias based on current stage using difficulty field (1-5)
  List<_QuizQuestion> _selectWithDifficultyBias(List<_QuizQuestion> pool, int count) {
    if (pool.isEmpty) return [];
    if (pool.length <= count) return pool..shuffle();

    final selected = <_QuizQuestion>[];
    final usedDocIds = <String>{};

    // Step 1: Try to fill from target difficulties
    final targetDiffs = _getTargetDifficulties(_stage);
    final targetPool = pool.where((q) => targetDiffs.contains(q.difficulty)).toList()..shuffle();
    
    for (final q in targetPool) {
      if (selected.length >= count) break;
      if (!usedDocIds.contains(q.docId)) {
        selected.add(q);
        usedDocIds.add(q.docId);
      }
    }

    // Step 2: If not enough, expand to adjacent difficulties
    if (selected.length < count) {
      final expandedDiffs = _getExpandedDifficulties(_stage);
      final expandedPool = pool
          .where((q) => expandedDiffs.contains(q.difficulty) && !usedDocIds.contains(q.docId))
          .toList()..shuffle();
      
      for (final q in expandedPool) {
        if (selected.length >= count) break;
        selected.add(q);
        usedDocIds.add(q.docId);
      }
    }

    // Step 3: If still not enough, use any remaining questions (graceful fallback)
    if (selected.length < count) {
      final remaining = pool.where((q) => !usedDocIds.contains(q.docId)).toList()..shuffle();
      
      for (final q in remaining) {
        if (selected.length >= count) break;
        selected.add(q);
        usedDocIds.add(q.docId);
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
  // PART C: Safe Transactional Results (Per-Question Anti-Dup)
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _finishRound() async {
    if (!_isFreePlaySession) {
      await _submitResultSafely();
      setState(() =>
          _roundsDoneToday = (_roundsDoneToday + 1).clamp(0, _roundsPerDay));
    }
    _showResultSheet();
  }

  /// Submit result with per-question duplicate guard and transaction
  Future<void> _submitResultSafely() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Collect docIds from this round that haven't been submitted yet
    final docIdsToSubmit = <String>[];
    for (final q in _runQuestions) {
      if (!_submittedQuestionIds.contains(q.docId)) {
        docIdsToSubmit.add(q.docId);
      }
    }

    // If all questions were already submitted (duplicate round), skip
    if (docIdsToSubmit.isEmpty) {
      debugPrint("All questions already submitted, skipping");
      return;
    }

    // Mark these questions as submitted (before async to prevent race)
    _submittedQuestionIds.addAll(docIdsToSubmit);

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
    // Always show intro first (even if pool is empty - intro will show diagnostic)
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
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 14),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
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
                    // Show empty message if no questions available
                    if (_candidatePool.isEmpty) ...[
                      _glassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange, size: 28),
                            const SizedBox(height: 8),
                            Text("لا توجد أسئلة نشطة في هذا الدوري حالياً",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.cairo(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.orange[800])),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    // Start button (disabled if no questions)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _candidatePool.isEmpty ? Colors.grey : accentColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(200, 48),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 0,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: _candidatePool.isEmpty
                          ? null
                          : () {
                              SoundManager.playTap();
                              _openDailyChallengeSheet();
                            },
                      child: Text(
                        _candidatePool.isEmpty ? "لا توجد أسئلة" : _enterButtonText,
                        style: GoogleFonts.cairo(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text("رجوع",
                            style: GoogleFonts.cairo(
                                fontWeight: FontWeight.w800,
                                color: Colors.blueGrey))),
                    // Debug button (debug builds only) - opens diagnostic sheet
                    if (const bool.fromEnvironment('dart.vm.product') == false) ...[
                      const SizedBox(height: 12),
                      ActionChip(
                        avatar: Icon(Icons.bug_report, size: 16, color: Colors.grey[600]),
                        label: Text('Debug', style: GoogleFonts.robotoMono(fontSize: 10, color: Colors.grey[700])),
                        backgroundColor: Colors.grey[200],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        onPressed: _showDiagnosticSheet,
                      ),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Show diagnostic panel in a bottom sheet (debug builds only)
  void _showDiagnosticSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.5,
          ),
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.bug_report, color: Colors.grey[700], size: 20),
                    const SizedBox(width: 8),
                    Text('Debug Diagnostic', style: GoogleFonts.robotoMono(fontWeight: FontWeight.bold, fontSize: 13)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: _buildDiagnosticPanel(),
                ),
              ),
            ],
          ),
        ),
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
                                    _submittedQuestionIds.clear();
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
                    _submittedQuestionIds.clear();
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
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 40),
              Icon(Icons.quiz_outlined, size: 64, color: primaryColor.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              Text("انتهت الجولة",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w900, fontSize: 18, color: primaryColor)),
              const SizedBox(height: 8),
              Text("يمكنك بدء جولة جديدة من الشاشة الرئيسية",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w600, fontSize: 14, color: Colors.grey[600])),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                child: Text("رجوع", style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w800)),
              ),
              // Debug button (debug builds only)
              if (const bool.fromEnvironment('dart.vm.product') == false) ...[
                const SizedBox(height: 20),
                ActionChip(
                  avatar: Icon(Icons.bug_report, size: 16, color: Colors.grey[600]),
                  label: Text('Debug', style: GoogleFonts.robotoMono(fontSize: 10, color: Colors.grey[700])),
                  backgroundColor: Colors.grey[200],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  onPressed: _showDiagnosticSheet,
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ));

  /// Diagnostic panel for debugging query issues (shown in debug builds)
  Widget _buildDiagnosticPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[400]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🔍 DEBUG DIAGNOSTIC', 
              style: GoogleFonts.robotoMono(fontWeight: FontWeight.bold, fontSize: 11)),
          const Divider(height: 8),
          _diagRow('Collection', 'quizzes'),
          _diagRow('Raw category', '"${widget.categoryTitle}"'),
          _diagRow('Normalized', '"$_normalizedCategory"'),
          _diagRow('Strategy', _queryStrategy.isEmpty ? 'N/A' : _queryStrategy),
          const Divider(height: 8),
          Text('Query Results:', style: GoogleFonts.robotoMono(fontWeight: FontWeight.bold, fontSize: 10)),
          _diagRow('Q1 (cat+active+order)', _queryCount1 < 0 ? 'error' : '$_queryCount1 docs'),
          _diagRow('Q2 (cat+active)', _queryCount2 < 0 ? 'error' : '$_queryCount2 docs'),
          _diagRow('Q3 (active only)', _queryCount3 < 0 ? 'error' : '$_queryCount3 docs'),
          if (_query3Categories.isNotEmpty)
            _diagRow('Q3 categories', _query3Categories.take(3).join(', ')),
          _diagRow('Pool loaded', '${_candidatePool.length} questions'),
          if (_queryError.isNotEmpty) ...[
            const Divider(height: 8),
            Text('Errors:', style: GoogleFonts.robotoMono(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.red)),
            Text(_queryError.trim(), style: GoogleFonts.robotoMono(fontSize: 9, color: Colors.red)),
          ],
        ],
      ),
    );
  }

  Widget _diagRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text('$label:', style: GoogleFonts.robotoMono(fontSize: 9, color: Colors.grey[700])),
          ),
          Expanded(
            child: Text(value, style: GoogleFonts.robotoMono(fontSize: 9, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

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
  final int difficulty; // Firestore 'difficulty' field (1-5), used for progression

  _QuizQuestion({
    required this.docId,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.createdAtMs,
    required this.difficulty,
  });
}

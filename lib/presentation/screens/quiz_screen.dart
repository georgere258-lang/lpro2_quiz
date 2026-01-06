import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:confetti/confetti.dart';
import 'dart:async';

import '../../core/constants/app_colors.dart';
import '../../core/utils/sound_manager.dart';

class QuizScreen extends StatefulWidget {
  final String categoryTitle;

  const QuizScreen({
    super.key,
    required this.categoryTitle,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final Color deepTeal = AppColors.primaryDeepTeal;
  final Color safetyOrange = AppColors.secondaryOrange;
  final Color lightTurquoise = const Color(0xFFE0F7F9);

  int currentQuestionIndex = 0;
  int batchCount = 0;
  int roundNumber = 1;
  int score = 0;
  int dailyQuestionsAnswered = 0;

  late int timeLeft;
  Timer? timer;
  bool gameStarted = false;
  String? selectedOption;
  bool showFeedback = false;
  bool isLoading = true;

  List<Map<String, dynamic>> dataItems = [];
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    timeLeft = (widget.categoryTitle == "دوري المحترفين") ? 15 : 25;
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _fetchDailyProgress();
    await _fetchContent();
  }

  Future<void> _fetchDailyProgress() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;
        Timestamp? lastDate = data['lastQuizDate'];
        DateTime now = DateTime.now();

        if (lastDate != null) {
          DateTime lastDateTime = lastDate.toDate();
          bool isSameDay = lastDateTime.year == now.year &&
              lastDateTime.month == now.month &&
              lastDateTime.day == now.day;

          if (isSameDay) {
            setState(() {
              dailyQuestionsAnswered = data['dailyQuestionsCount'] ?? 0;
              roundNumber = (dailyQuestionsAnswered ~/ 5) + 1;
              if (roundNumber > 4) roundNumber = 4;
            });
          } else {
            // تصفير عداد اليوم فقط مع بداية يوم جديد دون المساس بالنقاط
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .update({'dailyQuestionsCount': 0});
          }
        }
      }
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _fetchContent() async {
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('quizzes')
          .where('category', isEqualTo: widget.categoryTitle)
          .get();

      if (mounted) {
        setState(() {
          dataItems = snapshot.docs.map((doc) {
            var data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
          dataItems.shuffle();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _startTimer() {
    setState(
        () => timeLeft = (widget.categoryTitle == "دوري المحترفين") ? 15 : 25);
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) {
        if (timeLeft > 0) {
          setState(() => timeLeft--);
        } else {
          _handleAnswer("");
        }
      }
    });
  }

  void _handleAnswer(String selected) {
    if (showFeedback) return;
    timer?.cancel();

    var currentQ = dataItems[currentQuestionIndex];
    bool isCorrect = _normalize(selected) ==
        _normalize(currentQ['options'][currentQ['correctAnswer']]);

    if (mounted) {
      setState(() {
        selectedOption = selected;
        showFeedback = true;
        batchCount++;
        if (isCorrect) {
          SoundManager.playCorrect();
          // نظام نقاط موحد: دوري النجوم (2) | دوري المحترفين (5)
          score += (widget.categoryTitle == "دوري النجوم") ? 2 : 5;
        } else {
          SoundManager.playWrong();
        }
      });
    }

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      if (batchCount >= 5) {
        _saveProgressAndShowRound();
      } else {
        _nextStep();
      }
    });
  }

  void _nextStep() {
    if (currentQuestionIndex < dataItems.length - 1) {
      if (mounted) {
        setState(() {
          currentQuestionIndex++;
          showFeedback = false;
          selectedOption = null;
        });
        _startTimer();
      }
    } else {
      Navigator.popUntil(context, (r) => r.isFirst);
    }
  }

  // --- دالة الربط السحري بفايربيز ---
  Future<void> _saveProgressAndShowRound() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // تحديد حقل الدوري بدقة لضمان ظهورها في البروفايل
      String leagueField =
          (widget.categoryTitle == "دوري النجوم") ? 'starsPoints' : 'proPoints';

      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          // 1. زيادة المجموع العام (للهوم والترتيب العام)
          'points': FieldValue.increment(score),
          // 2. زيادة نقاط الدوري الخاص (للقسم المخصص في البروفايل)
          leagueField: FieldValue.increment(score),
          // 3. تحديث النشاط اليومي
          'dailyQuestionsCount': FieldValue.increment(5),
          'lastQuizDate': FieldValue.serverTimestamp(),
        });

        dailyQuestionsAnswered += 5;
        if (dailyQuestionsAnswered >= 20) {
          _confettiController.play();
        }
        _showRoundResultPage();
      } catch (e) {
        debugPrint("Error in DB Sync: $e");
      }
    }
  }

  void _showRoundResultPage() {
    timer?.cancel();
    int roundEarnedPoints = score;
    setState(() => score = 0); // تصفير عداد الجولة الحالية فقط

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => Stack(
        alignment: Alignment.topCenter,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: lightTurquoise,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: safetyOrange.withOpacity(0.1),
                          offset: const Offset(3, 3),
                          blurRadius: 0)
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.stars_rounded, color: safetyOrange, size: 28),
                      const SizedBox(width: 10),
                      Text("كسبت $roundEarnedPoints نقطة في الجولة",
                          style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: deepTeal)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text("عاش يا Pro! خلصت الجولة $roundNumber 🏆",
                    style: GoogleFonts.cairo(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: deepTeal)),
                const SizedBox(height: 10),
                Text(
                    roundNumber < 4
                        ? "باقي لك ${4 - roundNumber} جولات لتقفيل تارجت اليوم"
                        : "مبروك! قفلت تارجت الـ 20 سؤال لليوم بنجاح 🌟",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                        fontSize: 14, color: Colors.grey[600])),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: deepTeal,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                        ),
                        onPressed: () {
                          SoundManager.playTap();
                          Navigator.pop(context);
                          setState(() {
                            roundNumber++;
                            batchCount = 0;
                            showFeedback = false;
                            selectedOption = null;
                            currentQuestionIndex++;
                          });
                          _startTimer();
                        },
                        child: Text(
                            roundNumber < 4
                                ? "جولة تانية 🚀"
                                : "جولة إضافية 🔥",
                            style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          side: BorderSide(color: deepTeal),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                        ),
                        onPressed: () {
                          SoundManager.playTap();
                          Navigator.popUntil(context, (r) => r.isFirst);
                        },
                        child: Text("الرئيسية",
                            style: GoogleFonts.cairo(
                                color: deepTeal, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
              ],
            ),
          ),
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (dataItems.isEmpty)
      return Scaffold(
          appBar: _buildUnifiedHeader(),
          body: const Center(child: Text("لا يوجد أسئلة حالياً")));
    if (!gameStarted) return _buildStartView();

    var q = dataItems[currentQuestionIndex];
    return Scaffold(
      backgroundColor: lightTurquoise,
      appBar: _buildUnifiedHeader(),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            LinearProgressIndicator(
                value: timeLeft /
                    ((widget.categoryTitle == "دوري المحترفين") ? 15 : 25),
                color: safetyOrange,
                backgroundColor: Colors.white,
                minHeight: 6),
            Padding(
                padding: const EdgeInsets.all(15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                                color: safetyOrange.withOpacity(0.2),
                                offset: const Offset(2, 2))
                          ]),
                      child: Text("جولة $roundNumber من 4",
                          style: GoogleFonts.cairo(
                              fontWeight: FontWeight.w900,
                              color: deepTeal,
                              fontSize: 13)),
                    ),
                    Text("سؤال $batchCount من 5",
                        style: GoogleFonts.cairo(
                            fontWeight: FontWeight.bold, color: deepTeal)),
                  ],
                )),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Column(
                  children: [
                    if (q['imageUrl'] != null && q['imageUrl'] != "")
                      ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: CachedNetworkImage(
                              imageUrl: q['imageUrl'],
                              height: 160,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              memCacheHeight: 400)),
                    const SizedBox(height: 20),
                    _buildQuestionCard(q['question']),
                    const SizedBox(height: 30),
                    ...List.generate(
                        q['options'].length,
                        (i) => _buildOptionItem(
                            q['options'][i], q['correctAnswer'])),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionItem(String opt, int correctIdx) {
    var currentQ = dataItems[currentQuestionIndex];
    bool isCorrect = showFeedback && opt == currentQ['options'][correctIdx];
    bool isWrong = showFeedback &&
        opt == selectedOption &&
        opt != currentQ['options'][correctIdx];
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
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
            ]),
        child: Center(
            child: Text(opt,
                style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    color: (isCorrect || isWrong) ? Colors.white : deepTeal))),
      ),
    );
  }

  PreferredSizeWidget _buildUnifiedHeader() => AppBar(
      backgroundColor: deepTeal,
      centerTitle: true,
      elevation: 0,
      title: Text(widget.categoryTitle,
          style: GoogleFonts.cairo(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)));

  Widget _buildStartView() {
    bool isStar = widget.categoryTitle == "دوري النجوم";
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [deepTeal, deepTeal.withOpacity(0.85)])),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(isStar ? "دوري النجوم" : "دوري المحترفين",
                style: GoogleFonts.cairo(
                    fontSize: 35,
                    fontWeight: FontWeight.w900,
                    color: Colors.white)),
            const SizedBox(height: 40),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: safetyOrange,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 60, vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15))),
                onPressed: () {
                  SoundManager.playTap();
                  setState(() => gameStarted = true);
                  _startTimer();
                },
                child: Text(isStar ? "يلا يا نجم ✨" : "يلا يا Pro 🔥",
                    style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18))),
          ],
        ),
      ),
    );
  }

  String _normalize(String text) => text.trim().toLowerCase();
  Widget _buildQuestionCard(String text) => Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(25)),
      child: Text(text,
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(
              fontSize: 17, fontWeight: FontWeight.bold, color: deepTeal)));
}

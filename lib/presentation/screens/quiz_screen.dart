import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:confetti/confetti.dart'; // إضافة مكتبة الاحتفال
import 'dart:async';
import 'dart:math';

import '../../core/constants/app_colors.dart';
import '../../core/utils/sound_manager.dart'; // المسار الصحيح لمدير الصوت

class QuizScreen extends StatefulWidget {
  final String categoryTitle;
  final bool isTopicMode;

  const QuizScreen({
    super.key,
    required this.categoryTitle,
    this.isTopicMode = false,
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
  int totalSessionScore = 0;
  int dailyQuestionsAnswered = 0;

  late int timeLeft;
  Timer? timer;
  bool gameStarted = false;
  String? selectedOption;
  bool showFeedback = false;
  bool isLoading = true;

  List<Map<String, dynamic>> dataItems = [];

  // متحكم الاحتفال
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

        if (lastDate != null) {
          DateTime lastDateTime = lastDate.toDate();
          DateTime now = DateTime.now();
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

  bool get isEducationalOnly =>
      widget.categoryTitle == "المعلومة بتفرق" || widget.isTopicMode;

  Future<void> _fetchContent() async {
    try {
      String collectionName = widget.isTopicMode ? 'topics' : 'quizzes';
      var snapshot = await FirebaseFirestore.instance
          .collection(collectionName)
          .where('category', isEqualTo: widget.categoryTitle)
          .get();

      if (mounted) {
        setState(() {
          dataItems = snapshot.docs.map((doc) {
            var data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
          if (!isEducationalOnly) dataItems.shuffle();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _startTimer() {
    if (isEducationalOnly) return;
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
        if (isCorrect && !isEducationalOnly) {
          SoundManager.playCorrect(); // تشغيل صوت النجاح
          int pointsToAdd = (widget.categoryTitle == "دوري النجوم") ? 2 : 5;
          score += pointsToAdd;
          totalSessionScore += pointsToAdd;
        } else if (!isCorrect && !isEducationalOnly) {
          SoundManager.playWrong(); // تشغيل صوت الخطأ
        }
      });
    }

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      if (!isEducationalOnly && batchCount >= 5) {
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
      isEducationalOnly ? Navigator.pop(context) : _showFinalTotalResult();
    }
  }

  Future<void> _saveProgressAndShowRound() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !isEducationalOnly) {
      String pointsField =
          (widget.categoryTitle == "دوري النجوم") ? 'starsPoints' : 'proPoints';
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'points': FieldValue.increment(score),
          pointsField: FieldValue.increment(score),
          'dailyQuestionsCount': FieldValue.increment(5),
          'lastQuizDate': FieldValue.serverTimestamp(),
        });

        dailyQuestionsAnswered += 5;

        // إذا أكمل الـ 4 جولات (20 سؤال) نقوم بتشغيل الاحتفال
        if (dailyQuestionsAnswered >= 20) {
          _confettiController.play();
        }

        _showRoundResultPage();
      } catch (e) {
        debugPrint("Error saving: $e");
      }
    }
  }

  void _showRoundResultPage() {
    timer?.cancel();
    int roundEarnedPoints = score;
    setState(() => score = 0);

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
          // عرض القصاصات الملونة
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

  void _showFinalTotalResult() {
    Navigator.popUntil(context, (r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (dataItems.isEmpty) {
      return Scaffold(
          appBar: _buildUnifiedHeader(),
          body: const Center(child: Text("لا يوجد محتوى حالياً")));
    }
    if (isEducationalOnly) return _buildAttractiveTopicView();
    if (!gameStarted) return _buildStartView();

    var q = dataItems[currentQuestionIndex];
    return Scaffold(
      backgroundColor: lightTurquoise,
      appBar: _buildUnifiedHeader(),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            if (!isEducationalOnly)
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
                              fit: BoxFit.cover)),
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

  Widget _buildAttractiveTopicView() {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: _buildUnifiedHeader(),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: dataItems.length,
          itemBuilder: (context, index) =>
              _buildAttractiveTopicCard(dataItems[index]),
        ),
      ),
    );
  }

  Widget _buildAttractiveTopicCard(Map<String, dynamic> data) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        SoundManager.playTap();
        Navigator.push(context,
            MaterialPageRoute(builder: (c) => QuizTopicDetailPage(data: data)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 20,
                offset: const Offset(0, 10))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (data['imageUrl'] != null && data['imageUrl'] != "")
              ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                  child: CachedNetworkImage(
                      imageUrl: data['imageUrl'],
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover)),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color: safetyOrange.withOpacity(0.25),
                              offset: const Offset(3, 3),
                              blurRadius: 0)
                        ],
                        border: Border.all(color: deepTeal.withOpacity(0.05))),
                    child: Text(data['title'] ?? "",
                        style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: deepTeal)),
                  ),
                  const SizedBox(height: 15),
                  Text(data['content'] ?? "",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                          fontSize: 13.5,
                          color: Colors.grey[600],
                          height: 1.6)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                            color: deepTeal,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                  color: deepTeal.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4))
                            ]),
                        child: Row(
                          children: [
                            Text("اقرأ المعلومة",
                                style: GoogleFonts.cairo(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800)),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_back_rounded,
                                size: 16, color: Colors.white),
                          ],
                        ),
                      ),
                      Icon(Icons.lightbulb_outline_rounded,
                          color: safetyOrange.withOpacity(0.5), size: 22),
                    ],
                  ),
                ],
              ),
            ),
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

// عارض تفاصيل الموضوع الفني
class QuizTopicDetailPage extends StatelessWidget {
  final Map<String, dynamic> data;
  const QuizTopicDetailPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFB),
      appBar: AppBar(
          backgroundColor: AppColors.primaryDeepTeal,
          elevation: 0,
          centerTitle: true,
          title: Text(data['title'] ?? "التفاصيل",
              style: GoogleFonts.cairo(
                  fontSize: 16, fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (data['imageUrl'] != null && data['imageUrl'] != "")
                CachedNetworkImage(
                    imageUrl: data['imageUrl'],
                    width: double.infinity,
                    height: 220,
                    fit: BoxFit.cover),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 8))
                    ],
                    border: Border.all(
                        color: AppColors.primaryDeepTeal.withOpacity(0.1),
                        width: 1.2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 12),
                          decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                  colors: [
                                AppColors.primaryDeepTeal,
                                Color(0xFF006D77)
                              ],
                                  begin: Alignment.centerRight,
                                  end: Alignment.centerLeft)),
                          child: Row(
                            children: [
                              const Icon(Icons.auto_stories_rounded,
                                  color: AppColors.secondaryOrange, size: 22),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: Text(data['title'] ?? "المحتوى الفني",
                                      style: GoogleFonts.cairo(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 14),
                                      overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(22),
                          color: Colors.white,
                          child: Text(data['content'] ?? "",
                              textAlign: TextAlign.right,
                              style: GoogleFonts.cairo(
                                  fontSize: 16,
                                  height: 1.8,
                                  color: const Color(0xFF2D3142),
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

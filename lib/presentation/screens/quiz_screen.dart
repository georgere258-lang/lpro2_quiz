import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import 'dart:math';

import '../../core/constants/app_colors.dart';

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
  int score = 0;
  late int timeLeft;
  Timer? timer;
  bool gameStarted = false;
  String? selectedOption;
  bool showFeedback = false;
  bool isLoading = true;
  bool isSaving = false;

  List<Map<String, dynamic>> dataItems = [];

  final List<String> starMessages = [
    "الاستمرار هو السر، كل معلومة بتعرفها النهاردة هي طوبة في صرح نجاحك بكرة 🌱",
    "المعلومة قوة، والتعلم المستمر هو اللي هيخليك تسبق الكل، برافو عليك ✨",
    "تذكر إن كل خبير كان في يوم مبتدئ زيك، كمل طريقك 🚀",
  ];

  final List<String> proMessages = [
    "أنت مشيت طريق طويل ووصلت لمستوى المحترفين، كمل سلم النجاح للأخر 👑",
    "المحترف الحقيقي هو اللي بيطور نفسه كل يوم، خليك دايمًا في القمة 🏔️",
    "النجاح رحلة مستمرة وأنت أثبت إنك قدها، كمل يا Pro 🚀"
  ];

  @override
  void initState() {
    super.initState();
    timeLeft = (widget.categoryTitle == "دوري المحترفين") ? 15 : 25;
    _fetchContent();
  }

  @override
  void dispose() {
    timer?.cancel();
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
          score += (widget.categoryTitle == "دوري النجوم") ? 2 : 5;
        }
      });
    }

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      if (!isEducationalOnly &&
          batchCount >= 5 &&
          currentQuestionIndex != dataItems.length - 1) {
        _showBatchBreakdown();
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
      isEducationalOnly ? Navigator.pop(context) : _saveScoreAndFinish();
    }
  }

  void _showBatchBreakdown() {
    setState(() => batchCount = 0);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("أحسنت! مكملين؟ 🚀",
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: Text("نقاطك الحالية: $score",
            textAlign: TextAlign.center, style: GoogleFonts.cairo()),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.pop(c);
                _showMotivationalExit();
              },
              child: Text("خروج", style: GoogleFonts.cairo(color: Colors.red))),
          ElevatedButton(
              onPressed: () {
                Navigator.pop(c);
                _nextStep();
              },
              style: ElevatedButton.styleFrom(backgroundColor: deepTeal),
              child: Text("استمرار",
                  style: GoogleFonts.cairo(color: Colors.white))),
        ],
      ),
    );
  }

  void _showMotivationalExit() {
    if (isEducationalOnly) {
      Navigator.pop(context);
      return;
    }
    final random = Random();
    String message = (widget.categoryTitle == "دوري النجوم")
        ? starMessages[random.nextInt(starMessages.length)]
        : proMessages[random.nextInt(proMessages.length)];
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(25),
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("كنز المعلومة 💡",
                style: GoogleFonts.cairo(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: safetyOrange)),
            const SizedBox(height: 15),
            Text(message,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(fontSize: 15, height: 1.6)),
            const SizedBox(height: 25),
            SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: deepTeal,
                        padding: const EdgeInsets.symmetric(vertical: 15)),
                    onPressed: () {
                      Navigator.pop(context);
                      _saveScoreAndFinish();
                    },
                    child: Text("حفظ والعودة",
                        style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)))),
          ],
        ),
      ),
    );
  }

  Future<void> _saveScoreAndFinish() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && score > 0 && !isEducationalOnly) {
      if (mounted) setState(() => isSaving = true);
      String pointsField =
          (widget.categoryTitle == "دوري النجوم") ? 'starsPoints' : 'proPoints';
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'points': FieldValue.increment(score),
          pointsField: FieldValue.increment(score),
          'lastQuizDate': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint("Error saving score: $e");
      }
    }
    if (mounted) {
      setState(() => isSaving = false);
      _showFinalResult();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (dataItems.isEmpty)
      return Scaffold(
          appBar: _buildUnifiedHeader(),
          body: const Center(child: Text("لا يوجد محتوى حالياً")));
    if (widget.isTopicMode || widget.categoryTitle == "المعلومة بتفرق")
      return _buildTopicView();
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
                child: Text("سؤال ${batchCount == 0 ? 5 : batchCount} من 5",
                    style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold, color: deepTeal))),
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

  Widget _buildTopicView() {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: _buildUnifiedHeader(),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: dataItems.length,
          itemBuilder: (context, index) =>
              _buildDetailedTopicCard(dataItems[index]),
        ),
      ),
    );
  }

  Widget _buildDetailedTopicCard(Map<String, dynamic> data) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (c) => QuizTopicDetailPage(data: data))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ]),
        child: Column(
          children: [
            if (data['imageUrl'] != null && data['imageUrl'] != "")
              ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  child: CachedNetworkImage(
                      imageUrl: data['imageUrl'],
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover)),
            Padding(
                padding: const EdgeInsets.all(15),
                child: Text(data['title'] ?? "",
                    style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold,
                        color: deepTeal,
                        fontSize: 16))),
          ],
        ),
      ),
    );
  }

  void _showFinalResult() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                title:
                    const Text("انتهى التحدي! 🏆", textAlign: TextAlign.center),
                actions: [
                  Center(
                      child: ElevatedButton(
                          onPressed: () =>
                              Navigator.popUntil(context, (r) => r.isFirst),
                          child: const Text("الرئيسية")))
                ]));
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

// --- عارض المواضيع الفنية المطور (صفحة عرض تفاصيل الموضوع) ---
class QuizTopicDetailPage extends StatelessWidget {
  final Map<String, dynamic> data;
  const QuizTopicDetailPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFB), // لون خلفية هادئ جداً
      appBar: AppBar(
        backgroundColor: AppColors.primaryDeepTeal,
        elevation: 0,
        centerTitle: true,
        title: Text(data['title'] ?? "التفاصيل",
            style:
                GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // إذا كان هناك صورة للموضوع تظهر في الأعلى
              if (data['imageUrl'] != null && data['imageUrl'] != "")
                CachedNetworkImage(
                  imageUrl: data['imageUrl'],
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                ),

              // كارت المحتوى الفني بتنسيق "معلومة L Pro" الفخم
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
                          offset: const Offset(0, 8)),
                    ],
                    border: Border.all(
                        color: AppColors.primaryDeepTeal.withOpacity(0.1),
                        width: 1.2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Column(
                      children: [
                        // هيدر الكارت (نفس ستايل الهوم)
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
                              end: Alignment.centerLeft,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.auto_stories_rounded,
                                  color: AppColors.secondaryOrange, size: 22),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  data['title'] ?? "المحتوى الفني",
                                  style: GoogleFonts.cairo(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // نص الموضوع (المهم جداً التنسيق والمحاذاة)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(22),
                          color: Colors.white,
                          child: Text(
                            data['content'] ?? "",
                            textAlign: TextAlign.right, // دائماً من اليمين
                            style: GoogleFonts.cairo(
                              fontSize: 16, // حجم خط مريح للقراءة الطويلة
                              height: 1.8, // مسافة واسعة بين السطور
                              color: const Color(0xFF2D3142),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import 'dart:math';

import 'package:lpro2_quiz/core/constants/app_colors.dart';
import 'package:lpro2_quiz/core/utils/sound_manager.dart';

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

  // مصفوفات الرسائل التحفيزية
  final List<String> starMessages = [
    "الاستمرار هو السر، كل معلومة بتعرفها النهاردة هي طوبة في صرح نجاحك بكرة 🌱",
    "طبيعي تحس باللخبطة في الأول، المهم إنك مكمل وبتحاول، الصبر هو مفتاح العقارات 🔑",
    "المعلومة قوة، والتعلم المستمر هو اللي هيخليك تسبق الكل، برافو عليك ✨",
    "تذكر إن كل خبير كان في يوم مبتدئ زيك، الاحباط مجرد محطة، كمل طريقك 🚀",
    "نجاحك بيبدأ بقرارك إنك متوقفش تعلم مهما كانت التحديات، فخورين بيك 👏"
  ];

  final List<String> proMessages = [
    "افتكر اللحظة اللي قفلت فيها أصعب بيعة، القوة دي جواك وبتقدر تكررها تاني 🔥",
    "أنت مشيت طريق طويل ووصلت لمستوى المحترفين، كمل سلم النجاح للأخر 👑",
    "المحترف الحقيقي هو اللي بيطور نفسه كل يوم، خليك دايمًا في القمة 🏔️",
    "الخبرة هي تراكم اللحظات دي، استعد للبيعة الجاية بمعلوماتك القوية 🔝",
    "النجاح مش محطة، النجاح رحلة مستمرة وأنت أثبت إنك قدها، كمل يا Pro 🚀"
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

  // فحص هل القسم إثرائي (للمعلومة فقط) أم تنافسي
  bool get isEducationalOnly =>
      widget.categoryTitle == "المعلومة بتفرق" || widget.isTopicMode;

  void _playAppSound(String type) {
    if (isEducationalOnly) return; // لا أصوات في الأقسام التعليمية
    if (type == 'success')
      SoundManager.playCorrect();
    else if (type == 'wrong')
      SoundManager.playWrong();
    else
      SoundManager.playTap();
  }

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
    if (isEducationalOnly) return; // تعطيل التايمر في القسم التعليمي
    setState(
        () => timeLeft = (widget.categoryTitle == "دوري المحترفين") ? 15 : 25);
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) {
        if (timeLeft > 0)
          setState(() => timeLeft--);
        else
          _handleAnswer("");
      }
    });
  }

  void _handleAnswer(String selected) {
    if (showFeedback) return;
    timer?.cancel();

    var currentQ = dataItems[currentQuestionIndex];
    bool isCorrect = _normalize(selected) ==
        _normalize(currentQ['options'][currentQ['correctAnswer']]);

    _playAppSound(isCorrect ? 'success' : 'wrong');

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
                style: GoogleFonts.cairo(
                    fontSize: 15, height: 1.6, fontWeight: FontWeight.w600)),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: deepTeal,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15))),
                onPressed: () {
                  Navigator.pop(context);
                  _saveScoreAndFinish();
                },
                child: Text("حفظ والعودة",
                    style: GoogleFonts.cairo(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _saveScoreAndFinish() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && score > 0 && !isEducationalOnly) {
      setState(() => isSaving = true);
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
        debugPrint("Error: $e");
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
    if (widget.isTopicMode) return _buildTopicView();
    if (!gameStarted) return _buildStartView();

    var q = dataItems[currentQuestionIndex];
    return Scaffold(
      backgroundColor: lightTurquoise,
      appBar: _buildUnifiedHeader(),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            if (!isEducationalOnly) // إخفاء شريط الوقت في الأقسام التعليمية
              LinearProgressIndicator(
                value: timeLeft /
                    ((widget.categoryTitle == "دوري المحترفين") ? 15 : 25),
                color: safetyOrange,
                backgroundColor: Colors.white,
                minHeight: 6,
              ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("خطوة ${currentQuestionIndex + 1}",
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                  if (!isEducationalOnly)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                          color: deepTeal,
                          borderRadius: BorderRadius.circular(10)),
                      child: Text("نقاط: $score",
                          style: GoogleFonts.cairo(
                              color: Colors.white, fontSize: 12)),
                    )
                ],
              ),
            ),
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
    String correctVal = currentQ['options'][correctIdx];
    bool isCorrect = showFeedback && opt == correctVal;
    bool isWrong = showFeedback && opt == selectedOption && opt != correctVal;

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => isEducationalOnly
              ? Navigator.pop(context)
              : _showMotivationalExit(),
        ),
        title: Text(widget.categoryTitle,
            style: GoogleFonts.cairo(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
      );

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
                        onPressed: () => Navigator.of(context)
                          ..pop()
                          ..pop(),
                        child: const Text("الرئيسية")))
              ],
            ));
  }

  String _normalize(String text) => text
      .trim()
      .replaceAll(RegExp(r'[\u064B-\u0652]'), '')
      .replaceAll(RegExp(r'[أإآ]'), 'ا')
      .replaceAll(RegExp(r'[ى]'), 'ي')
      .replaceAll(RegExp(r'[ة]'), 'ه')
      .toLowerCase();

  Widget _buildQuestionCard(String text) => Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)
          ]),
      child: Text(text,
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(
              fontSize: 17, fontWeight: FontWeight.bold, color: deepTeal)));

  Widget _buildStartView() => Scaffold(
      backgroundColor: lightTurquoise,
      appBar: _buildUnifiedHeader(),
      body: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(widget.categoryTitle,
            style: GoogleFonts.cairo(
                fontSize: 28, fontWeight: FontWeight.bold, color: deepTeal)),
        const SizedBox(height: 40),
        ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: safetyOrange,
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 15)),
            onPressed: () {
              setState(() => gameStarted = true);
              _startTimer();
            },
            child: Text("ابدأ الآن 🚀",
                style: GoogleFonts.cairo(
                    color: Colors.white, fontWeight: FontWeight.bold)))
      ])));

  Widget _buildTopicView() => Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: _buildUnifiedHeader(),
      body: Directionality(
          textDirection: TextDirection.rtl,
          child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: dataItems.length,
              itemBuilder: (context, index) =>
                  _buildDetailedTopicCard(dataItems[index]))));

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
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)
            ]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['title'] ?? "",
                      style: GoogleFonts.cairo(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: deepTeal)),
                  const SizedBox(height: 5),
                  Text(data['content'] ?? "",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                          fontSize: 13, color: Colors.black54, height: 1.5)),
                  const SizedBox(height: 10),
                  Row(children: [
                    Text("اقرأ المزيد",
                        style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: safetyOrange,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(width: 5),
                    Icon(Icons.arrow_circle_left_outlined,
                        size: 16, color: safetyOrange)
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QuizTopicDetailPage extends StatelessWidget {
  final Map<String, dynamic> data;
  const QuizTopicDetailPage({super.key, required this.data});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
                expandedHeight: 250,
                pinned: true,
                backgroundColor: AppColors.primaryDeepTeal,
                flexibleSpace: FlexibleSpaceBar(
                    background:
                        data['imageUrl'] != null && data['imageUrl'] != ""
                            ? CachedNetworkImage(
                                imageUrl: data['imageUrl'], fit: BoxFit.cover)
                            : Container(color: AppColors.primaryDeepTeal))),
            SliverPadding(
                padding: const EdgeInsets.all(25),
                sliver: SliverList(
                    delegate: SliverChildListDelegate([
                  Text(data['title'] ?? "",
                      style: GoogleFonts.cairo(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryDeepTeal)),
                  const SizedBox(height: 15),
                  const Divider(),
                  const SizedBox(height: 15),
                  Text(data['content'] ?? "",
                      style: GoogleFonts.cairo(
                          fontSize: 15,
                          height: 1.8,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 50)
                ]))),
          ],
        ),
      ),
    );
  }
}

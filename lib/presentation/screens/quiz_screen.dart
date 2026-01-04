import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';

// استيراد الثوابت ومدير الصوت
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
  int score = 0;
  int timeLeft = 25;
  Timer? timer;
  bool gameStarted = false;
  String? selectedOption;
  bool showFeedback = false;
  bool isLoading = true;
  bool isSaving = false;

  List<Map<String, dynamic>> dataItems = [];

  @override
  void initState() {
    super.initState();
    _fetchContent();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  // دالة تشغيل الأصوات مع ضمان القوة المطلوبة
  void _playAppSound(String type) {
    if (type == 'success') {
      SoundManager.playCorrect(); // استدعاء صوت الإجابة الصحيحة
    } else if (type == 'wrong') {
      SoundManager
          .playWrong(); // استدعاء صوت الإجابة الخاطئة (المعدل ليكون أعلى)
    } else {
      SoundManager.playTap(); // صوت النقر العام
    }
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

          if (!widget.isTopicMode) dataItems.shuffle(); // عشوائية التحديات
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _startTimer() {
    if (widget.isTopicMode) return;
    timeLeft = 25;
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) {
        if (timeLeft > 0) {
          setState(() => timeLeft--);
        } else {
          _handleAnswer(""); // انتهاء الوقت يعتبر إجابة خاطئة
        }
      }
    });
  }

  void _handleAnswer(String selected) {
    if (showFeedback) return;
    timer?.cancel();

    var currentQ = dataItems[currentQuestionIndex];

    // التحقق من صحة الإجابة باستخدام الـ Normalize لمنع أخطاء المسافات
    bool isCorrect = _normalize(selected) ==
        _normalize(currentQ['options'][currentQ['correctAnswer']]);

    if (isCorrect) {
      _playAppSound('success');
    } else {
      _playAppSound('wrong'); // سينطلق الآن بصوت مرتفع جداً
    }

    if (mounted) {
      setState(() {
        selectedOption = selected;
        showFeedback = true;
        if (isCorrect) {
          // توزيع النقاط حسب نوع الدوري
          score += (widget.categoryTitle == "دوري النجوم") ? 2 : 5;
        }
      });
    }

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      // ميزة استراحة محارب كل 5 أسئلة لزيادة التشويق
      if ((currentQuestionIndex + 1) % 5 == 0 &&
          currentQuestionIndex != dataItems.length - 1) {
        _showInterimResult();
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
      _saveScoreAndFinish();
    }
  }

  // دالة دقيقة جداً لتحديث النقاط في الفايربيز
  Future<void> _saveScoreAndFinish() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && score > 0 && !widget.isTopicMode) {
      setState(() => isSaving = true);
      String pointsField =
          (widget.categoryTitle == "دوري النجوم") ? 'starsPoints' : 'proPoints';

      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'points': FieldValue.increment(score), // تحديث الحقل العام
          pointsField: FieldValue.increment(score), // تحديث حقل الدوري الخاص
          'lastQuizDate': FieldValue.serverTimestamp(),
        });
        debugPrint("Score Saved Successfully ✅");
      } catch (e) {
        debugPrint("Error saving score: $e");
      }
    }
    if (mounted) {
      setState(() => isSaving = false);
      _showFinalResult();
    }
  }

  PreferredSizeWidget _buildUnifiedHeader() {
    return AppBar(
      backgroundColor: deepTeal,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () {
            _playAppSound('click');
            Navigator.pop(context);
          }),
      title: Text(widget.categoryTitle,
          style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
    );
  }

  Widget _buildQuizPlayView() {
    var q = dataItems[currentQuestionIndex];
    return Scaffold(
      backgroundColor: lightTurquoise,
      appBar: _buildUnifiedHeader(),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: timeLeft / 25,
              color: safetyOrange,
              backgroundColor: Colors.white,
              minHeight: 6,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(25),
                child: Column(
                  children: [
                    if (q['imageUrl'] != null && q['imageUrl'] != "")
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: CachedNetworkImage(
                          imageUrl: q['imageUrl'],
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              Container(height: 180, color: Colors.grey[200]),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.error),
                        ),
                      ),
                    const SizedBox(height: 20),
                    _buildQuestionCard(q['question']),
                    const SizedBox(height: 30),
                    _buildOptions(q['options']),
                  ],
                ),
              ),
            ),
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
    return Column(
      children: options.map((opt) {
        var currentQ = dataItems[currentQuestionIndex];
        var correctVal = currentQ['options'][currentQ['correctAnswer']];
        bool isThisCorrect = showFeedback && opt == correctVal;
        bool isThisSelectedWrong =
            showFeedback && opt == selectedOption && opt != correctVal;

        return GestureDetector(
          onTap: () => _handleAnswer(opt),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 15),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isThisCorrect
                  ? Colors.green
                  : (isThisSelectedWrong ? Colors.red : Colors.white),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: (isThisCorrect || isThisSelectedWrong)
                      ? Colors.transparent
                      : Colors.grey.shade200),
            ),
            child: Center(
                child: Text(opt,
                    style: GoogleFonts.cairo(
                        color: (isThisCorrect || isThisSelectedWrong)
                            ? Colors.white
                            : deepTeal,
                        fontWeight: FontWeight.bold,
                        fontSize: 15))),
          ),
        );
      }).toList(),
    );
  }

  void _showFinalResult() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Text("المهمة تمت بنجاح! ✨",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
              content: Text("مجموع نقاطك المضافة: $score",
                  textAlign: TextAlign.center, style: GoogleFonts.cairo()),
              actions: [
                Center(
                    child: TextButton(
                        onPressed: () {
                          _playAppSound('click');
                          Navigator.pop(c);
                          Navigator.pop(context);
                        },
                        child: Text("العودة للرئيسية",
                            style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold,
                                color: safetyOrange))))
              ],
            ));
  }

  void _showInterimResult() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => AlertDialog(
              title: Text("استراحة محارب ☕",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
              content: Text(
                  "نقاطك الحالية: $score\nهل تريد الاستمرار أم حفظ النقاط والانسحاب؟",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo()),
              actions: [
                TextButton(
                    onPressed: () {
                      _playAppSound('click');
                      Navigator.pop(c);
                      _saveScoreAndFinish();
                    },
                    child: Text("انسحاب وحفظ",
                        style: GoogleFonts.cairo(color: Colors.red))),
                ElevatedButton(
                    onPressed: () {
                      _playAppSound('click');
                      Navigator.pop(c);
                      _nextStep();
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: deepTeal),
                    child: Text("استمرار", style: GoogleFonts.cairo())),
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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
          backgroundColor: AppColors.scaffoldBackground,
          body: Center(child: CircularProgressIndicator()));
    }
    if (dataItems.isEmpty) {
      return Scaffold(
          appBar: _buildUnifiedHeader(),
          body: const Center(child: Text("لا يوجد محتوى حالياً")));
    }
    if (widget.isTopicMode) return _buildTopicView();
    if (!gameStarted) return _buildStartView();
    return Stack(
      children: [
        _buildQuizPlayView(),
        if (isSaving)
          Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator())),
      ],
    );
  }

  Widget _buildStartView() {
    return Scaffold(
      backgroundColor: lightTurquoise,
      appBar: _buildUnifiedHeader(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(widget.categoryTitle,
                style: GoogleFonts.cairo(
                    fontSize: 32,
                    color: deepTeal,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            Text("استعد لإثبات مهاراتك",
                style: GoogleFonts.cairo(
                    fontSize: 16, color: deepTeal.withOpacity(0.7))),
            const SizedBox(height: 60),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: safetyOrange,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 60, vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30))),
              onPressed: () {
                _playAppSound('click');
                setState(() => gameStarted = true);
                _startTimer();
              },
              child: Text(
                  widget.categoryTitle == "دوري النجوم"
                      ? "يلا يا نجم 🚀"
                      : "اتفضل يا Pro 🔥",
                  style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
            ),
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
      onTap: () {
        _playAppSound('click');
        Navigator.push(context,
            MaterialPageRoute(builder: (c) => QuizTopicDetailPage(data: data)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5))
          ],
        ),
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
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                      height: 160,
                      color: Colors.grey[100],
                      child: const Center(child: CircularProgressIndicator())),
                  errorWidget: (context, url, error) => const SizedBox(),
                ),
              ),
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
                  Row(
                    children: [
                      Text("اقرأ المزيد",
                          style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: safetyOrange,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(width: 5),
                      Icon(Icons.arrow_circle_left_outlined,
                          size: 16, color: safetyOrange),
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
}

// صفحة تفاصيل المحتوى التعليمي
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
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: data['imageUrl'] != null && data['imageUrl'] != ""
                    ? CachedNetworkImage(
                        imageUrl: data['imageUrl'], fit: BoxFit.cover)
                    : Container(color: AppColors.primaryDeepTeal),
              ),
            ),
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
                const SizedBox(height: 50),
              ])),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'dart:async';

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
  final Color deepTeal = const Color(0xFF1B4D57);
  final Color safetyOrange = const Color(0xFFE67E22);
  final Color lightTurquoise =
      const Color(0xFFE0F7F9); // لون فيروزي فاتح جداً للخلفية

  int currentQuestionIndex = 0;
  int score = 0;
  int timeLeft = 25;
  Timer? timer;
  bool gameStarted = false;
  String? selectedOption;
  bool showFeedback = false;
  bool isLoading = true;

  List<Map<String, dynamic>> dataItems = [];

  bool get isAdmin =>
      FirebaseAuth.instance.currentUser?.email == "admin@lpro.com";

  @override
  void initState() {
    super.initState();
    _fetchContent();
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
          if (!widget.isTopicMode) dataItems.shuffle();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // --- الهيدر الموحد بـ اللوجو وزر الرجوع ---
  PreferredSizeWidget _buildUnifiedHeader() {
    return AppBar(
      backgroundColor: deepTeal,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Image.asset(
        'assets/top_brand.png',
        height: 30,
        errorBuilder: (context, error, stackTrace) => Text(
          "LPro",
          style: GoogleFonts.cairo(
              fontWeight: FontWeight.w900, color: Colors.white, fontSize: 18),
        ),
      ),
    );
  }

  // --- إدارة الوقت والخطوات ---
  void _startTimer() {
    if (widget.isTopicMode) return;
    timeLeft = 25;
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (timeLeft > 0) {
        if (mounted) setState(() => timeLeft--);
      } else {
        _handleAnswer("");
      }
    });
  }

  void _nextStep() {
    if (currentQuestionIndex < dataItems.length - 1) {
      setState(() {
        currentQuestionIndex++;
        showFeedback = false;
        selectedOption = null;
      });
      if (!widget.isTopicMode) _startTimer();
    } else {
      _saveScoreAndFinish();
    }
  }

  // --- واجهة عرض المواضيع ---
  Widget _buildTopicView() {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F8),
      appBar: _buildUnifiedHeader(),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: dataItems.length,
          itemBuilder: (context, index) {
            var item = dataItems[index];
            return _buildTopicCard(item);
          },
        ),
      ),
    );
  }

  Widget _buildTopicCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
        border: Border(right: BorderSide(color: safetyOrange, width: 6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item['imageUrl'] != null &&
              item['imageUrl'].toString().isNotEmpty)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: Image.network(
                item['imageUrl'],
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(item['title'] ?? "",
                          style: GoogleFonts.cairo(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: deepTeal)),
                    ),
                    if (isAdmin) _buildAdminControls(item, isTopic: true),
                  ],
                ),
                const SizedBox(height: 10),
                Text(item['content'] ?? "",
                    style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.7,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminControls(Map<String, dynamic> item,
      {required bool isTopic}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
            icon: const Icon(Icons.swap_horiz, color: Colors.blue, size: 20),
            onPressed: () => _moveItem(item, isTopic)),
        IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            onPressed: () => _confirmDelete(item, isTopic)),
      ],
    );
  }

  void _moveItem(Map<String, dynamic> item, bool isTopic) async {
    String collection = isTopic ? 'topics' : 'quizzes';
    String currentCat = item['category'];
    String newCat = isTopic
        ? (currentCat == "المعلومة بتفرق" ? "افهم عميلك" : "المعلومة بتفرق")
        : (currentCat == "دوري النجوم" ? "دوري المحترفين" : "دوري النجوم");

    await FirebaseFirestore.instance
        .collection(collection)
        .doc(item['id'])
        .update({'category': newCat});
    _fetchContent();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("تم النقل إلى $newCat")));
  }

  void _confirmDelete(Map<String, dynamic> item, bool isTopic) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text("حذف المحتوى؟", style: GoogleFonts.cairo()),
        content: const Text("هل أنت متأكد من حذف هذا العنصر نهائياً؟"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c), child: const Text("إلغاء")),
          TextButton(
            onPressed: () async {
              String collection = isTopic ? 'topics' : 'quizzes';
              await FirebaseFirestore.instance
                  .collection(collection)
                  .doc(item['id'])
                  .delete();
              Navigator.pop(c);
              _fetchContent();
            },
            child: const Text("حذف", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // --- واجهة لعب الكويز ---
  Widget _buildQuizPlayView() {
    var q = dataItems[currentQuestionIndex];
    return Scaffold(
      backgroundColor: lightTurquoise, // الخلفية الفيروزية
      appBar: _buildUnifiedHeader(),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            const SizedBox(height: 10),
            LinearProgressIndicator(
                value: timeLeft / 25,
                color: safetyOrange,
                backgroundColor: Colors.white),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(25),
                child: Column(
                  children: [
                    if (isAdmin) _buildAdminControls(q, isTopic: false),
                    if (q['imageUrl'] != null &&
                        q['imageUrl'].toString().isNotEmpty)
                      Container(
                        height: 180,
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          image: DecorationImage(
                              image: NetworkImage(q['imageUrl']),
                              fit: BoxFit.cover),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10)
                          ],
                        ),
                      ),
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
        var correctVal = dataItems[currentQuestionIndex]['options']
            [dataItems[currentQuestionIndex]['correctAnswer']];
        bool isCorrect = showFeedback && opt == correctVal;
        bool isWrong =
            showFeedback && opt == selectedOption && opt != correctVal;
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
              border: Border.all(
                  color: isCorrect || isWrong
                      ? Colors.transparent
                      : Colors.grey.shade200),
            ),
            child: Center(
                child: Text(opt,
                    style: GoogleFonts.cairo(
                        color: (isCorrect || isWrong) ? Colors.white : deepTeal,
                        fontWeight: FontWeight.bold,
                        fontSize: 15))),
          ),
        );
      }).toList(),
    );
  }

  void _handleAnswer(String selected) {
    if (showFeedback) return;
    timer?.cancel();
    var currentQ = dataItems[currentQuestionIndex];
    bool isCorrect = _normalize(selected) ==
        _normalize(currentQ['options'][currentQ['correctAnswer']]);
    setState(() {
      selectedOption = selected;
      showFeedback = true;
      if (isCorrect) score += (widget.categoryTitle == "دوري النجوم") ? 2 : 5;
    });
    Future.delayed(const Duration(milliseconds: 1500), () {
      if ((currentQuestionIndex + 1) % 5 == 0 &&
          currentQuestionIndex != dataItems.length - 1) {
        _showInterimResult();
      } else {
        _nextStep();
      }
    });
  }

  Future<void> _saveScoreAndFinish() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && score > 0 && !widget.isTopicMode) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'points': FieldValue.increment(score),
        'lastQuizDate': FieldValue.serverTimestamp(),
      });
    }
    _showFinalResult();
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
              content: Text("مجموع نقاطك في هذا التحدي: $score",
                  textAlign: TextAlign.center, style: GoogleFonts.cairo()),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.pop(c);
                      Navigator.pop(context);
                    },
                    child: const Text("العودة للرئيسية"))
              ],
            ));
  }

  void _showInterimResult() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => AlertDialog(
              title: const Text("استراحة محارب ☕"),
              content: Text("نقاطك الحالية: $score\nهل تريد الاستمرار؟"),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.pop(c);
                      _saveScoreAndFinish();
                    },
                    child: const Text("انسحاب")),
                ElevatedButton(
                    onPressed: () {
                      Navigator.pop(c);
                      _nextStep();
                    },
                    child: const Text("استمرار")),
              ],
            ));
  }

  String _normalize(String text) => text
      .trim()
      .replaceAll(RegExp(r'[أإآ]'), 'ا')
      .replaceAll(RegExp(r'[ى]'), 'ي')
      .replaceAll(RegExp(r'[ة]'), 'ه')
      .toLowerCase();

  @override
  Widget build(BuildContext context) {
    if (isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (dataItems.isEmpty) return _buildEmptyView();
    if (widget.isTopicMode) return _buildTopicView();
    if (!gameStarted) return _buildStartView();
    return _buildQuizPlayView();
  }

  Widget _buildEmptyView() => Scaffold(
      appBar: _buildUnifiedHeader(),
      body: const Center(child: Text("لا يوجد محتوى حالياً")));

  // --- واجهة البداية المحدثة ---
  Widget _buildStartView() {
    String buttonText = widget.categoryTitle == "دوري النجوم"
        ? "يلا يا نجم 🚀"
        : "اتفضل يا Pro 🔥";

    return Scaffold(
      backgroundColor: lightTurquoise, // الخلفية الفيروزية
      appBar: _buildUnifiedHeader(),
      body: Container(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(widget.categoryTitle,
                style: GoogleFonts.cairo(
                    fontSize: 32,
                    color: deepTeal,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            Text(
                widget.categoryTitle == "دوري النجوم"
                    ? "استعد لإثبات مهاراتك"
                    : "تحدي الكبار يبدأ من هنا",
                style: GoogleFonts.cairo(
                    fontSize: 16, color: deepTeal.withOpacity(0.7))),
            const SizedBox(height: 60),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: safetyOrange,
                padding:
                    const EdgeInsets.symmetric(horizontal: 60, vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
                elevation: 8,
              ),
              onPressed: () {
                setState(() => gameStarted = true);
                _startTimer();
              },
              child: Text(buttonText,
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

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
}

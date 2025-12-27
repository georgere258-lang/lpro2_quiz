import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/**
 * [QuizScreen] - قسم "نشط ذهنك" المصحح
 * تم إصلاح خطأ RoundedRectangleBorder وتعديل نظام النقاط والرسائل التشجيعية.
 * يلتزم الكود بمعايير الضخامة (450+ سطر) لضمان تفصيل كل Widget.
 */

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  
  // =============================================================
  // [1] الإعدادات والبيانات الأساسية (The Quiz Engine)
  // =============================================================
  
  static const Color brandOrange = Color(0xFFC67C32);
  static const Color navyDeep = Color(0xFF1E2B3E);
  static const Color pureWhite = Color(0xFFFFFFFF);
  
  int _currentQuestionIndex = 0;
  int _points = 0; // الرصيد بالنقاط كما اتفقنا
  int _correctAnswersInARow = 0; // عداد التوالي للرسائل التشجيعية
  bool _isAnswered = false;
  int? _selectedAnswerIndex;
  
  int _secondsRemaining = 15;
  Timer? _timer;
  late AnimationController _timerAnimationController;

  // قائمة الرسائل التشجيعية المخصصة
  final List<String> _motivationalMessages = [
    "الله ينور عليكِ! ✨",
    "وحش العقارات في الملعب! 🦁",
    "كملي.. إنتي جامدة جداً! 🔥",
    "عاش يا بطلة.. الترتيب في انتظارك! 🏆",
    "تركيز عالي.. استمري! 🚀",
    "إجابة ذكية من شخص أذكى! 💡",
  ];

  // قاعدة بيانات الأسئلة العقارية
  final List<Map<String, dynamic>> _questions = [
    {
      "question": "ما هي المنطقة التي تُلقب بـ 'قلب القاهرة الجديدة'؟",
      "options": ["التجمع الخامس", "العاصمة الإدارية", "الرحاب", "مدينتي"],
      "correctIndex": 0,
    },
    {
      "question": "أيهما يعتبر استثماراً طويل الأجل في العقارات؟",
      "options": ["الإيجار الشهري", "شراء أرض وبنائها", "التمويل الاستهلاكي", "المضاربة اليومية"],
      "correctIndex": 1,
    },
    {
      "question": "ما هو المصطلح الذي يعبر عن العائد السنوي للعقار؟",
      "options": ["ROI", "Yield", "Cash Flow", "Equity"],
      "correctIndex": 1,
    },
    {
      "question": "ما هي أفضل ميزة تنافسية في السكن بالعاصمة الإدارية؟",
      "options": ["البنية التحتية الذكية", "المساحات الصغيرة", "البعد عن القاهرة", "سهولة التراخيص"],
      "correctIndex": 0,
    }
  ];

  @override
  void initState() {
    super.initState();
    _startTimer();
    _timerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..reverse(from: 1.0);
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _timer?.cancel();
        _handleQuestionEnd();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timerAnimationController.dispose();
    super.dispose();
  }

  // =============================================================
  // [2] المنطق البرمجي (Quiz Logic)
  // =============================================================

  void _checkUserSelection(int index) {
    if (_isAnswered) return;
    
    _timer?.cancel();
    _timerAnimationController.stop();

    setState(() {
      _isAnswered = true;
      _selectedAnswerIndex = index;
      if (index == _questions[_currentQuestionIndex]['correctIndex']) {
        _points += 20; // إضافة نقاط بدلاً من كوينات
        _correctAnswersInARow++;
      } else {
        _correctAnswersInARow = 0; 
      }
    });

    // إظهار الرسائل التشجيعية كل سؤالين صحيحين
    if (_correctAnswersInARow >= 2) {
      _triggerEncouragementAlert();
      _correctAnswersInARow = 0; 
    }

    Future.delayed(const Duration(milliseconds: 1800), () => _handleQuestionEnd());
  }

  void _handleQuestionEnd() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _isAnswered = false;
        _selectedAnswerIndex = null;
        _secondsRemaining = 15;
      });
      _startTimer();
      _timerAnimationController.reverse(from: 1.0);
    } else {
      _displayFinalVictory();
    }
  }

  void _triggerEncouragementAlert() {
    final randomMsg = _motivationalMessages[Random().nextInt(_motivationalMessages.length)];
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.auto_awesome_rounded, color: brandOrange),
            const SizedBox(width: 15),
            Text(randomMsg, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: navyDeep)),
          ],
        ),
        backgroundColor: Colors.white,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.only(bottom: 110, left: 30, right: 30),
      ),
    );
  }

  // =============================================================
  // [3] بناء واجهة المستخدم (The High-Fidelity UI)
  // =============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navyDeep,
      appBar: _buildProfessionalAppBar(),
      body: Column(
        children: [
          _buildTopLinearTimer(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(25),
              child: Column(
                children: [
                  _buildQuestionSurface(),
                  const SizedBox(height: 35),
                  _buildOptionsGrid(),
                ],
              ),
            ),
          ),
          _buildPointsStatusTray(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildProfessionalAppBar() {
    return AppBar(
      backgroundColor: navyDeep,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close_rounded, color: pureWhite),
        onPressed: () => Navigator.pop(context),
      ),
      centerTitle: true,
      title: Column(
        children: [
          Text("نشط ذهنك العقاري", style: GoogleFonts.cairo(fontWeight: FontWeight.w900, color: pureWhite, fontSize: 18)),
          Text("السؤال ${_currentQuestionIndex + 1} من ${_questions.length}", 
               style: GoogleFonts.cairo(fontSize: 12, color: brandOrange, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTopLinearTimer() {
    return AnimatedBuilder(
      animation: _timerAnimationController,
      builder: (context, child) {
        return LinearProgressIndicator(
          value: _timerAnimationController.value,
          backgroundColor: pureWhite.withOpacity(0.05),
          valueColor: AlwaysStoppedAnimation<Color>(
            _secondsRemaining < 5 ? Colors.redAccent : brandOrange,
          ),
          minHeight: 5,
        );
      },
    );
  }

  Widget _buildQuestionSurface() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: pureWhite.withOpacity(0.04),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: pureWhite.withOpacity(0.1)),
        boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          const Icon(Icons.lightbulb_outline_rounded, color: brandOrange, size: 50),
          const SizedBox(height: 25),
          Text(
            _questions[_currentQuestionIndex]['question'],
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(color: pureWhite, fontSize: 20, fontWeight: FontWeight.bold, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsGrid() {
    List<String> opts = _questions[_currentQuestionIndex]['options'];
    return Column(
      children: List.generate(opts.length, (index) => _buildSelectionTile(index, opts[index])),
    );
  }

  Widget _buildSelectionTile(int index, String label) {
    bool isCorrect = index == _questions[_currentQuestionIndex]['correctIndex'];
    bool isSelected = index == _selectedAnswerIndex;
    
    Color borderCol = pureWhite.withOpacity(0.1);
    Color bgCol = pureWhite.withOpacity(0.05);

    if (_isAnswered) {
      if (isCorrect) {
        borderCol = Colors.greenAccent;
        bgCol = Colors.greenAccent.withOpacity(0.12);
      } else if (isSelected) {
        borderCol = Colors.redAccent;
        bgCol = Colors.redAccent.withOpacity(0.12);
      }
    }

    return GestureDetector(
      onTap: () => _checkUserSelection(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: bgCol,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: borderCol, width: 2),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: navyDeep.withOpacity(0.4),
              child: Text("${index + 1}", style: const TextStyle(color: brandOrange, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Text(label, style: GoogleFonts.cairo(color: pureWhite, fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            if (_isAnswered && isCorrect) const Icon(Icons.verified_rounded, color: Colors.greenAccent),
            if (_isAnswered && isSelected && !isCorrect) const Icon(Icons.error_outline_rounded, color: Colors.redAccent),
          ],
        ),
      ),
    );
  }

  Widget _buildPointsStatusTray() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 25),
      decoration: BoxDecoration(
        color: pureWhite.withOpacity(0.02),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
        border: Border(top: BorderSide(color: pureWhite.withOpacity(0.05))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("رصيد النقاط المكتسب", style: GoogleFonts.cairo(color: pureWhite.withOpacity(0.4), fontSize: 12, fontWeight: FontWeight.bold)),
              Text("$_points نقطة", style: GoogleFonts.cairo(color: brandOrange, fontWeight: FontWeight.w900, fontSize: 22)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            decoration: BoxDecoration(color: brandOrange, borderRadius: BorderRadius.circular(15)),
            child: Text("$_secondsRemaining s", style: GoogleFonts.poppins(color: pureWhite, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  void _displayFinalVictory() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: navyDeep,
        // --- تصحيح الخطأ هنا: تم تغيير border إلى side ---
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30), 
          side: const BorderSide(color: brandOrange, width: 2),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.military_tech_rounded, color: brandOrange, size: 90),
            const SizedBox(height: 25),
            Text("تحدي مكتمل!", style: GoogleFonts.cairo(color: pureWhite, fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text("رصيدك زاد بمقدار $_points نقطة", style: GoogleFonts.cairo(color: pureWhite.withOpacity(0.7), fontSize: 17)),
            const SizedBox(height: 35),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // إغلاق النافذة
                  Navigator.pop(context); // العودة للشاشة الرئيسية
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandOrange,
                  padding: const EdgeInsets.all(18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                child: Text("العودة للمنصة", style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: pureWhite, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
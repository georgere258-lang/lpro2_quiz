// PATH: lib/presentation/screens/section_quiz_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/sound_manager.dart';
import '../../features/quizzes/repositories/section_quiz_repository.dart';
import '../../features/quizzes/models/section_quiz_model.dart';
import '../../features/quizzes/models/user_question_record.dart';
import '../widgets/lpro_bottom_nav_bar.dart';
import '../home/widgets/section_identity_card.dart';
import 'main_wrapper.dart';

class SectionQuizScreen extends StatefulWidget {
  final String categoryTitle;

  const SectionQuizScreen({
    super.key,
    required this.categoryTitle,
  });

  @override
  State<SectionQuizScreen> createState() => _SectionQuizScreenState();
}

class _SectionQuizScreenState extends State<SectionQuizScreen>
    with TickerProviderStateMixin {
  final SectionQuizRepository _repository = SectionQuizRepository();
  final Color primaryColor = AppColors.primaryDeepTeal;
  final Color accentColor = AppColors.secondaryOrange;

  static const int _dailyGoal = 5;
  List<SectionQuiz> _sessionQuestions = [];
  final Map<String, bool> _sessionResults = {};
  final Map<int, String?> _userAnswers = {};

  bool _isLoading = true;
  bool _isIntro = true;
  int _currentIndex = 0;
  late Box<UserQuestionRecord> _recordsBox;

  @override
  void initState() {
    super.initState();
    _initAndLoad();
  }

  Future<void> _initAndLoad() async {
    try {
      _recordsBox = await Hive.openBox<UserQuestionRecord>('question_records');
      final allData = await _repository.getQuestions(widget.categoryTitle);

      if (mounted) {
        setState(() {
          allData.shuffle();
          _sessionQuestions = allData.take(_dailyGoal).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildIntroView() {
    final bool isMarket = widget.categoryTitle == "سوق العقار";
    final IconData icon =
        isMarket ? Icons.apartment_rounded : Icons.gavel_rounded;
    final String desc = isMarket
        ? "رحلة شاملة لفهم خريطة الاستثمار العقاري ومكونات السوق المصري."
        : "تمكن من أدواتك القانونية؛ تعلم كيف تقرأ العقود باحترافية وتغلق صفقاتك.";

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        title: Text(
          widget.categoryTitle,
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        foregroundColor: primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      bottomNavigationBar: LProBottomNavBar(
        activeIndex: 1,
        onTap: (index) => Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => MainWrapper(initialIndex: index),
          ),
          (route) => false,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ),
        child: Column(
          children: [
            SectionIdentityCard(
              sectionKey: widget.categoryTitle,
              icon: icon,
              title: widget.categoryTitle,
              description: desc,
              benefits: isMarket
                  ? ["فهم المناطق", "أنواع المطورين", "تحليل السوق"]
                  : ["شرح العقود", "فن الرد", "خطوات الإغلاق"],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 50,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: () {
                if (_sessionQuestions.isNotEmpty) {
                  setState(() => _isIntro = false);
                }
              },
              child: Text(
                _isLoading ? "جاري التجهيز..." : "ابدأ معرفة الآن",
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleAnswer(String answer) {
    if (_userAnswers.containsKey(_currentIndex)) return;
    final currentQ = _sessionQuestions[_currentIndex];
    final isCorrect = answer == currentQ.options[currentQ.correctAnswerIndex];

    setState(() {
      _userAnswers[_currentIndex] = answer;
      _sessionResults[currentQ.id] = isCorrect;
    });

    if (isCorrect) {
      SoundManager.playCorrect();
    } else {
      SoundManager.playWrong();
    }
  }

  Future<void> _commitSessionToHive() async {
    final settingsBox = Hive.box('app_settings');
    int sessionCorrect = 0;

    for (var entry in _sessionResults.entries) {
      final isCorrect = entry.value;
      if (isCorrect) sessionCorrect++;
      final existing = _recordsBox.get(entry.key);

      await _recordsBox.put(
        entry.key,
        UserQuestionRecord(
          questionId: entry.key,
          wasCorrect: isCorrect,
          lastSeen: DateTime.now(),
          timesAnswered: (existing?.timesAnswered ?? 0) + 1,
          dueInDays: isCorrect
              ? _calculateNextInterval(
                  existing?.dueInDays ?? 1,
                  existing?.timesAnswered ?? 0,
                )
              : 1,
        ),
      );
    }

    int totalAt = settingsBox.get(
      'total_attempted_${widget.categoryTitle}',
      defaultValue: 0,
    );
    int totalCo = settingsBox.get(
      'total_correct_${widget.categoryTitle}',
      defaultValue: 0,
    );

    await settingsBox.put(
      'total_attempted_${widget.categoryTitle}',
      totalAt + _sessionResults.length,
    );
    await settingsBox.put(
      'total_correct_${widget.categoryTitle}',
      totalCo + sessionCorrect,
    );
  }

  int _calculateNextInterval(int prev, int times) {
    if (times == 0) return 1;
    if (times == 1) return 3;
    return (prev * 1.8).round().clamp(1, 30);
  }

  void _nextQuestion() {
    if (_currentIndex < _sessionQuestions.length - 1) {
      setState(() => _currentIndex++);
    } else {
      _showResultSheet();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isIntro) return _buildIntroView();
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: primaryColor,
          ),
        ),
      );
    }

    final currentQuestion = _sessionQuestions[_currentIndex];
    final double progress = (_currentIndex + 1) / _sessionQuestions.length;

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        title: Text(
          widget.categoryTitle,
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: Colors.white24,
            valueColor: AlwaysStoppedAnimation<Color>(accentColor),
          ),
        ),
      ),
      bottomNavigationBar: LProBottomNavBar(
        activeIndex: 1,
        onTap: (index) => Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => MainWrapper(initialIndex: index),
          ),
          (route) => false,
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            _buildSessionStatsDecorated(),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              child: _pill(
                icon: Icons.auto_awesome_outlined,
                text: "النقطة المعرفية ${_currentIndex + 1} من $_dailyGoal",
                color: primaryColor,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    _questionCard(
                      child: Text(
                        currentQuestion.question,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15), // ✅ تم تقليل المسافة
                    ...List.generate(
                      currentQuestion.options.length,
                      (i) {
                        final opt = currentQuestion.options[i];
                        final hasAns = _userAnswers.containsKey(_currentIndex);
                        final isCorr = i == currentQuestion.correctAnswerIndex;
                        final isSel = _userAnswers[_currentIndex] == opt;

                        return Padding(
                          padding:
                              const EdgeInsets.only(bottom: 8), // ✅ تقليل الحشو
                          child: GestureDetector(
                            onTap: hasAns ? null : () => _handleAnswer(opt),
                            child: _optionTile(
                              opt,
                              hasAns
                                  ? (isCorr
                                      ? Colors.green.shade600
                                      : (isSel
                                          ? Colors.red.shade600
                                          : Colors.white))
                                  : Colors.white,
                              hasAns && (isCorr || isSel)
                                  ? Colors.white
                                  : primaryColor,
                              isSel,
                            ),
                          ),
                        );
                      },
                    ),
                    if (_userAnswers.containsKey(_currentIndex) &&
                        currentQuestion.explanation != null)
                      _buildExplanation(currentQuestion.explanation!),
                  ],
                ),
              ),
            ),
            _buildNavigationRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionStatsDecorated() {
    int correct = _sessionResults.values.where((v) => v == true).length;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 5),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: primaryColor.withOpacity(0.1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "معدل الإتقان: ",
            style: GoogleFonts.cairo(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            "$correct / ${_userAnswers.length}",
            style: GoogleFonts.cairo(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationRow() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          20, 12, 20, 25), // ✅ تم رفع الأزرار بـ 25 بكسل من الأسفل
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _navButton(
            label: "السابق",
            icon: Icons.arrow_back_ios_new_rounded,
            onPressed: _currentIndex > 0
                ? () => setState(() => _currentIndex--)
                : null,
            isPrimary: false,
          ),
          _navButton(
            label: _currentIndex == _sessionQuestions.length - 1
                ? "إنهاء"
                : "التالي",
            icon: _currentIndex == _sessionQuestions.length - 1
                ? Icons.check_circle_outline
                : Icons.arrow_forward_ios_rounded,
            onPressed:
                _userAnswers.containsKey(_currentIndex) ? _nextQuestion : null,
            isPrimary: true,
            isRightIcon: true,
          ),
        ],
      ),
    );
  }

  Widget _navButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    required bool isPrimary,
    bool isRightIcon = false,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? primaryColor : Colors.grey.shade100,
        foregroundColor: isPrimary ? Colors.white : primaryColor,
        elevation: isPrimary ? 2 : 0,
        minimumSize: const Size(110, 40), // ✅ تم تقليص الارتفاع قليلاً
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isRightIcon) Icon(icon, size: 14),
          if (!isRightIcon) const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          if (isRightIcon) const SizedBox(width: 6),
          if (isRightIcon) Icon(icon, size: 14),
        ],
      ),
    );
  }

  Widget _buildExplanation(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12), // ✅ تقليص المساحة
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.amber.withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.lightbulb_outline,
                  color: Colors.amber,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  "لماذا هذه الإجابة؟",
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.amber.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              text,
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: Colors.grey.shade900,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: color.withOpacity(0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.cairo(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _questionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18), // ✅ تقليص الحشو ليكون أرشق
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: primaryColor.withOpacity(0.6),
          width: 2.2,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _optionTile(String t, Color b, Color f, bool isSel) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 10, // ✅ تقليص الحشو الداخلي
      ),
      decoration: BoxDecoration(
        color: b,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSel ? accentColor : Colors.black.withOpacity(0.06),
          width: isSel ? 2 : 1,
        ),
      ),
      child: Center(
        child: Text(
          t,
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(
            fontSize: 13, // ✅ خط 13 بدلاً من 14 للرشاقة
            fontWeight: FontWeight.bold,
            color: f,
          ),
        ),
      ),
    );
  }

  void _showResultSheet() async {
    await _commitSessionToHive();
    int correct = _sessionResults.values.where((v) => v == true).length;
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 30, vertical: 25), // ✅ تنسيق الحشو
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(30),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.workspace_premium_rounded,
              color: Colors.amber,
              size: 55, // ✅ تصغير الأيقونة
            ),
            const SizedBox(height: 10),
            Text(
              "المعلومه بتفرق - كمل 💪",
              style: GoogleFonts.cairo(
                fontSize: 17, // ✅ تصغير الخط قليلاً
                fontWeight: FontWeight.w900,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              "لقد أتقنت $correct معلومة جديدة اليوم",
              style: GoogleFonts.cairo(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),
            // ✅ تم جعل الزر متناسباً مع حجم النص وليس عرض الشاشة بالكامل
            SizedBox(
              width: 180, // ✅ عرض محدد للزر ليكون أشيك
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: Text(
                  "استمر فى المعرفه",
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class MasterPlanScreen extends StatefulWidget {
  const MasterPlanScreen({super.key});

  @override
  State<MasterPlanScreen> createState() => _MasterPlanScreenState();
}

class _MasterPlanScreenState extends State<MasterPlanScreen> {
  static const Color deepTeal = Color(0xFF1B4D57);
  static const Color safetyOrange = Color(0xFFE67E22);

  // هيكل البيانات المقترح
  final List<Map<String, dynamic>> masterPlanChallenges = [
    {
      "image": "assets/top_brand.png",
      "question": "هذا المخطط يخص أي مشروع في التجمع الخامس؟",
      "options": [
        "ماونتن فيو آي سيتي",
        "بالم هيلز نيو كايرو",
        "ميفيدا",
        "هايد بارك"
      ],
      "answer": "ماونتن فيو آي سيتي",
      "points": 30
    },
    {
      "image": "assets/top_brand.png",
      "question": "المخطط الموضح أمامك يمثل المرحلة الأولى من مشروع:",
      "options": ["زد إيست", "كايرو فيستيفال", "سوان ليك", "تاج سيتي"],
      "answer": "زد إيست",
      "points": 30
    },
  ];

  int currentIndex = 0;
  String? selectedOption;
  bool showFeedback = false;
  int sessionScore = 0;

  void _handleAnswer(String selected, String correctAnswer, int points) {
    if (showFeedback) return;

    bool isCorrect = selected == correctAnswer;
    if (isCorrect) {
      HapticFeedback.mediumImpact();
      sessionScore += points;
    } else {
      HapticFeedback.heavyImpact();
    }

    setState(() {
      selectedOption = selected;
      showFeedback = true;
    });

    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        if (currentIndex < masterPlanChallenges.length - 1) {
          setState(() {
            currentIndex++;
            showFeedback = false;
            selectedOption = null;
          });
        } else {
          _finishChallenge();
        }
      }
    });
  }

  Future<void> _finishChallenge() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && sessionScore > 0) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'points': FieldValue.increment(sessionScore),
      });
    }
    _showFinalResult();
  }

  void _showFinalResult() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.map_outlined, size: 70, color: Colors.green),
            const SizedBox(height: 15),
            Text("عبقري الخرائط! 🗺️",
                style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: deepTeal)),
            Text("لقد حللت المخططات بنجاح وتستحق النقاط",
                style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 20),
            Text("+$sessionScore",
                style: GoogleFonts.poppins(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: safetyOrange)),
            const SizedBox(height: 25),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: deepTeal,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15))),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: Text("العودة للرئيسية",
                  style: GoogleFonts.cairo(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var currentChallenge = masterPlanChallenges[currentIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: deepTeal,
        elevation: 0,
        centerTitle: true,
        title: Text("تحدي الماستر بلان",
            style: GoogleFonts.cairo(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        leading: const BackButton(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (currentIndex + 1) / masterPlanChallenges.length,
              backgroundColor: Colors.grey[200],
              color: safetyOrange,
              minHeight: 6,
            ),
            Container(
              padding: const EdgeInsets.all(15),
              width: double.infinity,
              color: deepTeal.withOpacity(0.05),
              child: Text(
                "سؤال ${currentIndex + 1} من ${masterPlanChallenges.length}: حلل المخطط بدقة",
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                    color: deepTeal, fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 15,
                          offset: const Offset(0, 5))
                    ],
                    border: Border.all(color: Colors.white, width: 2)),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(25)),
                      child: Container(
                        height: 320,
                        width: double.infinity,
                        color: Colors.white,
                        child: InteractiveViewer(
                          panEnabled: true,
                          minScale: 1.0,
                          maxScale: 5.0,
                          child: Image.asset(
                            currentChallenge['image'],
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Center(
                                    child: Icon(Icons.image_not_supported,
                                        size: 50, color: Colors.grey)),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(18),
                      width: double.infinity,
                      decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(25))),
                      child: Text(
                        currentChallenge['question'],
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: deepTeal,
                            height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 25),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                children: currentChallenge['options'].map<Widget>((option) {
                  return _buildOption(option, currentChallenge['answer'],
                      currentChallenge['points']);
                }).toList(),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(String text, String correctAnswer, int points) {
    bool isCorrect = showFeedback && text == correctAnswer;
    bool isWrong =
        showFeedback && text == selectedOption && text != correctAnswer;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _handleAnswer(text, correctAnswer, points),
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          decoration: BoxDecoration(
            color: isCorrect
                ? Colors.green.shade500
                : (isWrong ? Colors.red.shade400 : Colors.white),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
                color: isCorrect || isWrong
                    ? Colors.transparent
                    : Colors.grey.shade200),
            boxShadow: isCorrect || isWrong
                ? [
                    BoxShadow(
                        color: (isCorrect ? Colors.green : Colors.red)
                            .withOpacity(0.3),
                        blurRadius: 10)
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                text,
                style: GoogleFonts.cairo(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: (isCorrect || isWrong) ? Colors.white : deepTeal),
              ),
              if (isCorrect)
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
              if (isWrong)
                const Icon(Icons.cancel, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

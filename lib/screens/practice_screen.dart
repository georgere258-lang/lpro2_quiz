import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  // --- ميثاق ألوان باكدج 3 المعتمد (LPro Deep Teal) ---
  static const Color deepTeal = Color(0xFF005F6B);     // اللون القائد
  static const Color safetyOrange = Color(0xFFFF8C00); // لون التحفيز (المثلث والأكشن)
  static const Color iceWhite = Color(0xFFF8F9FA);     // الخلفية الأساسية
  static const Color darkTealText = Color(0xFF002D33); // نصوص العناوين

  int currentQuestionIndex = 0;
  int? selectedAnswerIndex;
  bool isCorrect = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: iceWhite,
      appBar: AppBar(
        title: Text("تنشيط المعلومات", style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: darkTealText,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('quizzes').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: deepTeal));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("لا توجد أسئلة للمراجعة حالياً", style: GoogleFonts.cairo()));
          }

          final questions = snapshot.data!.docs;
          final currentQuestion = questions[currentQuestionIndex].data() as Map<String, dynamic>;
          final List options = currentQuestion['options'] ?? [];

          return Padding(
            padding: const EdgeInsets.all(25.0),
            child: Column(
              children: [
                // [المطلوب]: الجملة التحفيزية لوضع المراجعة
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lightbulb_outline, color: safetyOrange, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "وضع المراجعة (بدون نقاط) 💡",
                      style: GoogleFonts.cairo(color: deepTeal, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                
                // كارت السؤال الفخم
                Container(
                  padding: const EdgeInsets.all(30),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: deepTeal.withOpacity(0.05), 
                        blurRadius: 15, 
                        offset: const Offset(0, 8)
                      )
                    ],
                    border: Border.all(color: deepTeal.withOpacity(0.05)),
                  ),
                  child: Text(
                    currentQuestion['question'] ?? "",
                    style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: darkTealText, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 35),
                
                // قائمة الإجابات التفاعلية
                ...List.generate(options.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(20),
                          backgroundColor: _getButtonColor(index, currentQuestion['answerIndex']),
                          elevation: 0,
                          side: BorderSide(
                            color: _getBorderColor(index, currentQuestion['answerIndex']), 
                            width: 1.5
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        onPressed: selectedAnswerIndex != null ? null : () {
                          setState(() {
                            selectedAnswerIndex = index;
                            isCorrect = (index == currentQuestion['answerIndex']);
                          });
                        },
                        child: Text(
                          options[index], 
                          style: GoogleFonts.cairo(
                            fontSize: 16, 
                            fontWeight: FontWeight.w600,
                            color: selectedAnswerIndex != null && index == currentQuestion['answerIndex'] 
                                ? deepTeal : darkTealText
                          )
                        ),
                      ),
                    ),
                  );
                }),
                const Spacer(),
                
                // زر السؤال التالي بأسلوب باكدج 3
                if (selectedAnswerIndex != null)
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: deepTeal,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      onPressed: () {
                        setState(() {
                          if (currentQuestionIndex < questions.length - 1) {
                            currentQuestionIndex++;
                            selectedAnswerIndex = null;
                          } else {
                            Navigator.pop(context);
                          }
                        });
                      },
                      child: Text(
                        currentQuestionIndex < questions.length - 1 ? "السؤال التالي" : "إنهاء المراجعة", 
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getButtonColor(int index, int correctIndex) {
    if (selectedAnswerIndex == null) return Colors.white;
    if (index == correctIndex) return const Color(0xFFE8F5E9); // أخضر للنجاح
    if (index == selectedAnswerIndex && index != correctIndex) return const Color(0xFFFFEBEE); // أحمر للخطأ
    return Colors.white;
  }

  Color _getBorderColor(int index, int correctIndex) {
    if (selectedAnswerIndex == null) return deepTeal.withOpacity(0.1);
    if (index == correctIndex) return Colors.green;
    if (index == selectedAnswerIndex && index != correctIndex) return Colors.redAccent;
    return deepTeal.withOpacity(0.05);
  }
}
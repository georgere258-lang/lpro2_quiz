import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  int currentQuestionIndex = 0;
  int? selectedAnswerIndex;
  bool isCorrect = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F9),
      appBar: AppBar(
        title: const Text("تنشيط المعلومات", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF102A43),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // سنستخدم نفس مجموعة الأسئلة ولكن بمنطق مختلف
        stream: FirebaseFirestore.instance.collection('quizzes').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("لا توجد أسئلة للمراجعة حالياً"));
          }

          final questions = snapshot.data!.docs;
          final currentQuestion = questions[currentQuestionIndex].data() as Map<String, dynamic>;
          final List options = currentQuestion['options'] ?? [];

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const Text(
                  "وضع المراجعة (بدون نقاط) 💡",
                  style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                // كارت السؤال
                Container(
                  padding: const EdgeInsets.all(25),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                  ),
                  child: Text(
                    currentQuestion['question'] ?? "",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 30),
                // قائمة الإجابات
                ...List.generate(options.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(18),
                          backgroundColor: _getButtonColor(index, currentQuestion['answerIndex']),
                          foregroundColor: const Color(0xFF102A43),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                            side: const BorderSide(color: Colors.white, width: 2),
                          ),
                        ),
                        onPressed: selectedAnswerIndex != null ? null : () {
                          setState(() {
                            selectedAnswerIndex = index;
                            isCorrect = (index == currentQuestion['answerIndex']);
                          });
                        },
                        child: Text(options[index], style: const TextStyle(fontSize: 16)),
                      ),
                    ),
                  );
                }),
                const Spacer(),
                // زر السؤال التالي
                if (selectedAnswerIndex != null)
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF102A43),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
                      child: const Text("السؤال التالي", style: TextStyle(color: Colors.white)),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // دالة لتحديد لون الزر بناءً على الإجابة
  Color _getButtonColor(int index, int correctIndex) {
    if (selectedAnswerIndex == null) return Colors.white;
    if (index == correctIndex) return Colors.green.shade100;
    if (index == selectedAnswerIndex && index != correctIndex) return Colors.red.shade100;
    return Colors.white;
  }
}
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int currentQuestionIndex = 0;
  int score = 0;
  bool isFinished = false;

  // دالة تحديد المسمى التحفيزي بناءً على النقاط
  String _determineLevel(int totalPoints) {
    if (totalPoints >= 1500) return "👑 الإمبراطور";
    if (totalPoints >= 700) return "🔥 الأسطوري";
    if (totalPoints >= 300) return "💎 المتألق";
    if (totalPoints >= 100) return "🚀 المحلق";
    return "⚡ المنطلق";
  }

  // تحديث نقاط المستخدم ومستواه في Firebase
  Future<void> _updateUserPointsAndLevel(int pointsToAdd) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final snapshot = await userDoc.get();
    
    int currentPoints = 0;
    if (snapshot.exists) {
      currentPoints = (snapshot.data() as Map<String, dynamic>)['points'] ?? 0;
    }

    int newTotal = currentPoints + pointsToAdd;
    String newLevel = _determineLevel(newTotal);

    await userDoc.update({
      'points': newTotal,
      'level': newLevel,
    });
  }

  // نافذة لوحة الشرف (تفتح عند الضغط على الأيقونة في الـ AppBar)
  void _showLeaderboard(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 15),
            Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            const Text("🏆 متصدري الدوري العقاري", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF102A43))),
            const SizedBox(height: 15),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .orderBy('points', descending: true)
                    .limit(20)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  
                  final topUsers = snapshot.data!.docs;
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    itemCount: topUsers.length,
                    itemBuilder: (context, index) {
                      var userData = topUsers[index].data() as Map<String, dynamic>;
                      bool isTopThree = index < 3;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: isTopThree ? _getPodiumColor(index).withOpacity(0.1) : Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: isTopThree ? Border.all(color: _getPodiumColor(index), width: 1.5) : Border.all(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          leading: _buildRankBadge(index),
                          title: Text(userData['name'] ?? "مشارك", style: TextStyle(fontWeight: isTopThree ? FontWeight.bold : FontWeight.normal)),
                          subtitle: Text(userData['level'] ?? "⚡ المنطلق", style: const TextStyle(fontSize: 12)),
                          trailing: Text("${userData['points']} pts", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF102A43))),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankBadge(int index) {
    if (index == 0) return const Icon(Icons.workspace_premium, color: Color(0xFFFFD700), size: 32);
    if (index == 1) return const Icon(Icons.workspace_premium, color: Color(0xFFC0C0C0), size: 28);
    if (index == 2) return const Icon(Icons.workspace_premium, color: Color(0xFFCD7F32), size: 26);
    return CircleAvatar(backgroundColor: Colors.grey[100], radius: 14, child: Text("${index + 1}", style: const TextStyle(fontSize: 12, color: Colors.black54)));
  }

  Color _getPodiumColor(int index) {
    if (index == 0) return const Color(0xFFFFD700);
    if (index == 1) return const Color(0xFFC0C0C0);
    if (index == 2) return const Color(0xFFCD7F32);
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F9),
      appBar: AppBar(
        title: const Text("الدوري العقاري 🏆", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF102A43),
        elevation: 0,
        actions: [
          // هذا هو الزر الذي طلبته لإظهار لوحة الشرف
          IconButton(
            icon: const Icon(Icons.leaderboard_rounded, color: Color(0xFFD68A1A), size: 28),
            onPressed: () => _showLeaderboard(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('quizzes').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("لا توجد أسئلة حالياً"));

          final questions = snapshot.data!.docs;
          if (isFinished) return _buildResultScreen();

          final currentQuestion = questions[currentQuestionIndex].data() as Map<String, dynamic>;
          final List options = currentQuestion['options'] ?? [];

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LinearProgressIndicator(
                  value: (currentQuestionIndex + 1) / questions.length, 
                  color: const Color(0xFFD68A1A),
                  backgroundColor: Colors.orange.withOpacity(0.1),
                ),
                const SizedBox(height: 30),
                Text("السؤال ${currentQuestionIndex + 1} من ${questions.length}", textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white, 
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                  ),
                  child: Text(
                    currentQuestion['question'] ?? "", 
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), 
                    textAlign: TextAlign.center
                  ),
                ),
                const SizedBox(height: 30),
                ...List.generate(options.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(18),
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF102A43),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 2,
                      ),
                      onPressed: () {
                        if (index == currentQuestion['answerIndex']) score += 10;
                        setState(() {
                          if (currentQuestionIndex < questions.length - 1) {
                            currentQuestionIndex++;
                          } else {
                            isFinished = true;
                            _updateUserPointsAndLevel(score);
                          }
                        });
                      },
                      child: Text(options[index], style: const TextStyle(fontSize: 16)),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.stars_rounded, size: 120, color: Colors.amber),
            const SizedBox(height: 20),
            const Text("مجهود رائع!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("لقد أضفت $score نقطة إلى رصيدك", style: const TextStyle(fontSize: 18, color: Colors.blueGrey)),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF102A43), 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text("العودة للرئيسية", style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color deepTeal = Color(0xFF1B4D57);
    const Color safetyOrange = Color(0xFFE67E22);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Text("صباح التميز يا وحش السوق 🚀", style: GoogleFonts.cairo(color: deepTeal, fontWeight: FontWeight.bold, fontSize: 18))),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [deepTeal, Color(0xFF00333D)]), borderRadius: BorderRadius.circular(25)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("أهلاً مريم،", style: GoogleFonts.cairo(color: Colors.white70)),
                  Text("وحش العقارات 🦁", style: GoogleFonts.cairo(color: safetyOrange, fontWeight: FontWeight.bold, fontSize: 22)),
                ]),
                const Icon(Icons.workspace_premium, color: safetyOrange, size: 50),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Text("إيه رأيك نعمل ده النهاردة؟ ✨", style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18, color: deepTeal)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)], border: const Border(right: BorderSide(color: safetyOrange, width: 5))),
            child: Row(
              children: [
                const CircleAvatar(backgroundColor: Color(0xFFFFF3E0), child: Icon(Icons.lightbulb_outline, color: safetyOrange)),
                const SizedBox(width: 15),
                Expanded(child: Text("ندردش مع 5 عملاء جدد في التجمع؟ خطوة بسيطة هتفرق جداً في ترتيبك في الدوري!", style: GoogleFonts.cairo(fontWeight: FontWeight.w600, fontSize: 14))),
              ],
            ),
          ),
          const SizedBox(height: 30),
          GridView.count(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2, mainAxisSpacing: 15, crossAxisSpacing: 15,
            children: [
              _card("سوق اليوم", Icons.analytics, Colors.blue),
              _card("أكاديمية LPro", Icons.school, Colors.purple),
              _card("مجتمع الوحوش", Icons.groups, Colors.green),
              _card("الدعم الفني", Icons.support_agent, Colors.red),
            ],
          )
        ],
      ),
    );
  }

  Widget _card(String t, IconData i, Color c) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(i, color: c, size: 35), const SizedBox(height: 10), Text(t, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13))]),
  );
}
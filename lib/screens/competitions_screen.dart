import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// استيراد الملفات الموجودة عندك بالفعل
import 'master_plan_screen.dart';
import 'quiz_screen.dart';

class CompetitionsScreen extends StatelessWidget {
  const CompetitionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ألوان LPro الرسمية
    const Color deepTeal = Color(0xFF1B4D57);
    const Color safetyOrange = Color(0xFFE67E22);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text("ساحة التحدي", style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: deepTeal,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- قسم الدوري العقاري (كامل العرض) ---
            _buildHeader("الدوري العقاري", Icons.Emoji_events_outlined, deepTeal),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildCompactCard(context, "دوري المحترفين", Icons.workspace_premium, safetyOrange, const QuizScreen()),
                const SizedBox(width: 12),
                _buildCompactCard(context, "دوري المميزين", Icons.star_border_rounded, Colors.blueGrey, const QuizScreen()),
              ],
            ),

            const SizedBox(height: 25),

            // --- الأقسام المستقلة (جنباً إلى جنب) ---
            _buildHeader("التحديات المتخصصة", Icons.extension_outlined, deepTeal),
            const SizedBox(height: 12),
            Row(
              children: [
                // كارت الماستر بلان مستقل
                _buildSquareSection(
                  context, 
                  "تحدي\nالماستر بلان", 
                  Icons.map_outlined, 
                  deepTeal, 
                  const MasterPlanScreen()
                ),
                const SizedBox(width: 12),
                // كارت نشط ذهنك مستقل
                _buildSquareSection(
                  context, 
                  "نشط\nذهنك", 
                  Icons.psychology_outlined, 
                  Colors.purple[700]!, 
                  const QuizScreen() // سنغيره لاحقاً لملف نشط ذهنك
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // مخصص للعناوين الجانبية
  Widget _buildHeader(String title, IconData icon, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(title, style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(width: 8),
        Icon(icon, color: color, size: 24),
      ],
    );
  }

  // كروت الدوري العقاري
  Widget _buildCompactCard(BuildContext context, String title, IconData icon, Color color, Widget destination) {
    return Expanded(
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => destination)),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 30),
              Text(title, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  // كروت الماستر بلان ونشط ذهنك (مستقلة وكبيرة)
  Widget _buildSquareSection(BuildContext context, String title, IconData icon, Color color, Widget destination) {
    return Expanded(
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => destination)),
        child: Container(
          height: 160,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 45),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, height: 1.2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
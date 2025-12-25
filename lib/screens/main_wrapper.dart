import 'package:flutter/material.dart';
import 'developers_screen.dart';
import 'master_plan_screen.dart';
import 'profile_screen.dart';

class MainWrapper extends StatelessWidget {
  const MainWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    const Color brandOrange = Color(0xFFFF8C42);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("LPro Real Estate", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite, color: Colors.redAccent), 
            onPressed: () {}
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // البانر المحدث: اتعلم L -> اتطور (مثلث قاعدته يسار ورأسه يمين) -> PRO
            _buildFeaturedBanner(brandOrange),

            Padding(
              padding: const EdgeInsets.all(15.0),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 1.1,
                children: [
                  _menuCard(context, "المطورين", Icons.business_outlined, brandOrange, const DevelopersScreen()),
                  _menuCard(context, "MASTER PLAN", Icons.map_rounded, brandOrange, const MasterPlanScreen()),
                  _menuCard(context, "الدوري العقاري", Icons.emoji_events, Colors.amber, null),
                  _menuCard(context, "نشط ذهنك العقاري", Icons.psychology, Colors.lightBlueAccent, null),
                  _menuCard(context, "سابقة أعمال الشركات", Icons.history_edu_rounded, Colors.greenAccent, null),
                  _menuCard(context, "المفضلة", Icons.favorite, Colors.redAccent, null),
                  _menuCard(context, "النقاط والجوائز", Icons.stars, brandOrange, const ProfileScreen()),
                  _menuCard(context, "الملف الشخصي", Icons.person_outline, brandOrange, const ProfileScreen()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedBanner(Color color) {
    return Container(
      margin: const EdgeInsets.all(15),
      height: 180, 
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B3358), Color(0xFF2A4B7C)],
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // اتعلم + L
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    const Text("اتعلم", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 5),
                    Text("L", style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w900)),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 14),
                ),
                // اتطور وفوقها رأس مثلث (قاعدته شمال ورأسه يمين باتجاه PRO)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // الالتفاف ليكون الرأس لليمين تماماً
                    const Icon(Icons.play_arrow, color: Color(0xFFFF8C42), size: 24), 
                    const Text("اتطور", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 14),
                ),
                // PRO
                Text("PRO", style: TextStyle(color: color, fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: 2)),
              ],
            ),
            const SizedBox(height: 15),
            const Text(
              "كن شريكاً في النجاح LPro", 
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuCard(BuildContext context, String title, IconData icon, Color color, Widget? screen) {
    return InkWell(
      onTap: () {
        if (screen != null) {
          Navigator.push(context, MaterialPageRoute(builder: (c) => screen));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("هذا القسم قيد التطوير حالياً..."))
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1B3358),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 35, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title, 
              textAlign: TextAlign.center, 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)
            ),
          ],
        ),
      ),
    );
  }
}
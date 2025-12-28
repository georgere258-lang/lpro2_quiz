import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RealEstateLeague extends StatefulWidget {
  const RealEstateLeague({super.key});
  @override
  State<RealEstateLeague> createState() => _RealEstateLeagueState();
}

class _RealEstateLeagueState extends State<RealEstateLeague> {
  // --- ميثاق ألوان باكدج 3 المعتمد (LPro Deep Teal) ---
  static const Color deepTeal = Color(0xFF005F6B);     // فيروزي عميق (القائد)
  static const Color lightTeal = Color(0xFF003D45);    // تدرج السبلاش
  static const Color safetyOrange = Color(0xFFFF8C00); // برتقالي ساطع (المثلث)
  static const Color iceWhite = Color(0xFFF8F9FA);     // أبيض ثلجي
  static const Color darkTealText = Color(0xFF002D33); // نصوص داكنة
  static const Color silverMedal = Color(0xFFC0C0C0); 
  static const Color bronzeMedal = Color(0xFFCD7F32);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // [تثبيت]: الخلفية العلوية بتدرج السبلاش سكرين المعتمد
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [deepTeal, lightTeal],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 50),
            _buildCustomAppBar(),
            const SizedBox(height: 20),
            _buildPodium(),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 30),
                decoration: const BoxDecoration(
                  color: iceWhite, 
                  borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, -5))]
                ),
                child: _buildRankings(),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Text(
            "دوري وحوش العقارات", 
            style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)
          ),
          const SizedBox(height: 5),
          // [المطلوب]: الجملة التحفيزية
          Text(
            "مريم، أنتِ على بُعد 150 نقطة من المركز الأول! 🔥", 
            style: GoogleFonts.cairo(color: safetyOrange, fontWeight: FontWeight.bold, fontSize: 12)
          ),
        ],
      ),
    );
  }

  Widget _buildPodium() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _pillar("سارة", 110, silverMedal, "2"),
        const SizedBox(width: 15),
        // [تثبيت]: المركز الأول بلون المثلث البرتقالي
        _pillar("أحمد", 150, safetyOrange, "1"), 
        const SizedBox(width: 15),
        _pillar("مريم", 90, bronzeMedal, "3"),
      ],
    );
  }

  Widget _pillar(String n, double h, Color c, String r) => Column(
    children: [
      Text(r, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
      const SizedBox(height: 5),
      CircleAvatar(
        backgroundColor: Colors.white.withOpacity(0.15), 
        radius: 28, 
        child: Text(
          n[0], 
          style: GoogleFonts.cairo(
            color: c == safetyOrange ? safetyOrange : Colors.white, 
            fontWeight: FontWeight.w900,
            fontSize: 20
          )
        )
      ),
      const SizedBox(height: 12),
      Container(
        width: 75, height: h, 
        decoration: BoxDecoration(
          color: c, 
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(color: c.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, -2))
          ],
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [c, c.withOpacity(0.8)],
          )
        ),
        child: Center(
          child: r == "1" ? const Icon(Icons.workspace_premium, color: Colors.white, size: 30) : null,
        ),
      ),
      const SizedBox(height: 8),
      Text(n, style: GoogleFonts.cairo(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
    ],
  );

  Widget _buildRankings() => ListView.builder(
    padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
    itemCount: 10,
    itemBuilder: (context, i) => Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: deepTeal.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 6))
        ]
      ),
      child: Row(children: [
        Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(color: iceWhite, shape: BoxShape.circle),
          child: Center(
            child: Text("${i + 4}", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: darkTealText)),
          ),
        ),
        const SizedBox(width: 15),
        Text(
          "وحش عقاري صاعد ${i + 4}", 
          style: GoogleFonts.cairo(color: darkTealText, fontWeight: FontWeight.w600, fontSize: 14)
        ),
        const Spacer(),
        // عرض النقاط بلمحة فيروزية
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(color: deepTeal.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
          child: Text(
            "${2100 - (i * 100)} ن", 
            style: GoogleFonts.cairo(color: deepTeal, fontWeight: FontWeight.w900, fontSize: 13)
          ),
        ),
      ]),
    ),
  );
}
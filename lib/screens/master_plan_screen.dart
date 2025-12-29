import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MasterPlanScreen extends StatelessWidget {
  const MasterPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color deepTeal = Color(0xFF1B4D57);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: deepTeal,
        title: Text("الماستر بلان", style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        leading: const BackButton(color: Colors.white),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, size: 80, color: deepTeal.withOpacity(0.3)),
            const SizedBox(height: 20),
            Text(
              "قريباً.. خرائط المشاريع الجديدة",
              style: GoogleFonts.cairo(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

class AdminPanel extends StatelessWidget {
  const AdminPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController controller = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text("لوحة التحكم"),
        backgroundColor: AppColors.primaryDeepTeal,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: controller,
              maxLines: 4,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: "اكتب معلومة Pro...",
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondaryOrange,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () async {
                  final text = controller.text.trim();
                  if (text.isEmpty) return;

                  await FirebaseFirestore.instance
                      .collection('home_pro_card')
                      .doc('current')
                      .set({
                    'text': text,
                    'isActive': true,
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
                },
                child: Text(
                  "نشر فوري",
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
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

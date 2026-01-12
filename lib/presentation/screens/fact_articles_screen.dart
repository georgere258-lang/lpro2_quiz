import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FactArticlesScreen extends StatelessWidget {
  final String title;

  const FactArticlesScreen({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Text(
            'هنا سيتم عرض المحتوى القوي:\n\n'
            '- خبرة عملية\n'
            '- ملخص كتب\n'
            '- مواقف حقيقية من السوق\n\n'
            'الهدف: تغيير طريقة تفكيرك مش حشو معلومات.',
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.7,
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/sound_manager.dart';

class EventDetailsScreen extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final String actionLabel;
  final VoidCallback onActionPressed;

  const EventDetailsScreen({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.actionLabel,
    required this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF1B4D57)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "تفاصيل الفعالية",
          style: GoogleFonts.cairo(
            color: const Color(0xFF1B4D57),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // 1. Icon Header (بلمسة ذهبية ولؤلؤية)
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD4AF37).withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(icon, size: 60, color: AppColors.secondaryOrange),
              ),
              const SizedBox(height: 32),

              // 2. Title
              Text(
                title,
                style: GoogleFonts.cairo(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1B4D57),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // 3. Divider
              Container(
                width: 60,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // 4. Description Box
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: AppColors.eliteShadowL1,
                ),
                child: Text(
                  description,
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    height: 1.8,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.justify,
                ),
              ),
              const SizedBox(height: 40),

              // 5. Action Button
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () {
                    SoundManager.playTap();
                    onActionPressed();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDeepTeal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 5,
                  ),
                  child: Text(
                    actionLabel,
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

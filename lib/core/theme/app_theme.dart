import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// استيراد الألوان - تأكدي من صحة المسار
import '../constants/app_colors.dart';

class LproTheme {
  static const Color deepTeal = AppColors.primaryDeepTeal;
  static const Color safetyOrange = AppColors.secondaryOrange;
  static const Color iceWhite = AppColors.scaffoldBackground;
  static const Color darkTealText = AppColors.textMain;
  static const Color bodyGray = AppColors.textSecondary;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.cairo().fontFamily,

      colorScheme: ColorScheme.fromSeed(
        seedColor: deepTeal,
        primary: deepTeal,
        onPrimary: Colors.white,
        secondary: safetyOrange,
        onSecondary: Colors.white,
        surface: Colors.white,
        error: Colors.redAccent,
      ),

      scaffoldBackgroundColor: iceWhite,

      appBarTheme: AppBarTheme(
        backgroundColor: deepTeal,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        titleTextStyle: GoogleFonts.cairo(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white, size: 22),
      ),

      // تم التصحيح هنا: استخدام CardThemeData بدلاً من CardTheme
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),

      // تم التصحيح هنا: استخدام TabBarThemeData بدلاً من TabBarTheme
      tabBarTheme: TabBarThemeData(
        labelColor: safetyOrange,
        unselectedLabelColor: Colors.grey,
        labelStyle:
            GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: safetyOrange,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          textStyle:
              GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),

      textTheme: TextTheme(
        displayLarge:
            GoogleFonts.cairo(color: darkTealText, fontWeight: FontWeight.bold),
        displayMedium: GoogleFonts.cairo(
            color: darkTealText, fontWeight: FontWeight.bold, fontSize: 18),
        bodyLarge: GoogleFonts.cairo(
            color: darkTealText, fontSize: 16, fontWeight: FontWeight.w500),
        bodyMedium: GoogleFonts.cairo(color: bodyGray, fontSize: 14),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: deepTeal.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: deepTeal.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: deepTeal, width: 1.5),
        ),
      ),
    );
  }
}

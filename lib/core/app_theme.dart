import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LproTheme {
  // --- ميثاق ألوان باكدج 3 المعتمد (LPro Deep Teal) ---
  static const Color deepTeal = Color(0xFF005F6B);     // اللون القائد (30%)
  static const Color safetyOrange = Color(0xFFFF8C00); // لون الأكشن والمثلث (10%)
  static const Color iceWhite = Color(0xFFF8F9FA);     // الخلفية الأساسية (60%)
  static const Color darkTealText = Color(0xFF002D33); // نصوص العناوين
  static const Color bodyGray = Color(0xFF4A4A4A);     // نصوص المحتوى

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.cairo().fontFamily,
      
      colorScheme: ColorScheme.fromSeed(
        seedColor: deepTeal,
        primary: deepTeal,
        secondary: safetyOrange, // البرتقالي الأساسي للمثلث والتميز
        surface: Colors.white,
        background: iceWhite,
      ),

      scaffoldBackgroundColor: iceWhite,

      appBarTheme: const AppBarTheme(
        backgroundColor: deepTeal,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.bold, 
          fontSize: 20,
          fontFamily: 'Cairo',
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: safetyOrange,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),

      textTheme: const TextTheme(
        displayLarge: TextStyle(color: darkTealText, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: darkTealText, fontWeight: FontWeight.bold, fontSize: 18),
        bodyLarge: TextStyle(color: bodyGray, fontSize: 16),
        bodyMedium: TextStyle(color: bodyGray, fontSize: 14),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
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
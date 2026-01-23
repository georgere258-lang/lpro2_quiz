// PATH: lib/core/constants/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // =========================
  // Core Brand Colors (L Pro)
  // =========================
  static const Color primaryDeepTeal = Color(0xFF1B4D57);
  static const Color secondaryOrange = Color(0xFFE67E22);

  // =========================
  // Backgrounds
  // =========================
  static const Color scaffoldBackground = Color(0xFFF4F7F8);
  static const Color cardWhite = Colors.white;

  // =========================
  // Text
  // =========================
  static const Color textMain = Color(0xFF1B4D57);
  static const Color textSecondary = Color(0xFF7F8C8D);

  // ==========================================================
  // Elite Shadow Utility
  // Light source: Top-Center
  // Signature: Teal-tinted shadows + layered realism
  // ==========================================================

  static const double _shadowAlphaL1 = 0.06;
  static const double _shadowAlphaL2 = 0.08;
  static const double _shadowAlphaL3 = 0.10;

  static Color _shadowTint([double a = 0.08]) => primaryDeepTeal.withValues(alpha: a);

  /// L1: wide cards (Radar/Economy) — soft, low elevation
  static List<BoxShadow> get eliteShadowL1 => [
        BoxShadow(
          color: _shadowTint(_shadowAlphaL1),
          blurRadius: 10,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
      ];

  /// L2: grid cards + ticker containers — medium elevation with layered realism
  static List<BoxShadow> get eliteShadowL2 => [
        BoxShadow(
          color: _shadowTint(_shadowAlphaL2),
          blurRadius: 15,
          spreadRadius: 0,
          offset: const Offset(0, 6),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.02),
          blurRadius: 4,
          spreadRadius: 0,
          offset: const Offset(0, 1),
        ),
      ];

  /// L3: welcome card + interactive profile buttons — floating feel (deeper, more spread)
  static List<BoxShadow> get eliteShadowL3 => [
        BoxShadow(
          color: _shadowTint(_shadowAlphaL3),
          blurRadius: 25,
          spreadRadius: 0,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 6,
          spreadRadius: 0,
          offset: const Offset(0, 2),
        ),
      ];

  /// Rim Glow for active/important elements (subtle, colored)
  /// Use: boxShadow: [...AppColors.eliteShadowL2, ...AppColors.rimGlowOrange]
  static List<BoxShadow> rimGlow(
    Color color, {
    double alpha = 0.14,
    double blur = 18,
    double spread = 1,
  }) {
    return [
      BoxShadow(
        color: color.withValues(alpha: alpha),
        blurRadius: blur,
        spreadRadius: spread,
        offset: const Offset(0, 0),
      ),
    ];
  }

  // Prebuilt glows (semantic)
  static List<BoxShadow> get rimGlowOrange =>
      rimGlow(secondaryOrange, alpha: 0.16, blur: 18, spread: 1);

  static List<BoxShadow> get rimGlowTeal =>
      rimGlow(primaryDeepTeal, alpha: 0.12, blur: 18, spread: 1);

  static List<BoxShadow> get rimGlowBlue =>
      rimGlow(const Color(0xFF3498DB), alpha: 0.14, blur: 18, spread: 1);

  static List<BoxShadow> get rimGlowPurple =>
      rimGlow(const Color(0xFF9B59B6), alpha: 0.14, blur: 18, spread: 1);

  static List<BoxShadow> get rimGlowGreen =>
      rimGlow(const Color(0xFF2ECC71), alpha: 0.14, blur: 18, spread: 1);
}

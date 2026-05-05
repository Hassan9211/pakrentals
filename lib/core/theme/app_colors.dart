import 'package:flutter/material.dart';

class AppColors {
  // Background
  static const Color background = Color(0xFF0A0A0F);
  static const Color surface = Color(0xFF12121A);
  static const Color surfaceVariant = Color(0xFF1A1A28);
  static const Color card = Color(0xFF16162A);

  // Neon Accents
  static const Color neonCyan = Color(0xFF00F5FF);
  static const Color neonViolet = Color(0xFF8B5CF6);
  static const Color neonPink = Color(0xFFEC4899);
  static const Color neonGreen = Color(0xFF10B981);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0C8);
  static const Color textMuted = Color(0xFF6B6B8A);

  // Borders
  static const Color border = Color(0xFF2A2A3E);
  static const Color borderGlow = Color(0xff00f5ff40);

  // Status
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [neonCyan, neonViolet],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF0A0A0F), Color(0xFF1A0A2E), Color(0xFF0A0A0F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cyanVioletGradient = LinearGradient(
    colors: [neonCyan, neonViolet, neonPink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

import 'package:flutter/material.dart';

class AppColors {
  // Background layers
  static const Color background = Color(0xFF0B0F14);
  static const Color surface = Color(0xFF151A23);
  static const Color surfaceVariant = Color(0xFF1C2333);
  static const Color surfaceElevated = Color(0xFF202840);

  // Primary (dark purple, replacing the original dark blue)
  static const Color primary = Color(0xFF8B5FBF);
  static const Color primaryLight = Color(0xFFA87FD4);
  static const Color primaryDark = Color(0xFF6D3FA0);

  // Semantic
  static const Color green = Color(0xFF42D392);
  static const Color orange = Color(0xFFFFB84D);
  static const Color red = Color(0xFFFF6B6B);
  static const Color purple = Color(0xFF9B8FFF);
  static const Color teal = Color(0xFF4DCCBD);

  // Text
  static const Color textPrimary = Color(0xFFF5F7FA);
  static const Color textSecondary = Color(0xFFA6B0C3);
  static const Color textMuted = Color(0xFF6E7787);
  static const Color textDisabled = Color(0xFF3D4555);

  // Border
  static const Color border = Color(0xFF1E2A3A);
  static const Color borderLight = Color(0xFF253042);

  // Glass — used by the editable liquid-glass note on the dashboard
  static const Color glassBg = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x26FFFFFF);

  // Overlay
  static const Color overlay = Color(0x80000000);

  // Progress track
  static const Color progressTrack = Color(0xFF1C2333);

  // Sidebar
  static const Color sidebarBackground = Color(0xFF151A23);
  static const Color sidebarSelected = Color(0x268B5FBF);
  static const Color sidebarHover = Color(0x148B5FBF);
  static const Color iconDefault = Color(0xFF6E7787);

  // Button semantic colors
  static const Color dangerBg = Color(0xFF2A1A1D);
  static const Color dangerText = Color(0xFFFF6B6B);
  static const Color dangerBorder = Color(0xFF4A2A2E);
  static const Color pauseBg = Color(0xFF2A2419);
  static const Color pauseText = Color(0xFFFFB84D);
  static const Color pauseBorder = Color(0xFF4A3F29);

  // Subject palette
  static const List<Color> subjectPalette = [
    Color(0xFF8B5FBF),
    Color(0xFF42D392),
    Color(0xFFFFB84D),
    Color(0xFFFF6B6B),
    Color(0xFF9B8FFF),
    Color(0xFF4DCCBD),
    Color(0xFFFF9B71),
    Color(0xFFE88FFF),
    Color(0xFF5CECD6),
    Color(0xFFFFD166),
  ];
}

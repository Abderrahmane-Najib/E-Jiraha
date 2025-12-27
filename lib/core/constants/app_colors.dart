import 'package:flutter/material.dart';

/// Ejiraha app color palette based on Figma design
class AppColors {
  AppColors._();

  // Primary Teal Colors
  static const Color primary = Color(0xFF0F766E);
  static const Color primaryDark = Color(0xFF115E59);
  static const Color primaryLight = Color(0xFF14B8A6);
  static const Color primarySurface = Color(0xFFE7F6F4);
  static const Color primaryContainer = Color(0xFFCCFBF1);

  // Background Colors
  static const Color background = Color(0xFFF6F7F8);
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFFAFAFA);
  static const Color cardBackground = Colors.white;

  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textOnPrimary = Colors.white;
  static const Color textHint = Color(0xFF757575);

  // Border Colors
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFFCBD5E1);

  // Status Colors
  static const Color success = Color(0xFF22C55E);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);

  // Role-specific Colors
  static const Color secretaryColor = Color(0xFF8B5CF6);
  static const Color nurseColor = Color(0xFFEC4899);
  static const Color surgeonColor = Color(0xFF0EA5E9);
  static const Color anesthesiologistColor = Color(0xFFF97316);
  static const Color adminColor = Color(0xFF6366F1);

  // Patient Status Colors
  static const Color statusPending = Color(0xFFFBBF24);
  static const Color statusInProgress = Color(0xFF3B82F6);
  static const Color statusCompleted = Color(0xFF22C55E);
  static const Color statusUrgent = Color(0xFFEF4444);

  // Gradient for buttons
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment(0.21, -1.49),
    end: Alignment(0.79, 2.49),
    colors: [primary, primaryDark],
  );

  // Shadow color
  static const Color shadowColor = Color(0x14020617);
  static const Color primaryShadow = Color(0x330F766E);
}

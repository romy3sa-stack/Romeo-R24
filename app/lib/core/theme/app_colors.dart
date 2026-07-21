import 'package:flutter/material.dart';

/// Phase 15 colour system: deep navy for trust, turquoise/blue for actions,
/// green for success, amber for warnings, red for errors.
class AppColors {
  const AppColors._();

  static const Color navy = Color(0xFF0B1F3A);
  static const Color navyLight = Color(0xFF14315C);
  static const Color turquoise = Color(0xFF2DD4BF);
  static const Color actionBlue = Color(0xFF2563EB);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  static const Color lightBackground = Color(0xFFF7F9FC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color darkBackground = Color(0xFF0B1220);
  static const Color darkSurface = Color(0xFF111A2E);

  static const Color textPrimaryLight = Color(0xFF0B1F3A);
  static const Color textSecondaryLight = Color(0xFF5B6B84);
  static const Color textPrimaryDark = Color(0xFFF1F5F9);
  static const Color textSecondaryDark = Color(0xFF9AA9C2);
}

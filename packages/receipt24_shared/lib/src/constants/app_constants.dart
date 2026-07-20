/// Receipt24 brand colours and design tokens (Phase 15).
abstract final class Receipt24Colors {
  static const int navy = 0xFF001A4D;
  static const int primary = 0xFF00B4D8;
  static const int success = 0xFF4CAF50;
  static const int warning = 0xFFFFB300;
  static const int error = 0xFFE53935;
  static const int backgroundLight = 0xFFF5F7FA;
  static const int backgroundDark = 0xFF0A1628;
  static const int surfaceLight = 0xFFFFFFFF;
  static const int surfaceDark = 0xFF1A2744;
  static const int textPrimaryLight = 0xFF1A1A2E;
  static const int textPrimaryDark = 0xFFF5F5F5;
  static const int textSecondary = 0xFF6B7280;
}

abstract final class Receipt24Typography {
  static const String fontFamily = 'Inter';
  static const String fontFamilyAlt = 'Manrope';
}

abstract final class Receipt24Spacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

abstract final class Receipt24Strings {
  static const String appName = 'Receipt24';
  static const String tagline = 'Every Receipt. One Place.';
}

/// Supported languages (Phase 14).
abstract final class SupportedLanguages {
  static const Map<String, String> languages = {
    'en': 'English',
    'fr': 'French',
    'pt': 'Portuguese',
    'es': 'Spanish',
    'af': 'Afrikaans',
    'zu': 'isiZulu',
  };
}

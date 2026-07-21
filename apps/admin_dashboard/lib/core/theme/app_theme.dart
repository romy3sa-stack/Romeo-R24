import 'package:flutter/material.dart';
import 'package:receipt24_shared/receipt24_shared.dart';

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(Receipt24Colors.navy),
          primary: const Color(Receipt24Colors.navy),
        ),
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(Receipt24Colors.navy),
          brightness: Brightness.dark,
          primary: const Color(Receipt24Colors.primary),
          surface: const Color(Receipt24Colors.surfaceDark),
        ),
        scaffoldBackgroundColor: const Color(Receipt24Colors.backgroundDark),
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
}

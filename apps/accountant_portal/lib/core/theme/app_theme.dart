import 'package:flutter/material.dart';
import 'package:receipt24_shared/receipt24_shared.dart';

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(Receipt24Colors.primary),
          primary: const Color(Receipt24Colors.navy),
          surface: const Color(Receipt24Colors.surfaceLight),
        ),
        scaffoldBackgroundColor: const Color(Receipt24Colors.backgroundLight),
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(Receipt24Colors.primary),
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

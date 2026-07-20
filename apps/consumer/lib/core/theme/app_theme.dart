import 'package:flutter/material.dart';
import 'package:receipt24_shared/receipt24_shared.dart';

abstract final class AppTheme {
  static const _navy = Color(Receipt24Colors.navy);
  static const _primary = Color(Receipt24Colors.primary);
  static const _success = Color(Receipt24Colors.success);
  static const _warning = Color(Receipt24Colors.warning);
  static const _error = Color(Receipt24Colors.error);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primary,
          primary: _navy,
          secondary: _primary,
          tertiary: _success,
          error: _error,
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
          filled: true,
        ),
        fontFamily: Receipt24Typography.fontFamily,
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primary,
          brightness: Brightness.dark,
          primary: _primary,
          secondary: _success,
          error: _error,
          surface: const Color(Receipt24Colors.surfaceDark),
        ),
        scaffoldBackgroundColor: const Color(Receipt24Colors.backgroundDark),
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        fontFamily: Receipt24Typography.fontFamily,
      );
}

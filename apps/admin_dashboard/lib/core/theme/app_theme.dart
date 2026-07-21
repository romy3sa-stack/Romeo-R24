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
}

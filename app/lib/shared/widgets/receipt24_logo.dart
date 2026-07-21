import 'package:flutter/material.dart';

/// Shared Receipt24 brand mark. Reused across the Welcome screen (Phase 3),
/// every area's app bar, and email/notification templates preview (later
/// phases) — defined once here per Rule 7 ("use reusable components").
class Receipt24Logo extends StatelessWidget {
  const Receipt24Logo({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/branding/receipt24_logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}

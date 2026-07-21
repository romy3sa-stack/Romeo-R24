import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/app_theme_mode_controller.dart';
import 'features/platform_status/platform_status_screen.dart';

void main() {
  runApp(const Receipt24App());
}

/// Root widget for the shared Receipt24 platform (Step 1.1). The Consumer
/// App, Accountant Portal and Super Admin Dashboard are three areas of this
/// same codebase (see lib/areas/), selected at runtime by
/// `AppArea.forRole()` once Phase 3 auth screens exist.
class Receipt24App extends StatelessWidget {
  const Receipt24App({super.key});

  @override
  Widget build(BuildContext context) {
    final themeModeController = AppThemeModeController();

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeController,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'Receipt24',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          home: const PlatformStatusScreen(),
        );
      },
    );
  }
}

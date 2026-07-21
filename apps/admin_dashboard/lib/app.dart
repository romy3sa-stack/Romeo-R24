import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:receipt24_shared/receipt24_shared.dart';

import 'core/l10n/locale_provider.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';

class AdminDashboardApp extends ConsumerWidget {
  const AdminDashboardApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: '${Receipt24Strings.appName} — Admin',
      debugShowCheckedModeBanner: false,
      locale: Locale(locale),
      theme: AppTheme.light.copyWith(
        textTheme: GoogleFonts.interTextTheme(AppTheme.light.textTheme),
      ),
      darkTheme: AppTheme.dark.copyWith(
        textTheme: GoogleFonts.interTextTheme(AppTheme.dark.textTheme),
      ),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}

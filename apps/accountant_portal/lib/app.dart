import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:receipt24_shared/receipt24_shared.dart';

import 'core/l10n/locale_provider.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';

class AccountantPortalApp extends ConsumerWidget {
  const AccountantPortalApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    ref.watch(localeProvider);

    return MaterialApp.router(
      title: '${Receipt24Strings.appName} — Accountant',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light.copyWith(
        textTheme: GoogleFonts.interTextTheme(AppTheme.light.textTheme),
      ),
      routerConfig: router,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:receipt24_shared/receipt24_shared.dart';

import '../../../core/l10n/locale_provider.dart';
import '../../../core/widgets/receipt24_widgets.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Receipt24Spacing.lg),
          child: Column(
            children: [
              const Align(
                alignment: Alignment.centerRight,
                child: LanguageSelector(),
              ),
              const Spacer(),
              const Receipt24Logo(size: 120),
              const SizedBox(height: Receipt24Spacing.lg),
              Text(
                l10n.appName,
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.brightness == Brightness.dark
                      ? Colors.white
                      : const Color(Receipt24Colors.navy),
                ),
              ),
              const SizedBox(height: Receipt24Spacing.sm),
              Text(
                l10n.tagline,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: const Color(Receipt24Colors.textSecondary),
                ),
              ),
              const Spacer(),
              PrimaryButton(
                label: l10n.signIn,
                onPressed: () => context.push('/auth/login'),
              ),
              const SizedBox(height: Receipt24Spacing.sm),
              SecondaryButton(
                label: l10n.createAccount,
                onPressed: () => context.push('/auth/register'),
              ),
              const SizedBox(height: Receipt24Spacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.g_mobiledata, size: 24),
                      label: Text(l10n.continueWithGoogle),
                    ),
                  ),
                  const SizedBox(width: Receipt24Spacing.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.apple, size: 20),
                      label: Text(l10n.continueWithApple),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Receipt24Spacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => context.push('/legal/privacy'),
                    child: Text(l10n.privacyPolicy),
                  ),
                  const Text(' · '),
                  TextButton(
                    onPressed: () => context.push('/legal/terms'),
                    child: Text(l10n.termsAndConditions),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:receipt24_shared/receipt24_shared.dart';

/// Phase 3.1 — Welcome screen (placeholder for Phase 3 implementation).
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Receipt24Spacing.lg),
          child: Column(
            children: [
              const Spacer(),
              Image.asset(
                'assets/images/receipt24_logo.png',
                height: 120,
                errorBuilder: (_, __, ___) => _LogoPlaceholder(isDark: isDark),
              ),
              const SizedBox(height: Receipt24Spacing.lg),
              Text(
                Receipt24Strings.appName,
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(Receipt24Colors.navy),
                ),
              ),
              const SizedBox(height: Receipt24Spacing.sm),
              Text(
                Receipt24Strings.tagline,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: const Color(Receipt24Colors.textSecondary),
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {},
                child: const Text('Sign In'),
              ),
              const SizedBox(height: Receipt24Spacing.sm),
              OutlinedButton(
                onPressed: () {},
                child: const Text('Create Account'),
              ),
              const SizedBox(height: Receipt24Spacing.md),
              Row(
                children: [
                  Expanded(child: _SocialButton(label: 'Google', onPressed: () {})),
                  const SizedBox(width: Receipt24Spacing.sm),
                  Expanded(child: _SocialButton(label: 'Apple', onPressed: () {})),
                ],
              ),
              const SizedBox(height: Receipt24Spacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(onPressed: () {}, child: const Text('Privacy Policy')),
                  const Text(' · '),
                  TextButton(onPressed: () {}, child: const Text('Terms')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoPlaceholder extends StatelessWidget {
  const _LogoPlaceholder({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      width: 100,
      decoration: BoxDecoration(
        color: const Color(Receipt24Colors.navy),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Icon(Icons.receipt_long, color: Color(Receipt24Colors.success), size: 48),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(onPressed: onPressed, child: Text(label));
  }
}

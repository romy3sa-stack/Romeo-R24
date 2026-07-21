import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:receipt24_shared/receipt24_shared.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/utils/form_validators.dart';
import '../../../../core/widgets/receipt24_widgets.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref
          .read(authServiceProvider)
          .resetPassword(_emailController.text.trim());
      setState(() => _sent = true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.genericError)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AuthScaffold(
      title: l10n.resetPassword,
      showBack: true,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_sent) ...[
              const Icon(Icons.mark_email_read_outlined,
                  size: 64, color: Color(Receipt24Colors.success)),
              const SizedBox(height: Receipt24Spacing.md),
              Text(
                l10n.verifyEmailMessage,
                textAlign: TextAlign.center,
              ),
            ] else ...[
              AuthTextField(
                label: l10n.email,
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: (v) => FormValidators.email(v, l10n),
              ),
              PrimaryButton(
                label: l10n.sendResetLink,
                isLoading: _isLoading,
                onPressed: _sendReset,
              ),
            ],
            const SizedBox(height: Receipt24Spacing.md),
            TextButton(
              onPressed: () => context.go('/auth/login'),
              child: Text(l10n.backToLogin),
            ),
          ],
        ),
      ),
    );
  }
}

class VerifyEmailScreen extends ConsumerWidget {
  const VerifyEmailScreen({super.key, this.email});

  final String? email;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final resolvedEmail =
        email ?? GoRouterState.of(context).extra as String? ?? '';

    return AuthScaffold(
      title: l10n.verifyEmailTitle,
      showBack: true,
      child: Column(
        children: [
          const Icon(Icons.email_outlined,
              size: 72, color: Color(Receipt24Colors.primary)),
          const SizedBox(height: Receipt24Spacing.lg),
          Text(l10n.verifyEmailMessage, textAlign: TextAlign.center),
          if (resolvedEmail.isNotEmpty) ...[
            const SizedBox(height: Receipt24Spacing.sm),
            Text(
              resolvedEmail,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
          const SizedBox(height: Receipt24Spacing.xl),
          PrimaryButton(
            label: l10n.resendVerification,
            onPressed: () async {
              if (resolvedEmail.isNotEmpty) {
                await ref
                    .read(authServiceProvider)
                    .resendVerificationEmail(resolvedEmail);
              }
            },
          ),
          const SizedBox(height: Receipt24Spacing.md),
          TextButton(
            onPressed: () => context.go('/auth/login'),
            child: Text(l10n.backToLogin),
          ),
        ],
      ),
    );
  }
}

class AccountantPendingScreen extends ConsumerWidget {
  const AccountantPendingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Receipt24Spacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.hourglass_top,
                  size: 80, color: Color(Receipt24Colors.warning)),
              const SizedBox(height: Receipt24Spacing.lg),
              Text(
                l10n.accountantPendingTitle,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Receipt24Spacing.md),
              Text(
                l10n.accountantPendingMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(Receipt24Colors.textSecondary)),
              ),
              const SizedBox(height: Receipt24Spacing.xl),
              PrimaryButton(
                label: l10n.signOut,
                onPressed: () => ref.read(authServiceProvider).signOut(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

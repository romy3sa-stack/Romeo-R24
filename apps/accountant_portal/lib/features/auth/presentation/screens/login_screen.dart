import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:receipt24_shared/receipt24_shared.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/l10n/locale_provider.dart';
import '../../../core/utils/form_validators.dart';
import '../../../core/widgets/portal_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = context.l10n;
    setState(() => _isLoading = true);

    try {
      await ref.read(authServiceProvider).signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.loginFailed)));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Receipt24Spacing.lg),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const Receipt24Logo(),
                    const SizedBox(height: Receipt24Spacing.md),
                    Text(
                      l10n.accountantPortal,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      Receipt24Strings.tagline,
                      style: const TextStyle(
                          color: Color(Receipt24Colors.textSecondary)),
                    ),
                    const SizedBox(height: Receipt24Spacing.xl),
                    AuthTextField(
                      label: l10n.email,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => FormValidators.email(v, l10n),
                    ),
                    AuthTextField(
                      label: l10n.password,
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      validator: (v) => FormValidators.password(v, l10n),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    PrimaryButton(
                      label: l10n.signIn,
                      isLoading: _isLoading,
                      onPressed: _login,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PendingScreen extends ConsumerWidget {
  const PendingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final auth = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountantPortal)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(Receipt24Spacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.hourglass_top, size: 64),
              const SizedBox(height: Receipt24Spacing.md),
              Text(
                l10n.accountantPendingTitle,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Receipt24Spacing.sm),
              Text(
                l10n.accountantPendingMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Color(Receipt24Colors.textSecondary)),
              ),
              if (auth?.firmName != null) ...[
                const SizedBox(height: Receipt24Spacing.md),
                Text(auth!.firmName!),
              ],
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

class WrongRoleScreen extends ConsumerWidget {
  const WrongRoleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(Receipt24Spacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.block, size: 64),
              const SizedBox(height: Receipt24Spacing.md),
              Text(
                l10n.notAnAccountant,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
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

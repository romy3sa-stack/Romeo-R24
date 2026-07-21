import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:receipt24_shared/receipt24_shared.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/utils/form_validators.dart';
import '../../../../core/widgets/receipt24_widgets.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.loginFailed)),
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
      title: l10n.signIn,
      showBack: true,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.push('/auth/forgot-password'),
                child: Text(l10n.forgotPassword),
              ),
            ),
            const SizedBox(height: Receipt24Spacing.md),
            PrimaryButton(
              label: l10n.signIn,
              isLoading: _isLoading,
              onPressed: _login,
            ),
            const SizedBox(height: Receipt24Spacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(l10n.dontHaveAccount),
                TextButton(
                  onPressed: () => context.push('/auth/register'),
                  child: Text(l10n.createAccount),
                ),
              ],
            ),
            TextButton(
              onPressed: () => context.push('/auth/register/accountant'),
              child: Text(l10n.registerAsAccountant),
            ),
          ],
        ),
      ),
    );
  }
}

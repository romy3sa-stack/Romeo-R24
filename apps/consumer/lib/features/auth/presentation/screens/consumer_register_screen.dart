import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:receipt24_shared/receipt24_shared.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/utils/form_validators.dart';
import '../../../../core/widgets/receipt24_widgets.dart';

class ConsumerRegisterScreen extends ConsumerStatefulWidget {
  const ConsumerRegisterScreen({super.key});

  @override
  ConsumerState<ConsumerRegisterScreen> createState() =>
      _ConsumerRegisterScreenState();
}

class _ConsumerRegisterScreenState extends ConsumerState<ConsumerRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _country;
  String? _currency;
  String _language = 'en';
  bool _acceptTerms = false;
  bool _acceptPrivacy = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final l10n = context.l10n;
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.mustAcceptTerms)));
      return;
    }
    if (!_acceptPrivacy) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.mustAcceptPrivacy)));
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).signUpConsumer(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            fullName: _nameController.text.trim(),
            phoneNumber: _phoneController.text.trim(),
            country: _country,
            currency: _currency,
            preferredLanguage: _language,
          );
      if (mounted) {
        context.go('/auth/verify-email', extra: _emailController.text.trim());
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.genericError)));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AuthScaffold(
      title: l10n.createAccount,
      showBack: true,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthTextField(
              label: l10n.fullName,
              controller: _nameController,
              validator: (v) => FormValidators.required(v, l10n),
            ),
            AuthTextField(
              label: l10n.email,
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              validator: (v) => FormValidators.email(v, l10n),
            ),
            AuthTextField(
              label: l10n.mobileNumber,
              controller: _phoneController,
              keyboardType: TextInputType.phone,
            ),
            AuthTextField(
              label: l10n.password,
              controller: _passwordController,
              obscureText: true,
              validator: (v) => FormValidators.password(v, l10n),
            ),
            AuthTextField(
              label: l10n.confirmPassword,
              controller: _confirmPasswordController,
              obscureText: true,
              validator: (v) => FormValidators.confirmPassword(
                v,
                _passwordController.text,
                l10n,
              ),
            ),
            _DropdownField(
              label: l10n.country,
              value: _country,
              items: ReferenceData.countries
                  .map((c) => DropdownMenuItem(value: c.$1, child: Text(c.$2)))
                  .toList(),
              onChanged: (v) => setState(() => _country = v),
            ),
            _DropdownField(
              label: l10n.currency,
              value: _currency,
              items: ReferenceData.currencies
                  .map((c) => DropdownMenuItem(value: c.$1, child: Text(c.$2)))
                  .toList(),
              onChanged: (v) => setState(() => _currency = v),
            ),
            _DropdownField(
              label: l10n.preferredLanguage,
              value: _language,
              items: SupportedLanguages.languages.entries
                  .map((e) =>
                      DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) => setState(() => _language = v ?? 'en'),
            ),
            CheckboxListTile(
              value: _acceptTerms,
              onChanged: (v) => setState(() => _acceptTerms = v ?? false),
              title: Text(l10n.acceptTerms, style: const TextStyle(fontSize: 14)),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              value: _acceptPrivacy,
              onChanged: (v) => setState(() => _acceptPrivacy = v ?? false),
              title:
                  Text(l10n.acceptPrivacy, style: const TextStyle(fontSize: 14)),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: Receipt24Spacing.md),
            PrimaryButton(
              label: l10n.register,
              isLoading: _isLoading,
              onPressed: _register,
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

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Receipt24Spacing.md),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(labelText: label),
        items: items,
        onChanged: onChanged,
      ),
    );
  }
}

import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:receipt24_shared/receipt24_shared.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/utils/form_validators.dart';
import '../../../../core/widgets/receipt24_widgets.dart';

class AccountantRegisterScreen extends ConsumerStatefulWidget {
  const AccountantRegisterScreen({super.key});

  @override
  ConsumerState<AccountantRegisterScreen> createState() =>
      _AccountantRegisterScreenState();
}

class _AccountantRegisterScreenState
    extends ConsumerState<AccountantRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firmController = TextEditingController();
  final _regNumberController = TextEditingController();
  final _taxController = TextEditingController();
  final _addressController = TextEditingController();

  String? _country;
  String _plan = 'solo_accountant';
  String? _documentName;
  Uint8List? _documentBytes;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _firmController.dispose();
    _regNumberController.dispose();
    _taxController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _documentName = result.files.single.name;
        _documentBytes = result.files.single.bytes;
      });
    }
  }

  Future<void> _register() async {
    final l10n = context.l10n;
    if (!_formKey.currentState!.validate()) return;
    if (_documentBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.verificationDocument)),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await ref.read(authServiceProvider).signUpAccountant(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            fullName: _nameController.text.trim(),
            firmName: _firmController.text.trim(),
            professionalRegistrationNumber: _regNumberController.text.trim(),
            taxNumber: _taxController.text.trim(),
            country: _country,
            address: _addressController.text.trim(),
            phoneNumber: _phoneController.text.trim(),
            subscriptionPlan: _plan,
          );

      final userId = response.user?.id;
      if (userId != null && _documentBytes != null && _documentName != null) {
        await ref.read(authServiceProvider).uploadVerificationDocument(
              userId: userId,
              fileName: _documentName!,
              bytes: _documentBytes!,
            );
        await ref.read(authServiceProvider).updateAccountantPlan(userId, _plan);
      }

      if (mounted) context.go('/accountant-pending');
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
      title: l10n.registerAsAccountant,
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
              label: l10n.firmName,
              controller: _firmController,
              validator: (v) => FormValidators.required(v, l10n),
            ),
            AuthTextField(
              label: l10n.professionalRegNumber,
              controller: _regNumberController,
            ),
            AuthTextField(
              label: l10n.taxNumber,
              controller: _taxController,
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
              label: l10n.address,
              controller: _addressController,
              maxLines: 2,
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: Receipt24Spacing.md),
              child: DropdownButtonFormField<String>(
                value: _country,
                decoration: InputDecoration(labelText: l10n.country),
                items: ReferenceData.countries
                    .map((c) =>
                        DropdownMenuItem(value: c.$1, child: Text(c.$2)))
                    .toList(),
                onChanged: (v) => setState(() => _country = v),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: Receipt24Spacing.md),
              child: DropdownButtonFormField<String>(
                value: _plan,
                decoration: InputDecoration(labelText: l10n.subscriptionPlan),
                items: [
                  DropdownMenuItem(
                      value: 'solo_accountant', child: Text(l10n.planSolo)),
                  DropdownMenuItem(
                      value: 'professional_firm',
                      child: Text(l10n.planProfessional)),
                  DropdownMenuItem(
                      value: 'enterprise_firm',
                      child: Text(l10n.planEnterprise)),
                ],
                onChanged: (v) => setState(() => _plan = v ?? _plan),
              ),
            ),
            OutlinedButton.icon(
              onPressed: _pickDocument,
              icon: const Icon(Icons.upload_file),
              label: Text(
                _documentName ?? l10n.uploadDocument,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: Receipt24Spacing.lg),
            PrimaryButton(
              label: l10n.register,
              isLoading: _isLoading,
              onPressed: _register,
            ),
            TextButton(
              onPressed: () => context.push('/auth/register'),
              child: Text(l10n.registerAsConsumer),
            ),
          ],
        ),
      ),
    );
  }
}

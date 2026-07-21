import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:receipt24_shared/receipt24_shared.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/utils/form_validators.dart';
import '../../../../core/widgets/receipt24_widgets.dart';
import '../../../expenses/providers/expense_providers.dart';
import '../../../notifications/data/notification_helper.dart';
import '../../providers/receipt_providers.dart';

class ManualEntryScreen extends ConsumerStatefulWidget {
  const ManualEntryScreen({super.key});

  @override
  ConsumerState<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends ConsumerState<ManualEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _merchantController = TextEditingController();
  final _addressController = TextEditingController();
  final _receiptNumberController = TextEditingController();
  final _totalController = TextEditingController();
  final _taxController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _date = DateTime.now();
  String _currency = 'USD';
  String _paymentMethod = 'card';
  bool _isSaving = false;

  @override
  void dispose() {
    _merchantController.dispose();
    _addressController.dispose();
    _receiptNumberController.dispose();
    _totalController.dispose();
    _taxController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = context.l10n;
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isSaving = true);
    try {
      final extraction = OcrExtractionResult(
        merchantName: _merchantController.text.trim(),
        merchantAddress: _addressController.text.trim(),
        receiptNumber: _receiptNumberController.text.trim(),
        transactionDate: _date,
        totalAmount: double.tryParse(_totalController.text),
        taxAmount: double.tryParse(_taxController.text),
        currency: _currency,
        paymentMethod: _paymentMethod,
        confidenceScore: 100,
      );

      final saved = await ref.read(receiptServiceProvider).saveReceipt(
            userId: user.id,
            extraction: extraction,
            receiptSource: 'manual_entry',
          );

      await ref.read(expenseServiceProvider).autoClassifyReceipt(
            receiptId: saved.id,
            userId: user.id,
            merchantName: _merchantController.text.trim(),
          );

      await notifyReceiptSaved(ref, userId: user.id, receipt: saved);

      ref.invalidate(receiptsListProvider);
      ref.invalidate(homeStatsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.receiptSaved)));
        context.go('/home/receipts');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.genericError)));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.captureManual)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(Receipt24Spacing.md),
          children: [
            AuthTextField(
              label: l10n.merchantName,
              controller: _merchantController,
              validator: (v) => FormValidators.required(v, l10n),
            ),
            AuthTextField(
              label: l10n.address,
              controller: _addressController,
            ),
            AuthTextField(
              label: l10n.receiptNumber,
              controller: _receiptNumberController,
            ),
            ListTile(
              title: Text(l10n.transactionDate),
              subtitle: Text('${_date.year}-${_date.month}-${_date.day}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _date = picked);
              },
            ),
            AuthTextField(
              label: l10n.totalAmount,
              controller: _totalController,
              keyboardType: TextInputType.number,
              validator: (v) => FormValidators.required(v, l10n),
            ),
            AuthTextField(
              label: l10n.taxAmount,
              controller: _taxController,
              keyboardType: TextInputType.number,
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: Receipt24Spacing.md),
              child: DropdownButtonFormField<String>(
                value: _currency,
                decoration: InputDecoration(labelText: l10n.currency),
                items: ReferenceData.currencies
                    .map((c) =>
                        DropdownMenuItem(value: c.$1, child: Text(c.$2)))
                    .toList(),
                onChanged: (v) => setState(() => _currency = v ?? _currency),
              ),
            ),
            AuthTextField(
              label: 'Notes',
              controller: _notesController,
              maxLines: 3,
            ),
            const SizedBox(height: Receipt24Spacing.lg),
            PrimaryButton(
              label: l10n.saveReceipt,
              isLoading: _isSaving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}

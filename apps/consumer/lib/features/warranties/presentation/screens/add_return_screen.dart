import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:receipt24_shared/receipt24_shared.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/widgets/receipt24_widgets.dart';
import '../../../receipts/providers/receipt_providers.dart';
import '../../providers/warranty_return_providers.dart';

class AddReturnScreen extends ConsumerStatefulWidget {
  const AddReturnScreen({super.key, required this.receiptId});

  final String receiptId;

  @override
  ConsumerState<AddReturnScreen> createState() => _AddReturnScreenState();
}

class _AddReturnScreenState extends ConsumerState<AddReturnScreen> {
  String? _selectedItemId;
  String _requestType = 'return';
  final _reasonController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _refundController = TextEditingController();
  DateTime? _returnDeadline;
  bool _isSaving = false;

  static const _requestTypes = ['return', 'refund', 'exchange'];

  @override
  void dispose() {
    _reasonController.dispose();
    _descriptionController.dispose();
    _refundController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isSaving = true);
    try {
      final refundText = _refundController.text.trim();
      final refundAmount =
          refundText.isNotEmpty ? double.tryParse(refundText) : null;

      await ref.read(returnServiceProvider).createReturn(
            userId: user.id,
            receiptId: widget.receiptId,
            receiptItemId: _selectedItemId,
            requestType: _requestType,
            reason: _reasonController.text.trim(),
            description: _descriptionController.text.trim(),
            returnDeadline: _returnDeadline,
            refundAmount: refundAmount,
          );
      ref.invalidate(returnsListProvider);
      ref.invalidate(warrantyReturnStatsProvider);
      ref.invalidate(homeStatsProvider);
      ref.invalidate(receiptDetailProvider(widget.receiptId));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.returnSaved)));
        context.pop();
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
    final receiptAsync = ref.watch(receiptDetailProvider(widget.receiptId));
    final dateFormat = DateFormat.yMMMd();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.addReturn)),
      body: receiptAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(l10n.genericError)),
        data: (receipt) {
          if (receipt == null) {
            return const Center(child: Text('Receipt not found'));
          }

          return ListView(
            padding: const EdgeInsets.all(Receipt24Spacing.md),
            children: [
              if (receipt.items.isNotEmpty) ...[
                Text(l10n.selectProduct,
                    style: Theme.of(context).textTheme.titleSmall),
                ...receipt.items.map((item) => RadioListTile<String?>(
                      title: Text(item.itemName),
                      value: item.id,
                      groupValue: _selectedItemId,
                      onChanged: (v) => setState(() => _selectedItemId = v),
                    )),
              ],
              Text('Request type',
                  style: Theme.of(context).textTheme.titleSmall),
              Wrap(
                spacing: 8,
                children: _requestTypes.map((type) {
                  return ChoiceChip(
                    label: Text(type),
                    selected: _requestType == type,
                    onSelected: (_) => setState(() => _requestType = type),
                  );
                }).toList(),
              ),
              const SizedBox(height: Receipt24Spacing.md),
              AuthTextField(
                label: l10n.returnReason,
                controller: _reasonController,
              ),
              AuthTextField(
                label: 'Description',
                controller: _descriptionController,
                maxLines: 3,
              ),
              ListTile(
                title: Text(l10n.returnDeadline),
                subtitle: Text(
                  _returnDeadline != null
                      ? dateFormat.format(_returnDeadline!)
                      : 'Not set',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _returnDeadline ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() => _returnDeadline = picked);
                  }
                },
              ),
              AuthTextField(
                label: l10n.refundAmount,
                controller: _refundController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: Receipt24Spacing.lg),
              PrimaryButton(
                label: l10n.recordReturn,
                isLoading: _isSaving,
                onPressed: _save,
              ),
            ],
          );
        },
      ),
    );
  }
}

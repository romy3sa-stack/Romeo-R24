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

class AddWarrantyScreen extends ConsumerStatefulWidget {
  const AddWarrantyScreen({super.key, required this.receiptId});

  final String receiptId;

  @override
  ConsumerState<AddWarrantyScreen> createState() => _AddWarrantyScreenState();
}

class _AddWarrantyScreenState extends ConsumerState<AddWarrantyScreen> {
  String? _selectedItemId;
  int _warrantyDays = 365;
  DateTime _startDate = DateTime.now();
  final _contactController = TextEditingController();
  final _notesController = TextEditingController();
  bool _remindersEnabled = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _contactController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isSaving = true);
    try {
      await ref.read(warrantyServiceProvider).createWarranty(
            userId: user.id,
            receiptId: widget.receiptId,
            receiptItemId: _selectedItemId,
            startDate: _startDate,
            warrantyPeriodDays: _warrantyDays,
            merchantContact: _contactController.text.trim(),
            notes: _notesController.text.trim(),
            remindersEnabled: _remindersEnabled,
          );
      ref.invalidate(warrantiesListProvider);
      ref.invalidate(warrantyReturnStatsProvider);
      ref.invalidate(homeStatsProvider);
      ref.invalidate(receiptDetailProvider(widget.receiptId));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.warrantySaved)));
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
      appBar: AppBar(title: Text(l10n.addWarranty)),
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
                      subtitle: item.serialNumber != null
                          ? Text('S/N: ${item.serialNumber}')
                          : null,
                      value: item.id,
                      groupValue: _selectedItemId,
                      onChanged: (v) => setState(() => _selectedItemId = v),
                    )),
              ],
              ListTile(
                title: Text(l10n.transactionDate),
                subtitle: Text(dateFormat.format(
                    receipt.transactionDate ?? DateTime.now())),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _startDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _startDate = picked);
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: Receipt24Spacing.md),
                child: Text('${l10n.warrantyPeriod}: $_warrantyDays'),
              ),
              Slider(
                value: _warrantyDays.toDouble(),
                min: 30,
                max: 1095,
                divisions: 35,
                label: '$_warrantyDays',
                onChanged: (v) => setState(() => _warrantyDays = v.toInt()),
              ),
              AuthTextField(
                label: l10n.merchantNotes,
                controller: _contactController,
                maxLines: 2,
              ),
              AuthTextField(
                label: 'Notes',
                controller: _notesController,
                maxLines: 2,
              ),
              SwitchListTile(
                title: Text(l10n.reminderSettings),
                subtitle: Text(_remindersEnabled
                    ? l10n.remindersEnabled
                    : l10n.remindersDisabled),
                value: _remindersEnabled,
                onChanged: (v) => setState(() => _remindersEnabled = v),
              ),
              const SizedBox(height: Receipt24Spacing.lg),
              PrimaryButton(
                label: l10n.saveWarranty,
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

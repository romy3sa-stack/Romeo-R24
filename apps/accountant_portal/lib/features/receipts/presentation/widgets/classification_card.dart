import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receipt24_shared/receipt24_shared.dart';

import '../../../core/l10n/locale_provider.dart';
import '../../../core/widgets/portal_widgets.dart';
import '../providers/receipt_providers.dart';

class ClassificationCard extends ConsumerStatefulWidget {
  const ClassificationCard({
    super.key,
    required this.receiptId,
    required this.consumerUserId,
    this.initialClassification,
  });

  final String receiptId;
  final String consumerUserId;
  final ExpenseClassificationModel? initialClassification;

  @override
  ConsumerState<ClassificationCard> createState() =>
      _ClassificationCardState();
}

class _ClassificationCardState extends ConsumerState<ClassificationCard> {
  String? _categoryId;
  String _expenseType = 'personal';
  double _businessPercentage = 50;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final c = widget.initialClassification;
    if (c != null) {
      _categoryId = c.expenseCategoryId;
      _expenseType = c.expenseType;
      _businessPercentage = c.businessPercentage;
    }
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    setState(() => _isSaving = true);
    try {
      await ref.read(accountantReceiptServiceProvider).saveClassification(
            receiptId: widget.receiptId,
            consumerUserId: widget.consumerUserId,
            expenseCategoryId: _categoryId,
            expenseType: _expenseType,
            businessPercentage: _businessPercentage,
          );
      ref.invalidate(accountantReceiptDetailProvider(widget.receiptId));
      ref.invalidate(clientReceiptsProvider(widget.consumerUserId));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.classificationSaved)));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final categoriesAsync = ref.watch(expenseCategoriesProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Receipt24Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.expenseCategory,
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: Receipt24Spacing.sm),
            categoriesAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => Text(l10n.genericError),
              data: (categories) => DropdownButtonFormField<String?>(
                value: _categoryId,
                decoration: InputDecoration(
                  labelText: l10n.expenseCategory,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('—')),
                  ...categories.map((c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(c.categoryName),
                      )),
                ],
                onChanged: (v) => setState(() => _categoryId = v),
              ),
            ),
            const SizedBox(height: Receipt24Spacing.md),
            Text(l10n.expenseType,
                style: Theme.of(context).textTheme.titleSmall),
            ...['personal', 'business', 'mixed_use'].map((type) =>
                RadioListTile<String>(
                  title: Text(type.replaceAll('_', ' ')),
                  value: type,
                  groupValue: _expenseType,
                  onChanged: (v) => setState(() => _expenseType = v!),
                )),
            if (_expenseType == 'mixed_use') ...[
              Text('${l10n.businessPercentage}: ${_businessPercentage.toInt()}%'),
              Slider(
                value: _businessPercentage,
                min: 0,
                max: 100,
                divisions: 20,
                label: '${_businessPercentage.toInt()}%',
                onChanged: (v) => setState(() => _businessPercentage = v),
              ),
            ],
            const SizedBox(height: Receipt24Spacing.sm),
            PrimaryButton(
              label: l10n.saveClassification,
              isLoading: _isSaving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}

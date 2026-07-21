import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receipt24_shared/receipt24_shared.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../../../receipts/providers/receipt_providers.dart';
import '../../providers/expense_providers.dart';

class ExpenseClassificationCard extends ConsumerStatefulWidget {
  const ExpenseClassificationCard({
    super.key,
    required this.receiptId,
    required this.merchantName,
    this.items = const [],
    this.initialClassification,
  });

  final String receiptId;
  final String? merchantName;
  final List<ReceiptItemModel> items;
  final ExpenseClassificationModel? initialClassification;

  @override
  ConsumerState<ExpenseClassificationCard> createState() =>
      _ExpenseClassificationCardState();
}

class _ExpenseClassificationCardState
    extends ConsumerState<ExpenseClassificationCard> {
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
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isSaving = true);
    try {
      await ref.read(expenseServiceProvider).saveClassification(
            receiptId: widget.receiptId,
            userId: user.id,
            expenseCategoryId: _categoryId,
            expenseType: _expenseType,
            businessPercentage: _businessPercentage,
            userConfirmed: true,
            classificationSource: 'user_confirmed',
          );
      ref.invalidate(expenseClassificationProvider(widget.receiptId));
      ref.invalidate(receiptDetailProvider(widget.receiptId));
      ref.invalidate(receiptsListProvider);
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
    final suggestionAsync = ref.watch(categorySuggestionProvider((
      merchant: widget.merchantName,
      items: widget.items,
    )));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Receipt24Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.expenseCategory,
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: Receipt24Spacing.sm),
            suggestionAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (suggestion) {
                if (suggestion == null) return const SizedBox.shrink();
                if (_categoryId == null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _categoryId = suggestion.categoryId);
                  });
                }
                return Container(
                  margin: const EdgeInsets.only(bottom: Receipt24Spacing.sm),
                  padding: const EdgeInsets.all(Receipt24Spacing.sm),
                  decoration: BoxDecoration(
                    color: const Color(Receipt24Colors.primary)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome, size: 16),
                          const SizedBox(width: 4),
                          Text(l10n.suggestedCategory,
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          const Spacer(),
                          Text('${suggestion.confidenceScore.toStringAsFixed(0)}%'),
                        ],
                      ),
                      Text(suggestion.categoryName),
                      Text(suggestion.reason,
                          style: const TextStyle(
                              fontSize: 12,
                              color: Color(Receipt24Colors.textSecondary))),
                    ],
                  ),
                );
              },
            ),
            categoriesAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => Text(l10n.genericError),
              data: (categories) => DropdownButtonFormField<String>(
                value: _categoryId,
                decoration: InputDecoration(labelText: l10n.expenseCategory),
                items: categories
                    .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.categoryName),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _categoryId = v),
              ),
            ),
            const SizedBox(height: Receipt24Spacing.md),
            Text(l10n.expenseType,
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: Receipt24Spacing.sm),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'personal', label: Text(l10n.personal)),
                ButtonSegment(value: 'business', label: Text(l10n.business)),
                ButtonSegment(value: 'mixed_use', label: Text(l10n.mixedUse)),
              ],
              selected: {_expenseType},
              onSelectionChanged: (s) =>
                  setState(() => _expenseType = s.first),
            ),
            if (_expenseType == 'mixed_use') ...[
              const SizedBox(height: Receipt24Spacing.md),
              Text('${l10n.businessPercentage}: ${_businessPercentage.toInt()}%'),
              Slider(
                value: _businessPercentage,
                min: 1,
                max: 99,
                divisions: 98,
                label: '${_businessPercentage.toInt()}%',
                onChanged: (v) => setState(() => _businessPercentage = v),
              ),
            ],
            const SizedBox(height: Receipt24Spacing.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.saveClassification),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

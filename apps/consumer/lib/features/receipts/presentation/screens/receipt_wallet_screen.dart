import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:receipt24_shared/receipt24_shared.dart';

import '../../../../core/l10n/locale_provider.dart';
import '../../../expenses/providers/expense_providers.dart';
import '../../providers/receipt_providers.dart';

class ReceiptWalletScreen extends ConsumerWidget {
  const ReceiptWalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final receiptsAsync = ref.watch(receiptsListProvider);
    final filter = ref.watch(receiptFilterProvider);
    final duplicateCountAsync = ref.watch(duplicateCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navReceipts),
        actions: [
          duplicateCountAsync.when(
            data: (count) => count > 0
                ? IconButton(
                    icon: Badge(
                      label: Text('$count'),
                      child: const Icon(Icons.content_copy),
                    ),
                    onPressed: () => context.push('/receipts/duplicates'),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterSheet(context, ref, filter),
          ),
        ],
      ),
      body: receiptsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => ErrorStateView(
          message: l10n.genericError,
          onRetry: () => ref.invalidate(receiptsListProvider),
          retryLabel: l10n.retry,
        ),
        data: (receipts) {
          if (receipts.isEmpty) {
            return EmptyStateView(
              icon: Icons.receipt_long,
              title: l10n.noReceiptsYet,
              message: l10n.noReceiptsHint,
              actionLabel: l10n.scanReceipt,
              onAction: () => context.push('/receipts/scan'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(receiptsListProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(Receipt24Spacing.sm),
              itemCount: receipts.length,
              itemBuilder: (context, index) {
                final receipt = receipts[index];
                return _ReceiptCard(
                  receipt: receipt,
                  onTap: () => context.push('/receipts/${receipt.id}'),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/receipts/scan'),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showFilterSheet(
    BuildContext context,
    WidgetRef ref,
    ReceiptFilter filter,
  ) {
    final l10n = context.l10n;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(Receipt24Spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.filterSort,
                style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: Receipt24Spacing.md),
            Text(l10n.filterByExpenseType,
                style: Theme.of(ctx).textTheme.titleSmall),
            Wrap(
              spacing: 8,
              children: [
                _FilterChip(
                  label: l10n.allTypes,
                  selected: filter.expenseType == null,
                  onTap: () {
                    ref.read(receiptFilterProvider.notifier).state =
                        ReceiptFilter(sortBy: filter.sortBy);
                    ref.invalidate(receiptsListProvider);
                  },
                ),
                _FilterChip(
                  label: l10n.personal,
                  selected: filter.expenseType == 'personal',
                  onTap: () {
                    ref.read(receiptFilterProvider.notifier).state =
                        filter.copyWith(expenseType: 'personal');
                    ref.invalidate(receiptsListProvider);
                  },
                ),
                _FilterChip(
                  label: l10n.business,
                  selected: filter.expenseType == 'business',
                  onTap: () {
                    ref.read(receiptFilterProvider.notifier).state =
                        filter.copyWith(expenseType: 'business');
                    ref.invalidate(receiptsListProvider);
                  },
                ),
                _FilterChip(
                  label: l10n.mixedUse,
                  selected: filter.expenseType == 'mixed_use',
                  onTap: () {
                    ref.read(receiptFilterProvider.notifier).state =
                        filter.copyWith(expenseType: 'mixed_use');
                    ref.invalidate(receiptsListProvider);
                  },
                ),
              ],
            ),
            const Divider(),
            ...ReceiptSort.values.map((sort) {
              final label = switch (sort) {
                ReceiptSort.newest => l10n.sortNewest,
                ReceiptSort.oldest => l10n.sortOldest,
                ReceiptSort.highestAmount => l10n.sortHighest,
                ReceiptSort.lowestAmount => l10n.sortLowest,
              };
              return RadioListTile<ReceiptSort>(
                title: Text(label),
                value: sort,
                groupValue: filter.sortBy,
                onChanged: (v) {
                  ref.read(receiptFilterProvider.notifier).state =
                      filter.copyWith(sortBy: v);
                  ref.invalidate(receiptsListProvider);
                  Navigator.pop(ctx);
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard({required this.receipt, required this.onTap});

  final ReceiptModel receipt;
  final VoidCallback onTap;

  String _expenseTypeLabel(ExpenseClassificationModel? c, AppLocalizations l10n) {
    if (c == null) return '';
    return switch (c.expenseType) {
      'business' => l10n.business,
      'mixed_use' => l10n.mixedUse,
      _ => l10n.personal,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dateFormat = DateFormat.yMMMd();
    final currency = receipt.currency ?? 'USD';
    final classification = receipt.expenseClassification;

    return Card(
      margin: const EdgeInsets.only(bottom: Receipt24Spacing.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(Receipt24Spacing.md),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor:
                    const Color(Receipt24Colors.navy).withValues(alpha: 0.1),
                child: Text(
                  receipt.displayMerchant.isNotEmpty
                      ? receipt.displayMerchant[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                      color: Color(Receipt24Colors.navy),
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: Receipt24Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(receipt.displayMerchant,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (receipt.transactionDate != null)
                      Text(
                        dateFormat.format(receipt.transactionDate!),
                        style: const TextStyle(
                            color: Color(Receipt24Colors.textSecondary),
                            fontSize: 13),
                      ),
                    Wrap(
                      spacing: 4,
                      children: [
                        if (classification?.categoryName != null)
                          Chip(
                            label: Text(classification!.categoryName!,
                                style: const TextStyle(fontSize: 11)),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                          ),
                        if (classification != null)
                          Chip(
                            label: Text(
                                _expenseTypeLabel(classification, l10n),
                                style: const TextStyle(fontSize: 11)),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$currency ${receipt.totalAmount?.toStringAsFixed(2) ?? '—'}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (receipt.warrantyAvailable)
                        const Icon(Icons.verified,
                            size: 16, color: Color(Receipt24Colors.success)),
                      if (receipt.isDuplicateFlagged)
                        const Icon(Icons.content_copy,
                            size: 16, color: Color(Receipt24Colors.warning)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

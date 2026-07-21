import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:receipt24_shared/receipt24_shared.dart';

import '../../../../core/l10n/locale_provider.dart';
import '../../providers/receipt_providers.dart';

class ReceiptWalletScreen extends ConsumerWidget {
  const ReceiptWalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final receiptsAsync = ref.watch(receiptsListProvider);
    final filter = ref.watch(receiptFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navReceipts),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterSheet(context, ref, filter),
          ),
        ],
      ),
      body: receiptsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(l10n.genericError)),
        data: (receipts) {
          if (receipts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: Receipt24Spacing.md),
                  Text(l10n.noReceiptsYet),
                  Text(l10n.noReceiptsHint,
                      style: const TextStyle(
                          color: Color(Receipt24Colors.textSecondary))),
                  const SizedBox(height: Receipt24Spacing.lg),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/receipts/scan'),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.scanReceipt),
                  ),
                ],
              ),
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
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(Receipt24Spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.filterSort,
                style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: Receipt24Spacing.md),
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

class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard({required this.receipt, required this.onTap});

  final ReceiptModel receipt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd();
    final currency = receipt.currency ?? 'USD';

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
                    if (receipt.categoryName != null)
                      Text(receipt.categoryName!,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.secondary,
                              fontSize: 12)),
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
        ),
      ),
    );
  }
}

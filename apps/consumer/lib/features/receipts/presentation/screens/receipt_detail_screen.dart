import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:receipt24_shared/receipt24_shared.dart';

import '../../../../core/l10n/locale_provider.dart';
import '../../providers/receipt_providers.dart';

class ReceiptDetailScreen extends ConsumerWidget {
  const ReceiptDetailScreen({super.key, required this.receiptId});

  final String receiptId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final receiptAsync = ref.watch(receiptDetailProvider(receiptId));
    final dateFormat = DateFormat.yMMMd();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.receiptDetails)),
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
              if (receipt.isDuplicateFlagged)
                Card(
                  color: const Color(Receipt24Colors.warning)
                      .withValues(alpha: 0.15),
                  child: ListTile(
                    leading: const Icon(Icons.warning_amber,
                        color: Color(Receipt24Colors.warning)),
                    title: Text(l10n.duplicateWarning),
                  ),
                ),
              _DetailTile(
                  label: l10n.merchantName, value: receipt.displayMerchant),
              if (receipt.transactionDate != null)
                _DetailTile(
                  label: l10n.transactionDate,
                  value: dateFormat.format(receipt.transactionDate!),
                ),
              if (receipt.receiptNumber != null)
                _DetailTile(
                    label: l10n.receiptNumber, value: receipt.receiptNumber!),
              _DetailTile(
                label: l10n.totalAmount,
                value:
                    '${receipt.currency ?? ''} ${receipt.totalAmount?.toStringAsFixed(2) ?? '—'}',
              ),
              if (receipt.taxAmount != null)
                _DetailTile(
                  label: l10n.taxAmount,
                  value: receipt.taxAmount!.toStringAsFixed(2),
                ),
              if (receipt.ocrConfidenceScore != null)
                _DetailTile(
                  label: l10n.ocrConfidence,
                  value: '${receipt.ocrConfidenceScore!.toStringAsFixed(1)}%',
                ),
              if (receipt.paymentMethod != null)
                _DetailTile(
                  label: l10n.paymentMethodLabel,
                  value: receipt.paymentMethod!,
                ),
              const Divider(),
              Text(l10n.itemsPurchased,
                  style: Theme.of(context).textTheme.titleSmall),
              ...receipt.items.map((item) => ListTile(
                    title: Text(item.itemName),
                    subtitle: Text('Qty: ${item.quantity}'),
                    trailing: Text(
                        item.totalPrice?.toStringAsFixed(2) ?? '—'),
                  )),
              if (receipt.notes != null)
                _DetailTile(label: 'Notes', value: receipt.notes!),
              const SizedBox(height: Receipt24Spacing.lg),
              Wrap(
                spacing: Receipt24Spacing.sm,
                runSpacing: Receipt24Spacing.sm,
                children: [
                  _ActionChip(label: 'Share', icon: Icons.share),
                  _ActionChip(label: 'Export', icon: Icons.download),
                  _ActionChip(label: 'Personal', icon: Icons.person),
                  _ActionChip(label: 'Business', icon: Icons.business),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Receipt24Spacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(
                    color: Color(Receipt24Colors.textSecondary))),
          ),
          Expanded(
              child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$label — coming in next phase')),
        );
      },
    );
  }
}

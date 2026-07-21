import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:receipt24_shared/receipt24_shared.dart';

import '../../../../core/l10n/locale_provider.dart';
import '../../../receipts/providers/receipt_providers.dart';
import '../../providers/warranty_return_providers.dart';

class ReturnDetailScreen extends ConsumerWidget {
  const ReturnDetailScreen({super.key, required this.returnId});

  final String returnId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final returnAsync = ref.watch(returnDetailProvider(returnId));
    final dateFormat = DateFormat.yMMMd();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.returnDetails)),
      body: returnAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(l10n.genericError)),
        data: (returnRecord) {
          if (returnRecord == null) {
            return const Center(child: Text('Return not found'));
          }

          return ListView(
            padding: const EdgeInsets.all(Receipt24Spacing.md),
            children: [
              if (returnRecord.isDeadlineSoon)
                Card(
                  color: const Color(Receipt24Colors.warning)
                      .withValues(alpha: 0.15),
                  child: ListTile(
                    leading: const Icon(Icons.schedule),
                    title: Text(l10n.returnDeadline),
                    subtitle: Text(
                      '${returnRecord.daysUntilDeadline} ${l10n.daysRemaining}',
                    ),
                  ),
                ),
              _DetailRow(
                  label: 'Product',
                  value: returnRecord.productName ?? '—'),
              _DetailRow(
                  label: l10n.merchantName,
                  value: returnRecord.merchantName ?? '—'),
              _DetailRow(
                  label: 'Type', value: returnRecord.requestType),
              if (returnRecord.requestReason != null)
                _DetailRow(
                    label: l10n.returnReason,
                    value: returnRecord.requestReason!),
              if (returnRecord.requestDescription != null)
                _DetailRow(
                    label: 'Description',
                    value: returnRecord.requestDescription!),
              if (returnRecord.returnDeadline != null)
                _DetailRow(
                  label: l10n.returnDeadline,
                  value: dateFormat.format(returnRecord.returnDeadline!),
                ),
              if (returnRecord.refundAmount != null)
                _DetailRow(
                  label: l10n.refundAmount,
                  value: returnRecord.refundAmount!.toStringAsFixed(2),
                ),
              _DetailRow(
                  label: l10n.returnStatus,
                  value: returnRecord.requestStatus),
              if (returnRecord.merchantResponseNotes != null)
                _DetailRow(
                    label: l10n.merchantNotes,
                    value: returnRecord.merchantResponseNotes!),
              const Divider(),
              Text(l10n.updateStatus,
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: Receipt24Spacing.sm),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ReturnStatuses.all.map((status) {
                  return ActionChip(
                    label: Text(status.replaceAll('_', ' ')),
                    onPressed: () => _updateStatus(context, ref, status),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _updateStatus(
    BuildContext context,
    WidgetRef ref,
    String status,
  ) async {
    double? refundReceived;
    if (status == 'refund_received') {
      final amountText = await showDialog<String>(
        context: context,
        builder: (ctx) {
          final controller = TextEditingController();
          return AlertDialog(
            title: Text(context.l10n.refundAmount),
            content: TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(context.l10n.continueButton)),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, controller.text),
                  child: const Text('Save')),
            ],
          );
        },
      );
      if (amountText != null && amountText.isNotEmpty) {
        refundReceived = double.tryParse(amountText);
      }
    }

    await ref.read(returnServiceProvider).updateStatus(
          returnId: returnId,
          status: status,
          refundReceived: refundReceived,
        );
    ref.invalidate(returnDetailProvider(returnId));
    ref.invalidate(returnsListProvider);
    ref.invalidate(warrantyReturnStatsProvider);
    ref.invalidate(homeStatsProvider);
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: const TextStyle(
                    color: Color(Receipt24Colors.textSecondary))),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:receipt24_shared/receipt24_shared.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../../../receipts/providers/receipt_providers.dart';
import '../../providers/warranty_return_providers.dart';

class WarrantyDetailScreen extends ConsumerWidget {
  const WarrantyDetailScreen({super.key, required this.warrantyId});

  final String warrantyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final warrantyAsync = ref.watch(warrantyDetailProvider(warrantyId));
    final dateFormat = DateFormat.yMMMd();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.warrantyDetails)),
      body: warrantyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(l10n.genericError)),
        data: (warranty) {
          if (warranty == null) {
            return const Center(child: Text('Warranty not found'));
          }

          return ListView(
            padding: const EdgeInsets.all(Receipt24Spacing.md),
            children: [
              if (warranty.isExpiringSoon && !warranty.isExpired)
                Card(
                  color: const Color(Receipt24Colors.warning)
                      .withValues(alpha: 0.15),
                  child: ListTile(
                    leading: const Icon(Icons.warning_amber),
                    title: Text(l10n.expiringSoon),
                    subtitle: Text(
                        '${warranty.daysRemaining} ${l10n.daysRemaining}'),
                  ),
                ),
              _DetailRow(
                  label: 'Product', value: warranty.productName ?? '—'),
              _DetailRow(
                  label: l10n.merchantName,
                  value: warranty.merchantName ?? '—'),
              _DetailRow(
                  label: l10n.transactionDate,
                  value: dateFormat.format(warranty.warrantyStartDate)),
              _DetailRow(
                  label: l10n.warrantyExpiry,
                  value: dateFormat.format(warranty.warrantyEndDate)),
              _DetailRow(
                label: l10n.daysRemaining,
                value: warranty.isExpired
                    ? l10n.expired
                    : '${warranty.daysRemaining}',
              ),
              if (warranty.serialNumber != null)
                _DetailRow(label: 'Serial', value: warranty.serialNumber!),
              _DetailRow(
                  label: l10n.warrantyStatus, value: warranty.warrantyStatus),
              if (warranty.claimReference != null)
                _DetailRow(
                    label: l10n.claimReference,
                    value: warranty.claimReference!),
              if (warranty.notes != null)
                _DetailRow(label: 'Notes', value: warranty.notes!),
              const Divider(),
              Text(l10n.updateStatus,
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: Receipt24Spacing.sm),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: WarrantyStatuses.all.map((status) {
                  return ActionChip(
                    label: Text(status.replaceAll('_', ' ')),
                    onPressed: () => _updateStatus(context, ref, status),
                  );
                }).toList(),
              ),
              const SizedBox(height: Receipt24Spacing.lg),
              ListTile(
                title: Text(l10n.reminderSettings),
                subtitle: Text(warranty.reminderStatus.replaceAll('_', ' ')),
                trailing: Switch(
                  value: warranty.reminderStatus != ReminderStatuses.disabled,
                  onChanged: (enabled) async {
                    await ref.read(warrantyServiceProvider).setReminderStatus(
                          warranty.id,
                          enabled
                              ? ReminderStatuses.pending
                              : ReminderStatuses.disabled,
                        );
                    ref.invalidate(warrantyDetailProvider(warrantyId));
                  },
                ),
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
    String? claimRef;
    if (status == 'claim_started') {
      claimRef = await showDialog<String>(
        context: context,
        builder: (ctx) {
          final controller = TextEditingController();
          return AlertDialog(
            title: Text(context.l10n.claimReference),
            content: TextField(controller: controller),
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
    }

    await ref.read(warrantyServiceProvider).updateClaimStatus(
          warrantyId: warrantyId,
          status: status,
          claimReference: claimRef,
        );
    ref.invalidate(warrantyDetailProvider(warrantyId));
    ref.invalidate(warrantiesListProvider);
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

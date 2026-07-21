import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:receipt24_shared/receipt24_shared.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../../../receipts/providers/receipt_providers.dart';
import '../../providers/expense_providers.dart';

class DuplicatesScreen extends ConsumerWidget {
  const DuplicatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final duplicatesAsync = ref.watch(duplicateReceiptsProvider);
    final dateFormat = DateFormat.yMMMd();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.duplicateAlerts)),
      body: duplicatesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(l10n.genericError)),
        data: (duplicates) {
          if (duplicates.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: Receipt24Spacing.md),
                  Text(l10n.noDuplicates),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(Receipt24Spacing.md),
            itemCount: duplicates.length,
            itemBuilder: (context, index) {
              final receipt = duplicates[index];
              return Card(
                margin: const EdgeInsets.only(bottom: Receipt24Spacing.sm),
                child: ListTile(
                  leading: const Icon(Icons.content_copy,
                      color: Color(Receipt24Colors.warning)),
                  title: Text(receipt.displayMerchant),
                  subtitle: Text(
                    '${dateFormat.format(receipt.transactionDate ?? DateTime.now())} · '
                    '${receipt.currency} ${receipt.totalAmount?.toStringAsFixed(2) ?? '—'}',
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (action) async {
                      if (action == 'dismiss') {
                        await ref
                            .read(expenseServiceProvider)
                            .dismissDuplicateFlag(receipt.id);
                        ref.invalidate(duplicateReceiptsProvider);
                        ref.invalidate(duplicateCountProvider);
                        ref.invalidate(receiptsListProvider);
                      } else if (action == 'view') {
                        context.push('/receipts/${receipt.id}');
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                          value: 'view', child: Text(l10n.viewReceipt)),
                      PopupMenuItem(
                          value: 'dismiss',
                          child: Text(l10n.notDuplicate)),
                    ],
                  ),
                  onTap: () => context.push('/receipts/${receipt.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

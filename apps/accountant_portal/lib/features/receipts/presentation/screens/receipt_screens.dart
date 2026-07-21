import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:receipt24_shared/receipt24_shared.dart';

import '../../../core/l10n/locale_provider.dart';
import '../../../core/widgets/portal_widgets.dart';
import '../../clients/providers/client_providers.dart';
import '../providers/receipt_providers.dart';
import '../widgets/classification_card.dart';

class ClientReceiptsScreen extends ConsumerWidget {
  const ClientReceiptsScreen({super.key, required this.clientId});

  final String clientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final clientAsync = ref.watch(clientDetailProvider(clientId));

    return clientAsync.when(
      loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator())),
      error: (_, __) => Scaffold(
          body: Center(child: Text(l10n.genericError))),
      data: (client) {
        if (client == null || !client.isApproved) {
          return const Scaffold(
              body: Center(child: Text('Client not found')));
        }
        return _ReceiptsList(
          clientId: clientId,
          consumerUserId: client.consumerUserId,
        );
      },
    );
  }
}

class _ReceiptsList extends ConsumerWidget {
  const _ReceiptsList({
    required this.clientId,
    required this.consumerUserId,
  });

  final String clientId;
  final String consumerUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final receiptsAsync = ref.watch(clientReceiptsProvider(consumerUserId));
    final dateFormat = DateFormat.yMMMd();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.clientReceipts)),
      body: receiptsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(l10n.genericError)),
        data: (receipts) {
          if (receipts.isEmpty) {
            return Center(child: Text(l10n.noReceiptsYet));
          }

          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(clientReceiptsProvider(consumerUserId)),
            child: ListView.builder(
              padding: const EdgeInsets.all(Receipt24Spacing.sm),
              itemCount: receipts.length,
              itemBuilder: (context, index) {
                final receipt = receipts[index];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.receipt)),
                    title: Text(receipt.displayMerchant),
                    subtitle: Text(
                      receipt.transactionDate != null
                          ? dateFormat.format(receipt.transactionDate!)
                          : '—',
                    ),
                    trailing: Text(
                      receipt.totalAmount?.toStringAsFixed(2) ?? '—',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    onTap: () => context.push(
                      '/clients/$clientId/receipts/${receipt.id}',
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class AccountantReceiptDetailScreen extends ConsumerStatefulWidget {
  const AccountantReceiptDetailScreen({
    super.key,
    required this.clientId,
    required this.receiptId,
  });

  final String clientId;
  final String receiptId;

  @override
  ConsumerState<AccountantReceiptDetailScreen> createState() =>
      _AccountantReceiptDetailScreenState();
}

class _AccountantReceiptDetailScreenState
    extends ConsumerState<AccountantReceiptDetailScreen> {
  final _notesController = TextEditingController();
  bool _notesInitialized = false;
  bool _isSavingNotes = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveNotes() async {
    final l10n = context.l10n;
    setState(() => _isSavingNotes = true);
    try {
      await ref.read(accountantReceiptServiceProvider).updateReceiptNotes(
            widget.receiptId,
            _notesController.text.trim(),
          );
      ref.invalidate(accountantReceiptDetailProvider(widget.receiptId));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.notesSaved)));
      }
    } finally {
      if (mounted) setState(() => _isSavingNotes = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final clientAsync = ref.watch(clientDetailProvider(widget.clientId));
    final receiptAsync =
        ref.watch(accountantReceiptDetailProvider(widget.receiptId));
    final dateFormat = DateFormat.yMMMd();

    final consumerUserId = clientAsync.valueOrNull?.consumerUserId;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.receiptDetails)),
      body: receiptAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(l10n.genericError)),
        data: (receipt) {
          if (receipt == null || consumerUserId == null) {
            return const Center(child: Text('Receipt not found'));
          }

          if (!_notesInitialized) {
            _notesController.text = receipt.notes ?? '';
            _notesInitialized = true;
          }

          return ListView(
            padding: const EdgeInsets.all(Receipt24Spacing.md),
            children: [
              _DetailRow(
                  label: l10n.merchantName, value: receipt.displayMerchant),
              if (receipt.transactionDate != null)
                _DetailRow(
                  label: l10n.transactionDate,
                  value: dateFormat.format(receipt.transactionDate!),
                ),
              _DetailRow(
                label: l10n.totalAmount,
                value:
                    '${receipt.currency ?? ''} ${receipt.totalAmount?.toStringAsFixed(2) ?? '—'}',
              ),
              if (receipt.paymentMethod != null)
                _DetailRow(
                    label: l10n.paymentMethodLabel,
                    value: receipt.paymentMethod!),
              const Divider(),
              ClassificationCard(
                receiptId: widget.receiptId,
                consumerUserId: consumerUserId,
                initialClassification: receipt.expenseClassification,
              ),
              const Divider(),
              Text(l10n.itemsPurchased,
                  style: Theme.of(context).textTheme.titleSmall),
              ...receipt.items.map((item) => ListTile(
                    title: Text(item.itemName),
                    subtitle: Text('Qty: ${item.quantity}'),
                    trailing:
                        Text(item.totalPrice?.toStringAsFixed(2) ?? '—'),
                  )),
              const Divider(),
              Text(l10n.accountantNotes,
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: Receipt24Spacing.sm),
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: l10n.addNotes,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: Receipt24Spacing.sm),
              PrimaryButton(
                label: l10n.addNotes,
                isLoading: _isSavingNotes,
                onPressed: _saveNotes,
              ),
            ],
          );
        },
      ),
    );
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

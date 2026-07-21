import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:receipt24_shared/receipt24_shared.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/widgets/receipt24_widgets.dart';
import '../../../expenses/providers/expense_providers.dart';
import '../../providers/receipt_providers.dart';

class ReceiptReviewScreen extends ConsumerStatefulWidget {
  const ReceiptReviewScreen({super.key});

  @override
  ConsumerState<ReceiptReviewScreen> createState() =>
      _ReceiptReviewScreenState();
}

class _ReceiptReviewScreenState extends ConsumerState<ReceiptReviewScreen> {
  late TextEditingController _merchantController;
  late TextEditingController _receiptNumberController;
  late TextEditingController _totalController;
  late TextEditingController _taxController;
  late TextEditingController _subtotalController;
  DateTime? _transactionDate;
  String _paymentMethod = 'card';
  bool _isSaving = false;
  late List<ReceiptItemModel> _items;

  @override
  void initState() {
    super.initState();
    final pending = ref.read(pendingCaptureProvider);
    final e = pending?.extraction;
    _merchantController = TextEditingController(text: e?.merchantName ?? '');
    _receiptNumberController =
        TextEditingController(text: e?.receiptNumber ?? '');
    _totalController =
        TextEditingController(text: e?.totalAmount?.toStringAsFixed(2) ?? '');
    _taxController =
        TextEditingController(text: e?.taxAmount?.toStringAsFixed(2) ?? '');
    _subtotalController =
        TextEditingController(text: e?.subtotal?.toStringAsFixed(2) ?? '');
    _transactionDate = e?.transactionDate ?? DateTime.now();
    _paymentMethod = e?.paymentMethod ?? 'card';
    _items = List.from(e?.items ?? []);
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _receiptNumberController.dispose();
    _totalController.dispose();
    _taxController.dispose();
    _subtotalController.dispose();
    super.dispose();
  }

  OcrExtractionResult _buildExtraction() {
    final pending = ref.read(pendingCaptureProvider);
    return OcrExtractionResult(
      merchantName: _merchantController.text.trim(),
      merchantAddress: pending?.extraction.merchantAddress,
      merchantTaxNumber: pending?.extraction.merchantTaxNumber,
      receiptNumber: _receiptNumberController.text.trim(),
      transactionDate: _transactionDate,
      items: _items,
      subtotal: double.tryParse(_subtotalController.text),
      taxAmount: double.tryParse(_taxController.text),
      totalAmount: double.tryParse(_totalController.text),
      currency: pending?.extraction.currency ?? 'USD',
      paymentMethod: _paymentMethod,
      rawText: pending?.extraction.rawText,
      confidenceScore: pending?.extraction.confidenceScore ?? 0,
      fieldConfidence: pending?.extraction.fieldConfidence ?? {},
    );
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final user = ref.read(currentUserProvider);
    final pending = ref.read(pendingCaptureProvider);
    if (user == null || pending == null) return;

    setState(() => _isSaving = true);
    try {
      final saved = await ref.read(receiptServiceProvider).saveReceipt(
            userId: user.id,
            extraction: _buildExtraction(),
            receiptSource: pending.receiptSource,
            imagePath: pending.imagePath,
            pdfPath: pending.pdfPath,
            uploadId: pending.uploadId,
          );

      await ref.read(expenseServiceProvider).autoClassifyReceipt(
            receiptId: saved.id,
            userId: user.id,
            merchantName: _merchantController.text.trim(),
            items: _items,
          );

      ref.read(pendingCaptureProvider.notifier).state = null;
      ref.invalidate(receiptsListProvider);
      ref.invalidate(homeStatsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.receiptSaved)));
        context.go('/home/receipts');
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
    final pending = ref.watch(pendingCaptureProvider);
    if (pending == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('No receipt to review')),
      );
    }

    final extraction = pending.extraction;
    final dateFormat = DateFormat.yMMMd();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.reviewTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Receipt24Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.reviewSubtitle,
                style: const TextStyle(color: Color(Receipt24Colors.textSecondary))),
            if (pending.previewBytes != null) ...[
              const SizedBox(height: Receipt24Spacing.md),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(pending.previewBytes!, height: 160, fit: BoxFit.cover),
              ),
            ],
            const SizedBox(height: Receipt24Spacing.md),
            if (extraction.isLowConfidence('merchantName'))
              _LowConfidenceBanner(text: l10n.lowConfidence),
            TextField(
              controller: _merchantController,
              decoration: InputDecoration(labelText: l10n.merchantName),
            ),
            const SizedBox(height: Receipt24Spacing.sm),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.transactionDate),
              subtitle: Text(dateFormat.format(_transactionDate!)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _transactionDate!,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _transactionDate = picked);
              },
            ),
            TextField(
              controller: _receiptNumberController,
              decoration: InputDecoration(labelText: l10n.receiptNumber),
            ),
            const SizedBox(height: Receipt24Spacing.sm),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _subtotalController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'Subtotal'),
                  ),
                ),
                const SizedBox(width: Receipt24Spacing.sm),
                Expanded(
                  child: TextField(
                    controller: _taxController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: l10n.taxAmount),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Receipt24Spacing.sm),
            TextField(
              controller: _totalController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l10n.totalAmount),
            ),
            const SizedBox(height: Receipt24Spacing.md),
            Text(l10n.itemsPurchased,
                style: Theme.of(context).textTheme.titleSmall),
            ..._items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              return ListTile(
                title: Text(item.itemName),
                subtitle: Text(
                    'Qty: ${item.quantity} × ${item.unitPrice?.toStringAsFixed(2) ?? '—'}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () =>
                      setState(() => _items.removeAt(i)),
                ),
              );
            }),
            TextButton.icon(
              onPressed: () => setState(() => _items.add(
                    const ReceiptItemModel(itemName: 'New item', quantity: 1),
                  )),
              icon: const Icon(Icons.add),
              label: Text(l10n.addItem),
            ),
            const SizedBox(height: Receipt24Spacing.lg),
            PrimaryButton(
              label: l10n.saveReceipt,
              isLoading: _isSaving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _LowConfidenceBanner extends StatelessWidget {
  const _LowConfidenceBanner({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: Receipt24Spacing.sm),
      padding: const EdgeInsets.all(Receipt24Spacing.sm),
      decoration: BoxDecoration(
        color: const Color(Receipt24Colors.warning).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: Color(Receipt24Colors.warning)),
          const SizedBox(width: Receipt24Spacing.sm),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

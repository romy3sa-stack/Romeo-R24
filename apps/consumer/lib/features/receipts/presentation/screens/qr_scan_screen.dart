import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:receipt24_shared/receipt24_shared.dart';

import '../../../../core/l10n/locale_provider.dart';

class QrScanScreen extends ConsumerStatefulWidget {
  const QrScanScreen({super.key});

  @override
  ConsumerState<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends ConsumerState<QrScanScreen> {
  String? _scannedValue;
  bool _handled = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    // mobile_scanner requires platform; show manual input fallback for web/dev
    return Scaffold(
      appBar: AppBar(title: Text(l10n.qrScanTitle)),
      body: Padding(
        padding: const EdgeInsets.all(Receipt24Spacing.lg),
        child: Column(
          children: [
            const Icon(Icons.qr_code_scanner,
                size: 80, color: Color(Receipt24Colors.primary)),
            const SizedBox(height: Receipt24Spacing.md),
            Text(l10n.qrScanHint, textAlign: TextAlign.center),
            const SizedBox(height: Receipt24Spacing.lg),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Paste QR URL or reference',
                hintText: 'https://... or transaction ref',
              ),
              onSubmitted: (value) => _handleScan(value),
            ),
            const SizedBox(height: Receipt24Spacing.md),
            ElevatedButton(
              onPressed: () {
                _handleScan('https://example.com/receipt/TXN-12345');
              },
              child: Text(l10n.qrResult),
            ),
            if (_scannedValue != null) ...[
              const SizedBox(height: Receipt24Spacing.lg),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.link),
                  title: Text(l10n.qrResult),
                  subtitle: Text(_scannedValue!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _handleScan(String value) {
    if (_handled) return;
    _handled = true;
    setState(() => _scannedValue = value);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${context.l10n.qrResult}: $value')),
    );
    // QR may link to receipt URL or reference — user can add manually or upload
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) context.push('/receipts/manual');
    });
  }
}

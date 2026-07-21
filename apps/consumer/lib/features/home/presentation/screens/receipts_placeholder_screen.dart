import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receipt24_shared/receipt24_shared.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../../../core/widgets/receipt24_widgets.dart';

class ReceiptsPlaceholderScreen extends ConsumerWidget {
  const ReceiptsPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navReceipts)),
      body: Center(
        child: Text(l10n.noReceiptsYet),
      ),
    );
  }
}

class ScanPlaceholderScreen extends ConsumerWidget {
  const ScanPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navScan)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.document_scanner,
                size: 64, color: Color(Receipt24Colors.primary)),
            const SizedBox(height: Receipt24Spacing.md),
            Text(l10n.scanReceipt),
            const SizedBox(height: Receipt24Spacing.sm),
            const Text('Phase 5 — Receipt capture coming soon',
                style: TextStyle(color: Color(Receipt24Colors.textSecondary))),
          ],
        ),
      ),
    );
  }
}

class InsightsPlaceholderScreen extends ConsumerWidget {
  const InsightsPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navInsights)),
      body: const Center(
        child: Text('Phase 7 — Spending insights coming soon',
            style: TextStyle(color: Color(Receipt24Colors.textSecondary))),
      ),
    );
  }
}

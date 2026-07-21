import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:receipt24_shared/receipt24_shared.dart';

import '../../../../core/l10n/locale_provider.dart';
import '../../providers/warranty_return_providers.dart';

class WarrantiesReturnsHubScreen extends ConsumerWidget {
  const WarrantiesReturnsHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.warrantiesAndReturns),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.warranties),
              Tab(text: l10n.returns),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _WarrantiesTab(),
            _ReturnsTab(),
          ],
        ),
      ),
    );
  }
}

class _WarrantiesTab extends ConsumerWidget {
  const _WarrantiesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final warrantiesAsync = ref.watch(warrantiesListProvider);
    final dateFormat = DateFormat.yMMMd();

    return warrantiesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(child: Text(l10n.genericError)),
      data: (warranties) {
        if (warranties.isEmpty) {
          return Center(child: Text(l10n.noWarranties));
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(warrantiesListProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(Receipt24Spacing.sm),
            itemCount: warranties.length,
            itemBuilder: (context, index) {
              final w = warranties[index];
              return Card(
                child: ListTile(
                  leading: Icon(
                    w.isExpired
                        ? Icons.error_outline
                        : w.isExpiringSoon
                            ? Icons.warning_amber
                            : Icons.verified,
                    color: w.isExpired
                        ? const Color(Receipt24Colors.error)
                        : w.isExpiringSoon
                            ? const Color(Receipt24Colors.warning)
                            : const Color(Receipt24Colors.success),
                  ),
                  title: Text(w.productName ?? w.merchantName ?? 'Product'),
                  subtitle: Text(
                    '${l10n.warrantyExpiry}: ${dateFormat.format(w.warrantyEndDate)} · '
                    '${w.isExpired ? l10n.expired : '${w.daysRemaining} ${l10n.daysRemaining}'}',
                  ),
                  trailing: _StatusChip(status: w.warrantyStatus),
                  onTap: () => context.push('/warranties/${w.id}'),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _ReturnsTab extends ConsumerWidget {
  const _ReturnsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final returnsAsync = ref.watch(returnsListProvider);

    return returnsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(child: Text(l10n.genericError)),
      data: (returns) {
        if (returns.isEmpty) {
          return Center(child: Text(l10n.noReturns));
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(returnsListProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(Receipt24Spacing.sm),
            itemCount: returns.length,
            itemBuilder: (context, index) {
              final r = returns[index];
              return Card(
                child: ListTile(
                  leading: Icon(
                    r.isDeadlineSoon
                        ? Icons.schedule
                        : Icons.assignment_return,
                    color: r.isDeadlineSoon
                        ? const Color(Receipt24Colors.warning)
                        : const Color(Receipt24Colors.primary),
                  ),
                  title: Text(r.productName ?? r.merchantName ?? 'Return'),
                  subtitle: Text(
                    r.returnDeadline != null
                        ? '${l10n.returnDeadline}: ${DateFormat.yMMMd().format(r.returnDeadline!)}'
                        : r.requestReason ?? '',
                  ),
                  trailing: _StatusChip(status: r.requestStatus),
                  onTap: () => context.push('/returns/${r.id}'),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        status.replaceAll('_', ' '),
        style: const TextStyle(fontSize: 10),
      ),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );
  }
}

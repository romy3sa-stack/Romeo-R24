import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receipt24_shared/receipt24_shared.dart';

import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/widgets/receipt24_widgets.dart';
import '../providers/insights_providers.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final filter = ref.watch(insightsFilterProvider);
    final insightsAsync = ref.watch(insightsDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navInsights),
        actions: [
          PopupMenuButton<InsightsPeriod>(
            icon: const Icon(Icons.date_range),
            onSelected: (period) {
              ref.read(insightsFilterProvider.notifier).state =
                  filter.copyWith(period: period);
              ref.invalidate(insightsDataProvider);
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                  value: InsightsPeriod.thisMonth,
                  child: Text(l10n.periodThisMonth)),
              PopupMenuItem(
                  value: InsightsPeriod.lastMonth,
                  child: Text(l10n.periodLastMonth)),
              PopupMenuItem(
                  value: InsightsPeriod.last3Months,
                  child: Text(l10n.periodLast3Months)),
            ],
          ),
        ],
      ),
      body: insightsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(l10n.genericError)),
        data: (data) {
          if (data.receiptCount == 0) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(Receipt24Spacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.insights,
                        size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: Receipt24Spacing.md),
                    Text(l10n.noInsightsData,
                        style: Theme.of(context).textTheme.titleMedium),
                    Text(l10n.noInsightsHint,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Color(Receipt24Colors.textSecondary))),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(insightsDataProvider),
            child: ListView(
              padding: const EdgeInsets.all(Receipt24Spacing.md),
              children: [
                _PeriodChip(
                  label: _periodLabel(filter.period, l10n),
                ),
                const SizedBox(height: Receipt24Spacing.md),
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        label: l10n.totalSpending,
                        value:
                            '${data.currency} ${data.totalSpending.toStringAsFixed(2)}',
                        icon: Icons.payments_outlined,
                        color: const Color(Receipt24Colors.primary),
                      ),
                    ),
                    const SizedBox(width: Receipt24Spacing.sm),
                    Expanded(
                      child: StatCard(
                        label: l10n.receiptsCount,
                        value: '${data.receiptCount}',
                        icon: Icons.receipt_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Receipt24Spacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        label: l10n.businessExpenses,
                        value:
                            '${data.currency} ${data.businessTotal.toStringAsFixed(2)}',
                        icon: Icons.business_center_outlined,
                        color: const Color(Receipt24Colors.navy),
                      ),
                    ),
                    const SizedBox(width: Receipt24Spacing.sm),
                    Expanded(
                      child: StatCard(
                        label: l10n.personalExpenses,
                        value:
                            '${data.currency} ${data.personalTotal.toStringAsFixed(2)}',
                        icon: Icons.person_outline,
                        color: const Color(Receipt24Colors.success),
                      ),
                    ),
                  ],
                ),
                if (data.monthOverMonthChange != 0) ...[
                  const SizedBox(height: Receipt24Spacing.sm),
                  Card(
                    child: ListTile(
                      leading: Icon(
                        data.monthOverMonthChange > 0
                            ? Icons.trending_up
                            : Icons.trending_down,
                        color: data.monthOverMonthChange > 0
                            ? const Color(Receipt24Colors.warning)
                            : const Color(Receipt24Colors.success),
                      ),
                      title: Text(l10n.monthOverMonth),
                      subtitle: Text(l10n.vsLastMonth),
                      trailing: Text(
                        '${data.monthOverMonthChange > 0 ? '+' : ''}${data.monthOverMonthChange.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: data.monthOverMonthChange > 0
                              ? const Color(Receipt24Colors.warning)
                              : const Color(Receipt24Colors.success),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: Receipt24Spacing.lg),
                if (data.monthlySpending.isNotEmpty) ...[
                  Text(l10n.monthlyTrend,
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: Receipt24Spacing.sm),
                  SizedBox(
                    height: 200,
                    child: _BarChart(data: data.monthlySpending),
                  ),
                ],
                if (data.weeklySpending.isNotEmpty) ...[
                  const SizedBox(height: Receipt24Spacing.lg),
                  Text(l10n.weeklyTrend,
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: Receipt24Spacing.sm),
                  SizedBox(
                    height: 180,
                    child: _BarChart(data: data.weeklySpending),
                  ),
                ],
                const SizedBox(height: Receipt24Spacing.lg),
                Text(l10n.categoryBreakdown,
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: Receipt24Spacing.sm),
                ...data.categoryBreakdown.take(8).map(
                      (item) => _BreakdownTile(
                        item: item,
                        currency: data.currency,
                      ),
                    ),
                const SizedBox(height: Receipt24Spacing.lg),
                Text(l10n.merchantBreakdown,
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: Receipt24Spacing.sm),
                ...data.merchantBreakdown.take(8).map(
                      (item) => _BreakdownTile(
                        item: item,
                        currency: data.currency,
                      ),
                    ),
                if (data.alerts.isNotEmpty) ...[
                  const SizedBox(height: Receipt24Spacing.lg),
                  Text(l10n.spendingAlerts,
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: Receipt24Spacing.sm),
                  ...data.alerts.map((alert) => Card(
                        color: alert.severity == AlertSeverity.warning
                            ? const Color(Receipt24Colors.warning)
                                .withValues(alpha: 0.1)
                            : null,
                        child: ListTile(
                          leading: Icon(
                            alert.severity == AlertSeverity.warning
                                ? Icons.warning_amber
                                : Icons.info_outline,
                          ),
                          title: Text(alert.title),
                          subtitle: Text(alert.message),
                        ),
                      )),
                ],
                if (data.recurringExpenses.isNotEmpty) ...[
                  const SizedBox(height: Receipt24Spacing.lg),
                  Text(l10n.recurringExpenses,
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: Receipt24Spacing.sm),
                  ...data.recurringExpenses.take(5).map(
                        (r) => ListTile(
                          leading: const Icon(Icons.repeat),
                          title: Text(r.merchantName),
                          subtitle: Text(r.frequency),
                          trailing: Text(
                            '${r.currency} ${r.averageAmount.toStringAsFixed(2)}',
                          ),
                        ),
                      ),
                ],
                if (data.subscriptions.isNotEmpty) ...[
                  const SizedBox(height: Receipt24Spacing.lg),
                  Text(l10n.subscriptions,
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: Receipt24Spacing.sm),
                  ...data.subscriptions.map(
                    (s) => ListTile(
                      leading: const Icon(Icons.subscriptions,
                          color: Color(Receipt24Colors.primary)),
                      title: Text(s.merchantName),
                      subtitle: Text('${s.frequency} · ${s.currency}'),
                      trailing: Text(s.averageAmount.toStringAsFixed(2)),
                    ),
                  ),
                ],
                const SizedBox(height: Receipt24Spacing.lg),
                Text(
                  l10n.insightsDisclaimer,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(Receipt24Colors.textSecondary),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: Receipt24Spacing.xl),
              ],
            ),
          );
        },
      ),
    );
  }

  String _periodLabel(InsightsPeriod period, AppLocalizations l10n) {
    return switch (period) {
      InsightsPeriod.thisMonth => l10n.periodThisMonth,
      InsightsPeriod.lastMonth => l10n.periodLastMonth,
      InsightsPeriod.last3Months => l10n.periodLast3Months,
      InsightsPeriod.custom => l10n.periodThisMonth,
    };
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Chip(
        avatar: const Icon(Icons.calendar_today, size: 16),
        label: Text(label),
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  const _BarChart({required this.data});
  final List<PeriodSpending> data;

  @override
  Widget build(BuildContext context) {
    final maxY = data.map((d) => d.amount).reduce((a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        maxY: maxY * 1.2,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= data.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    data[i].label,
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: List.generate(data.length, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: data[i].amount,
                color: const Color(Receipt24Colors.primary),
                width: 16,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _BreakdownTile extends StatelessWidget {
  const _BreakdownTile({required this.item, required this.currency});

  final BreakdownItem item;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(item.name, overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: item.percentage / 100,
              backgroundColor: Colors.grey.shade200,
              color: const Color(Receipt24Colors.primary),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              '$currency ${item.amount.toStringAsFixed(0)}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

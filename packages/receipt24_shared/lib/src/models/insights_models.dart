/// Filter options for spending insights.
class InsightsFilter {
  const InsightsFilter({
    this.dateFrom,
    this.dateTo,
    this.expenseType,
    this.categoryId,
    this.currency,
    this.merchant,
    this.period = InsightsPeriod.thisMonth,
  });

  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? expenseType;
  final String? categoryId;
  final String? currency;
  final String? merchant;
  final InsightsPeriod period;

  InsightsFilter copyWith({
    DateTime? dateFrom,
    DateTime? dateTo,
    String? expenseType,
    String? categoryId,
    String? currency,
    String? merchant,
    InsightsPeriod? period,
  }) {
    return InsightsFilter(
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      expenseType: expenseType ?? this.expenseType,
      categoryId: categoryId ?? this.categoryId,
      currency: currency ?? this.currency,
      merchant: merchant ?? this.merchant,
      period: period ?? this.period,
    );
  }

  (DateTime, DateTime) resolveDateRange() {
    final now = DateTime.now();
    switch (period) {
      case InsightsPeriod.thisMonth:
        return (DateTime(now.year, now.month, 1), now);
      case InsightsPeriod.lastMonth:
        final start = DateTime(now.year, now.month - 1, 1);
        final end = DateTime(now.year, now.month, 0);
        return (start, end);
      case InsightsPeriod.last3Months:
        return (DateTime(now.year, now.month - 2, 1), now);
      case InsightsPeriod.custom:
        return (
          dateFrom ?? DateTime(now.year, now.month, 1),
          dateTo ?? now,
        );
    }
  }
}

enum InsightsPeriod {
  thisMonth,
  lastMonth,
  last3Months,
  custom,
}

/// Aggregated spending insights data.
class InsightsData {
  const InsightsData({
    required this.totalSpending,
    required this.businessTotal,
    required this.personalTotal,
    required this.receiptCount,
    required this.currency,
    required this.weeklySpending,
    required this.monthlySpending,
    required this.categoryBreakdown,
    required this.merchantBreakdown,
    required this.monthOverMonthChange,
    required this.alerts,
    required this.recurringExpenses,
    required this.subscriptions,
  });

  final double totalSpending;
  final double businessTotal;
  final double personalTotal;
  final int receiptCount;
  final String currency;
  final List<PeriodSpending> weeklySpending;
  final List<PeriodSpending> monthlySpending;
  final List<BreakdownItem> categoryBreakdown;
  final List<BreakdownItem> merchantBreakdown;
  final double monthOverMonthChange;
  final List<SpendingAlert> alerts;
  final List<RecurringExpense> recurringExpenses;
  final List<RecurringExpense> subscriptions;

  static const empty = InsightsData(
    totalSpending: 0,
    businessTotal: 0,
    personalTotal: 0,
    receiptCount: 0,
    currency: 'USD',
    weeklySpending: [],
    monthlySpending: [],
    categoryBreakdown: [],
    merchantBreakdown: [],
    monthOverMonthChange: 0,
    alerts: [],
    recurringExpenses: [],
    subscriptions: [],
  );
}

class PeriodSpending {
  const PeriodSpending({required this.label, required this.amount});

  final String label;
  final double amount;
}

class BreakdownItem {
  const BreakdownItem({
    required this.name,
    required this.amount,
    required this.count,
    this.percentage = 0,
  });

  final String name;
  final double amount;
  final int count;
  final double percentage;
}

class SpendingAlert {
  const SpendingAlert({
    required this.title,
    required this.message,
    required this.severity,
  });

  final String title;
  final String message;
  final AlertSeverity severity;
}

enum AlertSeverity { info, warning }

class RecurringExpense {
  const RecurringExpense({
    required this.merchantName,
    required this.averageAmount,
    required this.frequency,
    required this.currency,
    required this.lastDate,
  });

  final String merchantName;
  final double averageAmount;
  final String frequency;
  final String currency;
  final DateTime lastDate;
}

import 'package:intl/intl.dart';
import 'package:receipt24_shared/receipt24_shared.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InsightsService {
  InsightsService(this._client);

  final SupabaseClient _client;

  Future<InsightsData> computeInsights({
    required String userId,
    InsightsFilter filter = const InsightsFilter(),
  }) async {
    final (from, to) = filter.resolveDateRange();
    final fromStr = from.toIso8601String().split('T').first;
    final toStr = to.toIso8601String().split('T').first;

    var query = _client
        .from('receipts')
        .select(
          'id, merchant_name_raw, total_amount, currency, transaction_date, '
          'receipt_expense_classification(expense_type, business_percentage, '
          'expense_categories(category_name))',
        )
        .eq('consumer_user_id', userId)
        .isFilter('soft_deleted_at', null)
        .gte('transaction_date', fromStr)
        .lte('transaction_date', toStr);

    if (filter.currency != null) {
      query = query.eq('currency', filter.currency!);
    }

    final rows = await query.order('transaction_date');
    var receipts = (rows as List).cast<Map<String, dynamic>>();

    if (filter.merchant != null && filter.merchant!.isNotEmpty) {
      final m = filter.merchant!.toLowerCase();
      receipts = receipts
          .where((r) =>
              (r['merchant_name_raw'] as String? ?? '').toLowerCase().contains(m))
          .toList();
    }

    if (filter.expenseType != null) {
      receipts = receipts.where((r) {
        final type = _expenseType(r);
        return type == filter.expenseType;
      }).toList();
    }

    if (filter.categoryId != null) {
      receipts = receipts.where((r) {
        final classData = r['receipt_expense_classification'];
        if (classData is Map) {
          return classData['expense_category_id'] == filter.categoryId;
        }
        return false;
      }).toList();
    }

    if (receipts.isEmpty) return InsightsData.empty;

    final currency = receipts.first['currency'] as String? ?? 'USD';
    double total = 0;
    double business = 0;
    double personal = 0;

    final weeklyMap = <String, double>{};
    final monthlyMap = <String, double>{};
    final categoryMap = <String, double>{};
    final categoryCount = <String, int>{};
    final merchantMap = <String, double>{};
    final merchantCount = <String, int>{};

    for (final r in receipts) {
      final amount = (r['total_amount'] as num?)?.toDouble() ?? 0;
      final date = DateTime.parse(r['transaction_date'] as String);
      final merchant = r['merchant_name_raw'] as String? ?? 'Unknown';
      final expenseType = _expenseType(r);
      final businessPct = _businessPercentage(r);

      total += amount;
      if (expenseType == 'business') {
        business += amount;
      } else if (expenseType == 'mixed_use') {
        business += amount * businessPct / 100;
        personal += amount * (100 - businessPct) / 100;
      } else {
        personal += amount;
      }

      final weekKey = DateFormat('MMM d').format(
        date.subtract(Duration(days: date.weekday - 1)),
      );
      weeklyMap[weekKey] = (weeklyMap[weekKey] ?? 0) + amount;

      final monthKey = DateFormat('MMM yyyy').format(date);
      monthlyMap[monthKey] = (monthlyMap[monthKey] ?? 0) + amount;

      final category = _categoryName(r);
      categoryMap[category] = (categoryMap[category] ?? 0) + amount;
      categoryCount[category] = (categoryCount[category] ?? 0) + 1;

      merchantMap[merchant] = (merchantMap[merchant] ?? 0) + amount;
      merchantCount[merchant] = (merchantCount[merchant] ?? 0) + 1;
    }

    final categoryBreakdown = _buildBreakdown(categoryMap, categoryCount, total);
    final merchantBreakdown = _buildBreakdown(merchantMap, merchantCount, total);

    final weeklySpending = weeklyMap.entries
        .map((e) => PeriodSpending(label: e.key, amount: e.value))
        .toList();
    final monthlySpending = monthlyMap.entries
        .map((e) => PeriodSpending(label: e.key, amount: e.value))
        .toList();

    final momChange = await _monthOverMonthChange(userId, filter);
    final alerts = _detectAlerts(receipts, categoryMap, merchantMap);
    final recurring = _detectRecurring(receipts);
    final subscriptions = recurring
        .where((r) => _isLikelySubscription(r.merchantName))
        .toList();

    return InsightsData(
      totalSpending: total,
      businessTotal: business,
      personalTotal: personal,
      receiptCount: receipts.length,
      currency: currency,
      weeklySpending: weeklySpending,
      monthlySpending: monthlySpending,
      categoryBreakdown: categoryBreakdown,
      merchantBreakdown: merchantBreakdown,
      monthOverMonthChange: momChange,
      alerts: alerts,
      recurringExpenses: recurring,
      subscriptions: subscriptions,
    );
  }

  String _expenseType(Map<String, dynamic> receipt) {
    final classData = receipt['receipt_expense_classification'];
    if (classData is Map) {
      return classData['expense_type'] as String? ?? 'personal';
    }
    return 'personal';
  }

  double _businessPercentage(Map<String, dynamic> receipt) {
    final classData = receipt['receipt_expense_classification'];
    if (classData is Map) {
      return (classData['business_percentage'] as num?)?.toDouble() ?? 0;
    }
    return 0;
  }

  String _categoryName(Map<String, dynamic> receipt) {
    final classData = receipt['receipt_expense_classification'];
    if (classData is Map) {
      final cats = classData['expense_categories'];
      if (cats is Map) return cats['category_name'] as String? ?? 'Uncategorised';
    }
    return 'Uncategorised';
  }

  List<BreakdownItem> _buildBreakdown(
    Map<String, double> amounts,
    Map<String, int> counts,
    double total,
  ) {
    return amounts.entries.map((e) {
      return BreakdownItem(
        name: e.key,
        amount: e.value,
        count: counts[e.key] ?? 0,
        percentage: total > 0 ? (e.value / total) * 100 : 0,
      );
    }).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
  }

  Future<double> _monthOverMonthChange(
    String userId,
    InsightsFilter filter,
  ) async {
    final now = DateTime.now();
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);
    final lastMonthEnd = DateTime(now.year, now.month, 0);

    final thisTotal = await _sumForPeriod(
      userId,
      thisMonthStart,
      now,
      filter,
    );
    final lastTotal = await _sumForPeriod(
      userId,
      lastMonthStart,
      lastMonthEnd,
      filter,
    );

    if (lastTotal == 0) return 0;
    return ((thisTotal - lastTotal) / lastTotal) * 100;
  }

  Future<double> _sumForPeriod(
    String userId,
    DateTime from,
    DateTime to,
    InsightsFilter filter,
  ) async {
    final rows = await _client
        .from('receipts')
        .select('total_amount')
        .eq('consumer_user_id', userId)
        .isFilter('soft_deleted_at', null)
        .gte('transaction_date', from.toIso8601String().split('T').first)
        .lte('transaction_date', to.toIso8601String().split('T').first);

    return (rows as List)
        .fold<double>(0, (sum, r) => sum + ((r['total_amount'] as num?)?.toDouble() ?? 0));
  }

  List<SpendingAlert> _detectAlerts(
    List<Map<String, dynamic>> receipts,
    Map<String, double> categoryMap,
    Map<String, double> merchantMap,
  ) {
    final alerts = <SpendingAlert>[];

    if (receipts.isEmpty) return alerts;

    final total = receipts.fold<double>(
      0,
      (s, r) => s + ((r['total_amount'] as num?)?.toDouble() ?? 0),
    );
    final avg = total / receipts.length;

    for (final r in receipts) {
      final amount = (r['total_amount'] as num?)?.toDouble() ?? 0;
      final merchant = r['merchant_name_raw'] as String? ?? 'Unknown';
      if (amount > avg * 2.5) {
        alerts.add(SpendingAlert(
          title: 'Unusual spending',
          message:
              '$merchant: ${amount.toStringAsFixed(2)} is higher than your typical receipt',
          severity: AlertSeverity.warning,
        ));
      }
    }

    for (final entry in categoryMap.entries) {
      if (entry.value > total * 0.5 && categoryMap.length > 2) {
        alerts.add(SpendingAlert(
          title: 'Category concentration',
          message:
              '${entry.key} accounts for ${(entry.value / total * 100).toStringAsFixed(0)}% of spending',
          severity: AlertSeverity.info,
        ));
      }
    }

    return alerts.take(5).toList();
  }

  List<RecurringExpense> _detectRecurring(List<Map<String, dynamic>> receipts) {
    final byMerchant = <String, List<Map<String, dynamic>>>{};
    for (final r in receipts) {
      final m = r['merchant_name_raw'] as String? ?? 'Unknown';
      byMerchant.putIfAbsent(m, () => []).add(r);
    }

    final recurring = <RecurringExpense>[];
    for (final entry in byMerchant.entries) {
      if (entry.value.length < 2) continue;

      final amounts = entry.value
          .map((r) => (r['total_amount'] as num?)?.toDouble() ?? 0)
          .toList();
      final avg = amounts.reduce((a, b) => a + b) / amounts.length;
      final variance = amounts.every((a) => (a - avg).abs() / avg < 0.15);

      if (variance) {
        final dates = entry.value
            .map((r) => DateTime.parse(r['transaction_date'] as String))
            .toList()
          ..sort();
        final daysBetween = dates.length > 1
            ? dates.last.difference(dates.first).inDays / (dates.length - 1)
            : 0;

        String frequency = 'Irregular';
        if (daysBetween >= 25 && daysBetween <= 35) frequency = 'Monthly';
        if (daysBetween >= 6 && daysBetween <= 8) frequency = 'Weekly';

        recurring.add(RecurringExpense(
          merchantName: entry.key,
          averageAmount: avg,
          frequency: frequency,
          currency: entry.value.first['currency'] as String? ?? 'USD',
          lastDate: dates.last,
        ));
      }
    }

    return recurring..sort((a, b) => b.averageAmount.compareTo(a.averageAmount));
  }

  bool _isLikelySubscription(String merchant) {
    final lower = merchant.toLowerCase();
    const keywords = [
      'netflix', 'spotify', 'apple', 'google', 'microsoft',
      'adobe', 'amazon prime', 'dstv', 'showmax', 'youtube',
      'gym', 'fitness', 'insurance', 'subscription',
    ];
    return keywords.any((k) => lower.contains(k));
  }
}

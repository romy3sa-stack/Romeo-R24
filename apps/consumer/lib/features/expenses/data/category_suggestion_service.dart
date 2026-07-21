import 'package:receipt24_shared/receipt24_shared.dart';

/// Rule-based category suggestion engine.
/// Uses merchant keywords, item names, and past user corrections.
class CategorySuggestionService {
  static const _merchantRules = <String, String>{
    'shell': 'Fuel',
    'bp': 'Fuel',
    'engen': 'Fuel',
    'sasol': 'Fuel',
    'checkers': 'Groceries',
    'pick n pay': 'Groceries',
    'woolworths': 'Groceries',
    'spar': 'Groceries',
    'shoprite': 'Groceries',
    'uber': 'Transport',
    'bolt': 'Transport',
    'netflix': 'Entertainment',
    'spotify': 'Entertainment',
    'mcdonald': 'Restaurants',
    'kfc': 'Restaurants',
    'starbucks': 'Restaurants',
    'office': 'Office Supplies',
    'staples': 'Office Supplies',
    'hotel': 'Accommodation',
    'airbnb': 'Accommodation',
    'pharmacy': 'Medical',
    'clicks': 'Medical',
    'dischem': 'Medical',
    'vodacom': 'Communication',
    'mtn': 'Communication',
    'telkom': 'Communication',
  };

  static const _itemRules = <String, String>{
    'fuel': 'Fuel',
    'petrol': 'Fuel',
    'diesel': 'Fuel',
    'coffee': 'Restaurants',
    'lunch': 'Restaurants',
    'dinner': 'Restaurants',
    'paper': 'Office Supplies',
    'ink': 'Office Supplies',
    'hotel': 'Accommodation',
  };

  CategorySuggestion? suggest({
    required List<ExpenseCategoryModel> categories,
    String? merchantName,
    List<ReceiptItemModel> items = const [],
    List<ExpenseClassificationModel> pastConfirmations = const [],
  }) {
    if (categories.isEmpty) return null;

    final merchant = merchantName?.toLowerCase() ?? '';
    final scores = <String, double>{};
    final reasons = <String, String>{};

    // Learn from past user-confirmed classifications for this merchant
    for (final past in pastConfirmations) {
      if (past.categoryName != null &&
          past.userConfirmed &&
          merchant.isNotEmpty) {
        final cat = _findCategory(categories, past.categoryName!);
        if (cat != null) {
          scores[cat.id] = (scores[cat.id] ?? 0) + 40;
          reasons[cat.id] = 'You previously categorised this merchant as ${past.categoryName}';
        }
      }
    }

    // Merchant keyword rules
    for (final entry in _merchantRules.entries) {
      if (merchant.contains(entry.key)) {
        final cat = _findCategory(categories, entry.value);
        if (cat != null) {
          scores[cat.id] = (scores[cat.id] ?? 0) + 35;
          reasons[cat.id] = 'Merchant name matches ${entry.value}';
        }
      }
    }

    // Item keyword rules
    for (final item in items) {
      final name = item.itemName.toLowerCase();
      for (final entry in _itemRules.entries) {
        if (name.contains(entry.key)) {
          final cat = _findCategory(categories, entry.value);
          if (cat != null) {
            scores[cat.id] = (scores[cat.id] ?? 0) + 20;
            reasons[cat.id] = 'Item "${item.itemName}" suggests ${entry.value}';
          }
        }
      }
    }

    if (scores.isEmpty) {
      final groceries = _findCategory(categories, 'Groceries');
      if (groceries != null && merchant.contains('store')) {
        return CategorySuggestion(
          categoryId: groceries.id,
          categoryName: groceries.categoryName,
          confidenceScore: 45,
          reason: 'Generic store purchase',
        );
      }
      return null;
    }

    final bestId = scores.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    final bestCat = categories.firstWhere((c) => c.id == bestId);
    final rawScore = scores[bestId]!.clamp(0, 100);

    return CategorySuggestion(
      categoryId: bestCat.id,
      categoryName: bestCat.categoryName,
      confidenceScore: rawScore,
      reason: reasons[bestId] ?? 'Automatic categorisation',
    );
  }

  ExpenseCategoryModel? _findCategory(
    List<ExpenseCategoryModel> categories,
    String name,
  ) {
    try {
      return categories.firstWhere(
        (c) => c.categoryName.toLowerCase() == name.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }
}

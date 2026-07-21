/// Expense category from the database.
class ExpenseCategoryModel {
  const ExpenseCategoryModel({
    required this.id,
    required this.categoryName,
    required this.categoryCode,
    this.taxDeductible = false,
    this.vatEligible = false,
    this.description,
  });

  final String id;
  final String categoryName;
  final String categoryCode;
  final bool taxDeductible;
  final bool vatEligible;
  final String? description;

  factory ExpenseCategoryModel.fromJson(Map<String, dynamic> json) {
    return ExpenseCategoryModel(
      id: json['id'] as String,
      categoryName: json['category_name'] as String,
      categoryCode: json['category_code'] as String,
      taxDeductible: json['tax_deductible'] as bool? ?? false,
      vatEligible: json['vat_eligible'] as bool? ?? false,
      description: json['description'] as String?,
    );
  }
}

/// Expense classification for a receipt.
class ExpenseClassificationModel {
  const ExpenseClassificationModel({
    this.id,
    required this.receiptId,
    required this.consumerUserId,
    this.expenseCategoryId,
    this.categoryName,
    this.classificationSource = 'automatic',
    this.confidenceScore,
    this.userConfirmed = false,
    this.expenseType = 'personal',
    this.businessPercentage = 0,
    this.notes,
  });

  final String? id;
  final String receiptId;
  final String consumerUserId;
  final String? expenseCategoryId;
  final String? categoryName;
  final String classificationSource;
  final double? confidenceScore;
  final bool userConfirmed;
  final String expenseType;
  final double businessPercentage;
  final String? notes;

  bool get isBusiness =>
      expenseType == 'business' || expenseType == 'mixed_use';

  factory ExpenseClassificationModel.fromJson(Map<String, dynamic> json) {
    final category = json['expense_categories'];
    return ExpenseClassificationModel(
      id: json['id'] as String?,
      receiptId: json['receipt_id'] as String,
      consumerUserId: json['consumer_user_id'] as String,
      expenseCategoryId: json['expense_category_id'] as String?,
      categoryName: category is Map
          ? category['category_name'] as String?
          : null,
      classificationSource: json['classification_source'] as String? ?? 'automatic',
      confidenceScore: (json['confidence_score'] as num?)?.toDouble(),
      userConfirmed: json['user_confirmed'] as bool? ?? false,
      expenseType: json['expense_type'] as String? ?? 'personal',
      businessPercentage: (json['business_percentage'] as num?)?.toDouble() ?? 0,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toUpsertJson() {
    return {
      'receipt_id': receiptId,
      'consumer_user_id': consumerUserId,
      'expense_category_id': expenseCategoryId,
      'classification_source': classificationSource,
      'confidence_score': confidenceScore,
      'user_confirmed': userConfirmed,
      'expense_type': expenseType,
      'business_percentage': businessPercentage,
      'notes': notes,
    };
  }
}

/// Suggested expense category with confidence and reason.
class CategorySuggestion {
  const CategorySuggestion({
    required this.categoryId,
    required this.categoryName,
    required this.confidenceScore,
    required this.reason,
  });

  final String categoryId;
  final String categoryName;
  final double confidenceScore;
  final String reason;
}

enum ExpenseType {
  personal('personal'),
  business('business'),
  mixedUse('mixed_use');

  const ExpenseType(this.value);
  final String value;

  static ExpenseType fromString(String value) {
    return ExpenseType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ExpenseType.personal,
    );
  }
}

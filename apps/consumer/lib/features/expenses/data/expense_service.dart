import 'package:receipt24_shared/receipt24_shared.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'category_suggestion_service.dart';

class ExpenseService {
  ExpenseService(this._client, this._suggestionService);

  final SupabaseClient _client;
  final CategorySuggestionService _suggestionService;

  Future<List<ExpenseCategoryModel>> fetchExpenseCategories() async {
    final rows =
        await _client.from('expense_categories').select().order('category_name');
    return (rows as List)
        .map((r) => ExpenseCategoryModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<ExpenseClassificationModel?> getClassification(String receiptId) async {
    final row = await _client
        .from('receipt_expense_classification')
        .select('*, expense_categories(category_name)')
        .eq('receipt_id', receiptId)
        .maybeSingle();
    if (row == null) return null;
    return ExpenseClassificationModel.fromJson(row);
  }

  Future<List<ExpenseClassificationModel>> getPastConfirmations(
    String userId,
    String merchantName,
  ) async {
    final rows = await _client
        .from('receipt_expense_classification')
        .select('*, expense_categories(category_name)')
        .eq('consumer_user_id', userId)
        .eq('user_confirmed', true)
        .order('created_at', ascending: false)
        .limit(20);

    return (rows as List)
        .map((r) => ExpenseClassificationModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<CategorySuggestion?> suggestCategory({
    required String userId,
    required String? merchantName,
    List<ReceiptItemModel> items = const [],
  }) async {
    final categories = await fetchExpenseCategories();
    final past = merchantName != null
        ? await getPastConfirmations(userId, merchantName)
        : <ExpenseClassificationModel>[];

    return _suggestionService.suggest(
      categories: categories,
      merchantName: merchantName,
      items: items,
      pastConfirmations: past,
    );
  }

  Future<ExpenseClassificationModel> saveClassification({
    required String receiptId,
    required String userId,
    String? expenseCategoryId,
    required String expenseType,
    double businessPercentage = 0,
    bool userConfirmed = true,
    String classificationSource = 'user_confirmed',
    double? confidenceScore,
    String? notes,
  }) async {
    final data = {
      'receipt_id': receiptId,
      'consumer_user_id': userId,
      'expense_category_id': expenseCategoryId,
      'expense_type': expenseType,
      'business_percentage': expenseType == 'mixed_use' ? businessPercentage : 0,
      'user_confirmed': userConfirmed,
      'classification_source': classificationSource,
      'confidence_score': confidenceScore,
      'notes': notes,
    };

    final existing = await _client
        .from('receipt_expense_classification')
        .select('id')
        .eq('receipt_id', receiptId)
        .maybeSingle();

    final Map<String, dynamic> row;
    if (existing != null) {
      row = await _client
          .from('receipt_expense_classification')
          .update(data)
          .eq('receipt_id', receiptId)
          .select('*, expense_categories(category_name)')
          .single();
    } else {
      row = await _client
          .from('receipt_expense_classification')
          .insert(data)
          .select('*, expense_categories(category_name)')
          .single();
    }

    return ExpenseClassificationModel.fromJson(row);
  }

  Future<void> autoClassifyReceipt({
    required String receiptId,
    required String userId,
    required String? merchantName,
    List<ReceiptItemModel> items = const [],
  }) async {
    final suggestion = await suggestCategory(
      userId: userId,
      merchantName: merchantName,
      items: items,
    );
    if (suggestion == null) return;

    await saveClassification(
      receiptId: receiptId,
      userId: userId,
      expenseCategoryId: suggestion.categoryId,
      expenseType: 'personal',
      userConfirmed: false,
      classificationSource: 'ai_suggested',
      confidenceScore: suggestion.confidenceScore,
      notes: suggestion.reason,
    );
  }

  Future<List<ReceiptModel>> fetchDuplicateReceipts(String userId) async {
    final rows = await _client
        .from('receipts')
        .select('*, receipt_categories(category_name)')
        .eq('consumer_user_id', userId)
        .eq('is_duplicate_flagged', true)
        .isFilter('soft_deleted_at', null)
        .order('created_at', ascending: false);

    return (rows as List)
        .map((r) => ReceiptModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> dismissDuplicateFlag(String receiptId) async {
    await _client.from('receipts').update({
      'is_duplicate_flagged': false,
      'duplicate_of_receipt_id': null,
    }).eq('id', receiptId);
  }

  Future<int> countDuplicateAlerts(String userId) async {
    final rows = await _client
        .from('receipts')
        .select('id')
        .eq('consumer_user_id', userId)
        .eq('is_duplicate_flagged', true)
        .isFilter('soft_deleted_at', null);
    return (rows as List).length;
  }
}

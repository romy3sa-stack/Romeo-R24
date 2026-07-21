import 'package:receipt24_shared/receipt24_shared.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountantReceiptService {
  AccountantReceiptService(this._client);

  final SupabaseClient _client;

  Future<List<ReceiptModel>> fetchClientReceipts({
    required String consumerUserId,
    int limit = 100,
  }) async {
    final rows = await _client
        .from('receipts')
        .select(
          '*, receipt_expense_classification(*, expense_categories(category_name))',
        )
        .eq('consumer_user_id', consumerUserId)
        .isFilter('soft_deleted_at', null)
        .order('transaction_date', ascending: false)
        .limit(limit);

    return (rows as List)
        .map((r) => _parseReceiptRow(r as Map<String, dynamic>))
        .toList();
  }

  Future<ReceiptModel?> fetchReceipt(String receiptId) async {
    final row = await _client
        .from('receipts')
        .select(
          '*, receipt_items(*), '
          'receipt_expense_classification(*, expense_categories(category_name))',
        )
        .eq('id', receiptId)
        .maybeSingle();
    if (row == null) return null;
    return _parseReceiptRow(row);
  }

  Future<void> updateReceiptNotes(String receiptId, String notes) async {
    await _client.from('receipts').update({'notes': notes}).eq('id', receiptId);
  }

  Future<ExpenseClassificationModel> saveClassification({
    required String receiptId,
    required String consumerUserId,
    String? expenseCategoryId,
    required String expenseType,
    double businessPercentage = 0,
    String? notes,
  }) async {
    final data = {
      'receipt_id': receiptId,
      'consumer_user_id': consumerUserId,
      'expense_category_id': expenseCategoryId,
      'expense_type': expenseType,
      'business_percentage':
          expenseType == 'mixed_use' ? businessPercentage : 0,
      'user_confirmed': true,
      'classification_source': 'accountant',
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

  Future<List<ExpenseCategoryModel>> fetchExpenseCategories() async {
    final rows =
        await _client.from('expense_categories').select().order('category_name');
    return (rows as List)
        .map((r) => ExpenseCategoryModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  ReceiptModel _parseReceiptRow(Map<String, dynamic> json) {
    ExpenseClassificationModel? classification;
    final classData = json['receipt_expense_classification'];
    if (classData is Map<String, dynamic>) {
      classification = ExpenseClassificationModel.fromJson(classData);
    } else if (classData is List && classData.isNotEmpty) {
      classification = ExpenseClassificationModel.fromJson(
        classData.first as Map<String, dynamic>,
      );
    }

    final receipt = ReceiptModel.fromJson(json);
    List<ReceiptItemModel> items = receipt.items;
    final itemsData = json['receipt_items'];
    if (itemsData is List) {
      items = itemsData
          .map((i) => ReceiptItemModel.fromJson(i as Map<String, dynamic>))
          .toList();
    }

    return ReceiptModel(
      id: receipt.id,
      consumerUserId: receipt.consumerUserId,
      merchantNameRaw: receipt.merchantNameRaw,
      receiptNumber: receipt.receiptNumber,
      transactionDate: receipt.transactionDate,
      totalAmount: receipt.totalAmount,
      currency: receipt.currency,
      paymentMethod: receipt.paymentMethod,
      receiptSource: receipt.receiptSource,
      notes: receipt.notes,
      expenseClassification: classification,
      items: items,
      createdAt: receipt.createdAt,
    );
  }
}

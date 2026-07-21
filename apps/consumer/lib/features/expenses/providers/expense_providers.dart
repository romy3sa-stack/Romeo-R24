import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receipt24_shared/receipt24_shared.dart';

import '../../../core/auth/auth_providers.dart';
import '../data/category_suggestion_service.dart';
import '../data/expense_service.dart';

final categorySuggestionServiceProvider =
    Provider<CategorySuggestionService>((ref) {
  return CategorySuggestionService();
});

final expenseServiceProvider = Provider<ExpenseService>((ref) {
  return ExpenseService(
    ref.watch(supabaseClientProvider),
    ref.watch(categorySuggestionServiceProvider),
  );
});

final expenseCategoriesProvider =
    FutureProvider.autoDispose<List<ExpenseCategoryModel>>((ref) {
  return ref.read(expenseServiceProvider).fetchExpenseCategories();
});

final expenseClassificationProvider =
    FutureProvider.autoDispose.family<ExpenseClassificationModel?, String>(
        (ref, receiptId) {
  return ref.read(expenseServiceProvider).getClassification(receiptId);
});

final duplicateReceiptsProvider =
    FutureProvider.autoDispose<List<ReceiptModel>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.read(expenseServiceProvider).fetchDuplicateReceipts(user.id);
});

final duplicateCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 0;
  return ref.read(expenseServiceProvider).countDuplicateAlerts(user.id);
});

final categorySuggestionProvider = FutureProvider.autoDispose
    .family<CategorySuggestion?, ({String? merchant, List<ReceiptItemModel> items})>(
        (ref, params) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return ref.read(expenseServiceProvider).suggestCategory(
        userId: user.id,
        merchantName: params.merchant,
        items: params.items,
      );
});

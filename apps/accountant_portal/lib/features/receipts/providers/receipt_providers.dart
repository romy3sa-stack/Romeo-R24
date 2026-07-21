import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receipt24_shared/receipt24_shared.dart';

import '../../../core/auth/auth_providers.dart';
import '../data/accountant_receipt_service.dart';

final accountantReceiptServiceProvider =
    Provider<AccountantReceiptService>((ref) {
  return AccountantReceiptService(ref.watch(supabaseClientProvider));
});

final clientReceiptsProvider = FutureProvider.autoDispose
    .family<List<ReceiptModel>, String>((ref, consumerUserId) {
  return ref
      .read(accountantReceiptServiceProvider)
      .fetchClientReceipts(consumerUserId: consumerUserId);
});

final accountantReceiptDetailProvider =
    FutureProvider.autoDispose.family<ReceiptModel?, String>((ref, receiptId) {
  return ref.read(accountantReceiptServiceProvider).fetchReceipt(receiptId);
});

final expenseCategoriesProvider =
    FutureProvider.autoDispose<List<ExpenseCategoryModel>>((ref) {
  return ref.read(accountantReceiptServiceProvider).fetchExpenseCategories();
});

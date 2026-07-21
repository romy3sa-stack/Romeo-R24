import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receipt24_shared/receipt24_shared.dart';

import '../../../core/auth/auth_providers.dart';
import '../../warranties/providers/warranty_return_providers.dart';
import 'ocr_service.dart';
import 'receipt_service.dart';

final ocrServiceProvider = Provider<OcrService>((ref) {
  return OcrService(useMock: true);
});

final receiptServiceProvider = Provider<ReceiptService>((ref) {
  return ReceiptService(
    ref.watch(supabaseClientProvider),
    ref.watch(ocrServiceProvider),
  );
});

final receiptFilterProvider =
    StateProvider<ReceiptFilter>((ref) => const ReceiptFilter());

final receiptsListProvider =
    FutureProvider.autoDispose<List<ReceiptModel>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  final filter = ref.watch(receiptFilterProvider);
  return ref.read(receiptServiceProvider).fetchReceipts(
        userId: user.id,
        filter: filter,
      );
});

final receiptDetailProvider =
    FutureProvider.autoDispose.family<ReceiptModel?, String>((ref, id) {
  return ref.read(receiptServiceProvider).fetchReceipt(id);
});

final receiptCategoriesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return ref.read(receiptServiceProvider).fetchCategories();
});

final emailForwardingProvider = FutureProvider.autoDispose<String?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return ref.read(receiptServiceProvider).getEmailForwardingAddress(user.id);
});

final homeStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return {};
  final baseStats = await ref.read(authServiceProvider).getHomeStats(user.id);
  final warrantyStats = await ref.read(warrantyReturnStatsProvider.future);
  return {
    ...baseStats,
    'activeWarranties': warrantyStats['warranties'] ?? 0,
    'returnDeadlines': warrantyStats['returns'] ?? 0,
  };
});

/// Holds pending OCR data between capture and review screens.
class PendingReceiptCapture {
  const PendingReceiptCapture({
    required this.extraction,
    required this.receiptSource,
    this.imagePath,
    this.pdfPath,
    this.bucket = 'receipt-uploads',
    this.uploadId,
    this.previewBytes,
  });

  final OcrExtractionResult extraction;
  final String receiptSource;
  final String? imagePath;
  final String? pdfPath;
  final String bucket;
  final String? uploadId;
  final Uint8List? previewBytes;
}

final pendingCaptureProvider =
    StateProvider<PendingReceiptCapture?>((ref) => null);

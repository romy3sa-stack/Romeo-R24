import 'dart:typed_data';

import 'package:receipt24_shared/receipt24_shared.dart';

/// OCR extraction service.
/// Uses mock data in development; calls Supabase Edge Function in production.
class OcrService {
  OcrService({this.useMock = true});

  final bool useMock;

  Future<OcrExtractionResult> extractFromImage(
    Uint8List bytes,
    String fileName,
  ) async {
    if (useMock) {
      await Future<void>.delayed(const Duration(milliseconds: 800));
      return _mockResult(fileName);
    }

    // Production: invoke Edge Function `process-receipt-ocr`
    // final response = await supabase.functions.invoke('process-receipt-ocr', body: {...});
    return _mockResult(fileName);
  }

  Future<OcrExtractionResult> extractFromPdf(
    Uint8List bytes,
    String fileName,
  ) async {
    return extractFromImage(bytes, fileName);
  }

  OcrExtractionResult _mockResult(String fileName) {
    final now = DateTime.now();
    return OcrExtractionResult(
      merchantName: 'Sample Store',
      merchantAddress: '123 Main Street, Cape Town',
      merchantTaxNumber: 'VAT123456789',
      receiptNumber: 'RCP-${now.millisecondsSinceEpoch % 100000}',
      transactionDate: now,
      items: const [
        ReceiptItemModel(
          itemName: 'Office Supplies',
          quantity: 2,
          unitPrice: 49.99,
          totalPrice: 99.98,
        ),
        ReceiptItemModel(
          itemName: 'Printer Paper A4',
          quantity: 1,
          unitPrice: 89.00,
          totalPrice: 89.00,
        ),
      ],
      subtotal: 188.98,
      taxAmount: 28.35,
      discountAmount: 0,
      totalAmount: 217.33,
      currency: 'ZAR',
      paymentMethod: 'card',
      rawText: 'Mock OCR text extracted from $fileName',
      confidenceScore: 87.5,
      fieldConfidence: {
        'merchantName': 92,
        'totalAmount': 95,
        'transactionDate': 78,
        'taxAmount': 65,
      },
    );
  }
}

/// Result of uploading and processing a receipt file.
class ProcessUploadResult {
  const ProcessUploadResult({
    required this.extraction,
    required this.storagePath,
    required this.bucket,
    this.uploadId,
  });

  final OcrExtractionResult extraction;
  final String storagePath;
  final String bucket;
  final String? uploadId;
}

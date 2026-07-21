import 'dart:typed_data';

import 'package:receipt24_shared/receipt24_shared.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'ocr_service.dart';

class ReceiptService {
  ReceiptService(this._client, this._ocr);

  final SupabaseClient _client;
  final OcrService _ocr;
  final _uuid = const Uuid();

  Future<List<ReceiptModel>> fetchReceipts({
    required String userId,
    ReceiptFilter filter = const ReceiptFilter(),
    int limit = 50,
  }) async {
    var query = _client
        .from('receipts')
        .select('*, receipt_categories(category_name)')
        .eq('consumer_user_id', userId)
        .isFilter('soft_deleted_at', null);

    if (filter.dateFrom != null) {
      query = query.gte(
        'transaction_date',
        filter.dateFrom!.toIso8601String().split('T').first,
      );
    }
    if (filter.dateTo != null) {
      query = query.lte(
        'transaction_date',
        filter.dateTo!.toIso8601String().split('T').first,
      );
    }
    if (filter.categoryId != null) {
      query = query.eq('receipt_category_id', filter.categoryId!);
    }
    if (filter.paymentMethod != null) {
      query = query.eq('payment_method', filter.paymentMethod!);
    }
    if (filter.receiptSource != null) {
      query = query.eq('receipt_source', filter.receiptSource!);
    }
    if (filter.warrantyOnly) {
      query = query.eq('warranty_available', true);
    }

    final orderColumn = switch (filter.sortBy) {
      ReceiptSort.oldest => 'created_at',
      ReceiptSort.highestAmount => 'total_amount',
      ReceiptSort.lowestAmount => 'total_amount',
      ReceiptSort.newest => 'created_at',
    };
    final ascending = filter.sortBy == ReceiptSort.oldest ||
        filter.sortBy == ReceiptSort.lowestAmount;

    final rows = await query.order(orderColumn, ascending: ascending).limit(limit);
    var receipts = (rows as List)
        .map((r) => ReceiptModel.fromJson(r as Map<String, dynamic>))
        .toList();

    if (filter.searchQuery.isNotEmpty) {
      final q = filter.searchQuery.toLowerCase();
      receipts = receipts
          .where((r) =>
              r.displayMerchant.toLowerCase().contains(q) ||
              (r.receiptNumber?.toLowerCase().contains(q) ?? false))
          .toList();
    }

    if (filter.minAmount != null) {
      receipts = receipts
          .where((r) => (r.totalAmount ?? 0) >= filter.minAmount!)
          .toList();
    }
    if (filter.maxAmount != null) {
      receipts = receipts
          .where((r) => (r.totalAmount ?? 0) <= filter.maxAmount!)
          .toList();
    }

    return receipts;
  }

  Future<ReceiptModel?> fetchReceipt(String receiptId) async {
    final row = await _client
        .from('receipts')
        .select('*, receipt_categories(category_name)')
        .eq('id', receiptId)
        .maybeSingle();
    if (row == null) return null;

    final items = await _client
        .from('receipt_items')
        .select()
        .eq('receipt_id', receiptId);

    final receipt = ReceiptModel.fromJson(row);
    return ReceiptModel(
      id: receipt.id,
      consumerUserId: receipt.consumerUserId,
      merchantId: receipt.merchantId,
      merchantNameRaw: receipt.merchantNameRaw,
      receiptNumber: receipt.receiptNumber,
      transactionReference: receipt.transactionReference,
      transactionDate: receipt.transactionDate,
      subtotal: receipt.subtotal,
      taxAmount: receipt.taxAmount,
      discountAmount: receipt.discountAmount,
      totalAmount: receipt.totalAmount,
      currency: receipt.currency,
      paymentMethod: receipt.paymentMethod,
      receiptSource: receipt.receiptSource,
      receiptStatus: receipt.receiptStatus,
      receiptFileUrl: receipt.receiptFileUrl,
      receiptImageUrl: receipt.receiptImageUrl,
      receiptCategoryId: receipt.receiptCategoryId,
      categoryName: receipt.categoryName,
      ocrStatus: receipt.ocrStatus,
      ocrConfidenceScore: receipt.ocrConfidenceScore,
      verificationStatus: receipt.verificationStatus,
      warrantyAvailable: receipt.warrantyAvailable,
      returnDeadline: receipt.returnDeadline,
      notes: receipt.notes,
      isDuplicateFlagged: receipt.isDuplicateFlagged,
      items: (items as List)
          .map((i) => ReceiptItemModel.fromJson(i as Map<String, dynamic>))
          .toList(),
      createdAt: receipt.createdAt,
    );
  }

  Future<List<Map<String, dynamic>>> fetchCategories() async {
    final rows = await _client.from('receipt_categories').select().order('category_name');
    return (rows as List).cast<Map<String, dynamic>>();
  }

  Future<String?> getEmailForwardingAddress(String userId) async {
    final row = await _client
        .from('consumer_profiles')
        .select('email_forwarding_address')
        .eq('user_id', userId)
        .maybeSingle();
    return row?['email_forwarding_address'] as String?;
  }

  Future<String> uploadFile({
    required String userId,
    required Uint8List bytes,
    required String fileName,
    required String bucket,
  }) async {
    final path = '$userId/${_uuid.v4()}_$fileName';
    await _client.storage.from(bucket).uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
    return path;
  }

  Future<ProcessUploadResult> processUpload({
    required String userId,
    required Uint8List bytes,
    required String fileName,
    required String receiptSource,
    required String uploadSource,
    required String fileType,
    required String bucket,
  }) async {
    final storagePath = await uploadFile(
      userId: userId,
      bytes: bytes,
      fileName: fileName,
      bucket: bucket,
    );

    final uploadRow = await _client
        .from('receipt_uploads')
        .insert({
          'user_id': userId,
          'file_url': storagePath,
          'file_type': fileType,
          'upload_source': uploadSource,
          'ocr_status': 'processing',
          'processing_status': 'processing',
        })
        .select()
        .single();

    final ocrResult = fileType == 'application_pdf'
        ? await _ocr.extractFromPdf(bytes, fileName)
        : await _ocr.extractFromImage(bytes, fileName);

    await _client.from('receipt_uploads').update({
      'ocr_status': 'completed',
      'ocr_raw_text': ocrResult.rawText,
      'processing_status': 'completed',
    }).eq('id', uploadRow['id']);

    return ProcessUploadResult(
      extraction: ocrResult,
      storagePath: storagePath,
      bucket: bucket,
      uploadId: uploadRow['id'] as String,
    );
  }

  Future<ReceiptModel> saveReceipt({
    required String userId,
    required OcrExtractionResult extraction,
    required String receiptSource,
    String? imagePath,
    String? pdfPath,
    String? uploadId,
    String status = 'confirmed',
  }) async {
    final merchantId = await _findOrCreateMerchant(
      userId: userId,
      name: extraction.merchantName,
      address: extraction.merchantAddress,
      taxNumber: extraction.merchantTaxNumber,
    );

    final receiptData = {
      'consumer_user_id': userId,
      'merchant_id': merchantId,
      'merchant_name_raw': extraction.merchantName,
      'receipt_number': extraction.receiptNumber,
      'transaction_date':
          extraction.transactionDate?.toIso8601String().split('T').first,
      'subtotal': extraction.subtotal,
      'tax_amount': extraction.taxAmount,
      'discount_amount': extraction.discountAmount ?? 0,
      'total_amount': extraction.totalAmount,
      'currency': extraction.currency ?? 'USD',
      'payment_method': extraction.paymentMethod ?? 'unknown',
      'receipt_source': receiptSource,
      'receipt_status': status,
      'receipt_image_url': imagePath,
      'receipt_file_url': pdfPath,
      'ocr_status': 'completed',
      'ocr_confidence_score': extraction.confidenceScore,
      'verification_status': 'unverified',
    };

    final receiptRow = await _client
        .from('receipts')
        .insert(receiptData)
        .select()
        .single();

    final receiptId = receiptRow['id'] as String;

    for (final item in extraction.items) {
      await _client.from('receipt_items').insert(item.toInsertJson(receiptId));
    }

    if (uploadId != null) {
      await _client.from('receipt_uploads').update({
        'linked_receipt_id': receiptId,
      }).eq('id', uploadId);
    }

    await _checkDuplicates(userId, receiptId, extraction);

    final saved = await fetchReceipt(receiptId);
    return saved!;
  }

  Future<String?> _findOrCreateMerchant({
    required String userId,
    String? name,
    String? address,
    String? taxNumber,
  }) async {
    if (name == null || name.isEmpty) return null;

    final existing = await _client
        .from('merchants')
        .select('id')
        .ilike('merchant_name', name)
        .limit(1)
        .maybeSingle();

    if (existing != null) return existing['id'] as String;

    final row = await _client
        .from('merchants')
        .insert({
          'merchant_name': name,
          'address': address,
          'tax_number': taxNumber,
          'merchant_source': 'ocr_scan',
          'created_by_user_id': userId,
        })
        .select()
        .single();

    return row['id'] as String;
  }

  Future<void> _checkDuplicates(
    String userId,
    String receiptId,
    OcrExtractionResult extraction,
  ) async {
    if (extraction.merchantName == null || extraction.totalAmount == null) {
      return;
    }

    final matches = await _client
        .from('receipts')
        .select('id')
        .eq('consumer_user_id', userId)
        .eq('merchant_name_raw', extraction.merchantName!)
        .eq('total_amount', extraction.totalAmount!)
        .neq('id', receiptId)
        .isFilter('soft_deleted_at', null);

    if ((matches as List).isNotEmpty) {
      await _client.from('receipts').update({
        'is_duplicate_flagged': true,
        'duplicate_of_receipt_id': matches.first['id'],
      }).eq('id', receiptId);
    }
  }

  Future<void> updateReceipt(String receiptId, Map<String, dynamic> data) async {
    await _client.from('receipts').update(data).eq('id', receiptId);
  }

  Future<void> softDeleteReceipt(String receiptId) async {
    await _client.from('receipts').update({
      'soft_deleted_at': DateTime.now().toIso8601String(),
    }).eq('id', receiptId);
  }
}

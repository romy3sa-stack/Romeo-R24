/// Receipt data model aligned with the database schema.
class ReceiptModel {
  const ReceiptModel({
    required this.id,
    required this.consumerUserId,
    this.merchantId,
    this.merchantNameRaw,
    this.receiptNumber,
    this.transactionReference,
    this.transactionDate,
    this.subtotal,
    this.taxAmount,
    this.discountAmount,
    this.totalAmount,
    this.currency,
    this.paymentMethod,
    required this.receiptSource,
    required this.receiptStatus,
    this.receiptFileUrl,
    this.receiptImageUrl,
    this.receiptCategoryId,
    this.categoryName,
    this.ocrStatus,
    this.ocrConfidenceScore,
    this.verificationStatus,
    this.warrantyAvailable = false,
    this.returnDeadline,
    this.notes,
    this.isDuplicateFlagged = false,
    this.duplicateOfReceiptId,
    this.expenseClassification,
    this.items = const [],
    this.createdAt,
  });

  final String id;
  final String consumerUserId;
  final String? merchantId;
  final String? merchantNameRaw;
  final String? receiptNumber;
  final String? transactionReference;
  final DateTime? transactionDate;
  final double? subtotal;
  final double? taxAmount;
  final double? discountAmount;
  final double? totalAmount;
  final String? currency;
  final String? paymentMethod;
  final String receiptSource;
  final String receiptStatus;
  final String? receiptFileUrl;
  final String? receiptImageUrl;
  final String? receiptCategoryId;
  final String? categoryName;
  final String? ocrStatus;
  final double? ocrConfidenceScore;
  final String? verificationStatus;
  final bool warrantyAvailable;
  final DateTime? returnDeadline;
  final String? notes;
  final bool isDuplicateFlagged;
  final String? duplicateOfReceiptId;
  final ExpenseClassificationModel? expenseClassification;
  final List<ReceiptItemModel> items;
  final DateTime? createdAt;

  String get displayMerchant => merchantNameRaw ?? 'Unknown merchant';

  factory ReceiptModel.fromJson(Map<String, dynamic> json) {
    return ReceiptModel(
      id: json['id'] as String,
      consumerUserId: json['consumer_user_id'] as String,
      merchantId: json['merchant_id'] as String?,
      merchantNameRaw: json['merchant_name_raw'] as String?,
      receiptNumber: json['receipt_number'] as String?,
      transactionReference: json['transaction_reference'] as String?,
      transactionDate: json['transaction_date'] != null
          ? DateTime.parse(json['transaction_date'] as String)
          : null,
      subtotal: (json['subtotal'] as num?)?.toDouble(),
      taxAmount: (json['tax_amount'] as num?)?.toDouble(),
      discountAmount: (json['discount_amount'] as num?)?.toDouble(),
      totalAmount: (json['total_amount'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
      paymentMethod: json['payment_method'] as String?,
      receiptSource: json['receipt_source'] as String,
      receiptStatus: json['receipt_status'] as String,
      receiptFileUrl: json['receipt_file_url'] as String?,
      receiptImageUrl: json['receipt_image_url'] as String?,
      receiptCategoryId: json['receipt_category_id'] as String?,
      categoryName: json['receipt_categories'] is Map
          ? (json['receipt_categories'] as Map)['category_name'] as String?
          : null,
      ocrStatus: json['ocr_status'] as String?,
      ocrConfidenceScore: (json['ocr_confidence_score'] as num?)?.toDouble(),
      verificationStatus: json['verification_status'] as String?,
      warrantyAvailable: json['warranty_available'] as bool? ?? false,
      returnDeadline: json['return_deadline'] != null
          ? DateTime.parse(json['return_deadline'] as String)
          : null,
      notes: json['notes'] as String?,
      isDuplicateFlagged: json['is_duplicate_flagged'] as bool? ?? false,
      duplicateOfReceiptId: json['duplicate_of_receipt_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'merchant_name_raw': merchantNameRaw,
      'receipt_number': receiptNumber,
      'transaction_reference': transactionReference,
      'transaction_date': transactionDate?.toIso8601String().split('T').first,
      'subtotal': subtotal,
      'tax_amount': taxAmount,
      'discount_amount': discountAmount ?? 0,
      'total_amount': totalAmount,
      'currency': currency ?? 'USD',
      'payment_method': paymentMethod ?? 'unknown',
      'receipt_source': receiptSource,
      'receipt_status': receiptStatus,
      'receipt_file_url': receiptFileUrl,
      'receipt_image_url': receiptImageUrl,
      'receipt_category_id': receiptCategoryId,
      'ocr_status': ocrStatus ?? 'completed',
      'ocr_confidence_score': ocrConfidenceScore,
      'verification_status': verificationStatus ?? 'unverified',
      'warranty_available': warrantyAvailable,
      'return_deadline': returnDeadline?.toIso8601String().split('T').first,
      'notes': notes,
    };
  }
}

class ReceiptItemModel {
  const ReceiptItemModel({
    this.id,
    required this.itemName,
    this.itemDescription,
    this.quantity = 1,
    this.unitPrice,
    this.taxRate,
    this.taxAmount,
    this.discountAmount,
    this.totalPrice,
    this.serialNumber,
    this.warrantyPeriod,
  });

  final String? id;
  final String itemName;
  final String? itemDescription;
  final double quantity;
  final double? unitPrice;
  final double? taxRate;
  final double? taxAmount;
  final double? discountAmount;
  final double? totalPrice;
  final String? serialNumber;
  final int? warrantyPeriod;

  factory ReceiptItemModel.fromJson(Map<String, dynamic> json) {
    return ReceiptItemModel(
      id: json['id'] as String?,
      itemName: json['item_name'] as String,
      itemDescription: json['item_description'] as String?,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1,
      unitPrice: (json['unit_price'] as num?)?.toDouble(),
      taxRate: (json['tax_rate'] as num?)?.toDouble(),
      taxAmount: (json['tax_amount'] as num?)?.toDouble(),
      discountAmount: (json['discount_amount'] as num?)?.toDouble(),
      totalPrice: (json['total_price'] as num?)?.toDouble(),
      serialNumber: json['serial_number'] as String?,
      warrantyPeriod: json['warranty_period'] as int?,
    );
  }

  Map<String, dynamic> toInsertJson(String receiptId) {
    return {
      'receipt_id': receiptId,
      'item_name': itemName,
      'item_description': itemDescription,
      'quantity': quantity,
      'unit_price': unitPrice,
      'tax_rate': taxRate,
      'tax_amount': taxAmount,
      'discount_amount': discountAmount ?? 0,
      'total_price': totalPrice,
      'serial_number': serialNumber,
      'warranty_period': warrantyPeriod,
    };
  }
}

/// Structured OCR extraction result for user review.
class OcrExtractionResult {
  const OcrExtractionResult({
    this.merchantName,
    this.merchantAddress,
    this.merchantTaxNumber,
    this.receiptNumber,
    this.transactionDate,
    this.items = const [],
    this.subtotal,
    this.taxAmount,
    this.discountAmount,
    this.totalAmount,
    this.currency,
    this.paymentMethod,
    this.rawText,
    this.confidenceScore = 0,
    this.fieldConfidence = const {},
  });

  final String? merchantName;
  final String? merchantAddress;
  final String? merchantTaxNumber;
  final String? receiptNumber;
  final DateTime? transactionDate;
  final List<ReceiptItemModel> items;
  final double? subtotal;
  final double? taxAmount;
  final double? discountAmount;
  final double? totalAmount;
  final String? currency;
  final String? paymentMethod;
  final String? rawText;
  final double confidenceScore;
  final Map<String, double> fieldConfidence;

  bool isLowConfidence(String field) =>
      (fieldConfidence[field] ?? confidenceScore) < 70;
}

/// Filter and sort options for the receipt wallet.
class ReceiptFilter {
  const ReceiptFilter({
    this.searchQuery = '',
    this.sortBy = ReceiptSort.newest,
    this.dateFrom,
    this.dateTo,
    this.categoryId,
    this.minAmount,
    this.maxAmount,
    this.paymentMethod,
    this.receiptSource,
    this.warrantyOnly = false,
    this.taxRelevantOnly = false,
    this.expenseType,
    this.expenseCategoryId,
  });

  final String searchQuery;
  final ReceiptSort sortBy;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? categoryId;
  final double? minAmount;
  final double? maxAmount;
  final String? paymentMethod;
  final String? receiptSource;
  final bool warrantyOnly;
  final bool taxRelevantOnly;
  final String? expenseType;
  final String? expenseCategoryId;

  ReceiptFilter copyWith({
    String? searchQuery,
    ReceiptSort? sortBy,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? categoryId,
    double? minAmount,
    double? maxAmount,
    String? paymentMethod,
    String? receiptSource,
    bool? warrantyOnly,
    bool? taxRelevantOnly,
    String? expenseType,
    String? expenseCategoryId,
  }) {
    return ReceiptFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      categoryId: categoryId ?? this.categoryId,
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      receiptSource: receiptSource ?? this.receiptSource,
      warrantyOnly: warrantyOnly ?? this.warrantyOnly,
      taxRelevantOnly: taxRelevantOnly ?? this.taxRelevantOnly,
      expenseType: expenseType ?? this.expenseType,
      expenseCategoryId: expenseCategoryId ?? this.expenseCategoryId,
    );
  }
}

enum ReceiptSort {
  newest,
  oldest,
  highestAmount,
  lowestAmount,
}

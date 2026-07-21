import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receipt24_shared/receipt24_shared.dart';

import '../data/notification_service.dart';
import '../providers/notification_providers.dart';

Future<void> notifyReceiptSaved(
  WidgetRef ref, {
  required String userId,
  required ReceiptModel receipt,
}) async {
  final service = ref.read(notificationServiceProvider);
  final merchant = receipt.displayMerchant;

  if (receipt.isDuplicateFlagged) {
    await service.sendViaEdgeFunction(
      userId: userId,
      notificationType: NotificationTypes.duplicateDetected,
      title: 'Possible duplicate receipt',
      message: 'A receipt from $merchant may be a duplicate.',
      relatedRecordType: 'receipt',
      relatedRecordId: receipt.id,
      templateKey: 'duplicate_detected',
      templateVars: {'merchant_name': merchant},
    );
  } else {
    await service.sendViaEdgeFunction(
      userId: userId,
      notificationType: NotificationTypes.receiptProcessed,
      title: 'Receipt saved',
      message: 'Receipt from $merchant processed successfully.',
      relatedRecordType: 'receipt',
      relatedRecordId: receipt.id,
      templateKey: 'receipt_processed',
      templateVars: {'merchant_name': merchant},
    );
  }

  ref.invalidate(notificationsListProvider);
  ref.invalidate(unreadCountProvider);
}

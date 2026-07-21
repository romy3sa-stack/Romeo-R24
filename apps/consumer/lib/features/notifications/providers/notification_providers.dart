import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receipt24_shared/receipt24_shared.dart';

import '../../../core/auth/auth_providers.dart';
import '../data/accountant_access_service.dart';
import '../data/notification_service.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref.watch(supabaseClientProvider));
});

final accountantAccessServiceProvider = Provider<AccountantAccessService>((ref) {
  return AccountantAccessService(ref.watch(supabaseClientProvider));
});

final notificationsListProvider =
    FutureProvider.autoDispose<List<NotificationModel>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.read(notificationServiceProvider).fetchNotifications(user.id);
});

final unreadCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 0;
  return ref.read(notificationServiceProvider).getUnreadCount(user.id);
});

final notificationPreferencesProvider =
    FutureProvider.autoDispose<NotificationPreferences>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const NotificationPreferences();
  return ref.read(notificationServiceProvider).getPreferences(user.id);
});

final pendingAccountantRequestsProvider =
    FutureProvider.autoDispose<List<ClientAccessModel>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref
      .read(accountantAccessServiceProvider)
      .fetchPendingRequests(user.id);
});

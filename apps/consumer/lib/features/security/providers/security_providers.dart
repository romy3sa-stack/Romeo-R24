import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receipt24_shared/receipt24_shared.dart';

import '../../../core/auth/auth_providers.dart';
import '../data/security_service.dart';

final securityServiceProvider = Provider<SecurityService>((ref) {
  return SecurityService(ref.watch(supabaseClientProvider));
});

final loginHistoryProvider =
    FutureProvider.autoDispose<List<AuditLogModel>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.read(securityServiceProvider).fetchLoginHistory(user.id);
});

final userDevicesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.read(securityServiceProvider).fetchDevices(user.id);
});

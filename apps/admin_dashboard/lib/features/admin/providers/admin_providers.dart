import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receipt24_shared/receipt24_shared.dart';

import '../../../core/auth/auth_providers.dart';
import '../data/admin_service.dart';

final adminServiceProvider = Provider<AdminService>((ref) {
  return AdminService(ref.watch(supabaseClientProvider));
});

final dashboardStatsProvider =
    FutureProvider.autoDispose<Map<String, int>>((ref) {
  return ref.read(adminServiceProvider).getDashboardStats();
});

final usersListProvider =
    FutureProvider.autoDispose.family<List<AdminUserSummary>, String?>(
        (ref, roleFilter) {
  return ref.read(adminServiceProvider).fetchUsers(roleFilter: roleFilter);
});

final accountantsListProvider =
    FutureProvider.autoDispose
        .family<List<AdminAccountantSummary>, String?>((ref, filter) {
  return ref
      .read(adminServiceProvider)
      .fetchAccountants(verificationFilter: filter);
});

final supportTicketsProvider =
    FutureProvider.autoDispose.family<List<SupportTicketModel>, String?>(
        (ref, statusFilter) {
  return ref
      .read(adminServiceProvider)
      .fetchTickets(statusFilter: statusFilter);
});

final auditLogsProvider =
    FutureProvider.autoDispose<List<AuditLogModel>>((ref) {
  return ref.read(adminServiceProvider).fetchAuditLogs();
});

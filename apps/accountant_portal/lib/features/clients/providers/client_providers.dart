import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receipt24_shared/receipt24_shared.dart';

import '../../../core/auth/auth_providers.dart';
import '../data/client_service.dart';

final clientServiceProvider = Provider<ClientService>((ref) {
  return ClientService(ref.watch(supabaseClientProvider));
});

final clientsListProvider =
    FutureProvider.autoDispose<List<ClientAccessModel>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.read(clientServiceProvider).fetchClients(user.id);
});

final clientDetailProvider =
    FutureProvider.autoDispose.family<ClientAccessModel?, String>((ref, id) {
  return ref.read(clientServiceProvider).fetchClient(id);
});

final dashboardStatsProvider =
    FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return {};
  return ref.read(clientServiceProvider).getDashboardStats(user.id);
});

final accountantProfileProvider =
    FutureProvider.autoDispose<AccountantProfileModel?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return ref.read(clientServiceProvider).getAccountantProfile(user.id);
});

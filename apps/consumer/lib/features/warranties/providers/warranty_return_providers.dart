import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receipt24_shared/receipt24_shared.dart';

import '../../../core/auth/auth_providers.dart';
import '../data/warranty_return_service.dart';

final warrantyServiceProvider = Provider<WarrantyService>((ref) {
  return WarrantyService(ref.watch(supabaseClientProvider));
});

final returnServiceProvider = Provider<ReturnService>((ref) {
  return ReturnService(ref.watch(supabaseClientProvider));
});

final warrantiesListProvider =
    FutureProvider.autoDispose<List<WarrantyModel>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.read(warrantyServiceProvider).fetchWarranties(user.id);
});

final activeWarrantiesProvider =
    FutureProvider.autoDispose<List<WarrantyModel>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.read(warrantyServiceProvider).fetchActiveWarranties(user.id);
});

final expiringWarrantiesProvider =
    FutureProvider.autoDispose<List<WarrantyModel>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.read(warrantyServiceProvider).fetchExpiringSoon(user.id);
});

final warrantyDetailProvider =
    FutureProvider.autoDispose.family<WarrantyModel?, String>((ref, id) {
  return ref.read(warrantyServiceProvider).fetchWarranty(id);
});

final returnsListProvider =
    FutureProvider.autoDispose<List<ReturnModel>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.read(returnServiceProvider).fetchReturns(user.id);
});

final upcomingReturnsProvider =
    FutureProvider.autoDispose<List<ReturnModel>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.read(returnServiceProvider).fetchUpcomingDeadlines(user.id);
});

final returnDetailProvider =
    FutureProvider.autoDispose.family<ReturnModel?, String>((ref, id) {
  return ref.read(returnServiceProvider).fetchReturn(id);
});

final warrantyReturnStatsProvider =
    FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return {'warranties': 0, 'returns': 0};
  final warranties =
      await ref.read(warrantyServiceProvider).countActive(user.id);
  final returns =
      await ref.read(returnServiceProvider).countUpcomingDeadlines(user.id);
  return {'warranties': warranties, 'returns': returns};
});

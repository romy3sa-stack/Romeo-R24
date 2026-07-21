import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:receipt24_shared/receipt24_shared.dart';

import '../../../../core/l10n/locale_provider.dart';
import '../../providers/security_providers.dart';

class SecurityScreen extends ConsumerWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final historyAsync = ref.watch(loginHistoryProvider);
    final devicesAsync = ref.watch(userDevicesProvider);
    final dateFormat = DateFormat.yMMMd().add_jm();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.securitySettings)),
      body: ListView(
        padding: const EdgeInsets.all(Receipt24Spacing.md),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.shield_outlined),
              title: Text(l10n.mfaComingSoon),
              subtitle: Text(l10n.mfaDescription),
              trailing: Chip(label: Text(l10n.comingSoon)),
            ),
          ),
          const SizedBox(height: Receipt24Spacing.md),
          Text(l10n.activeDevices,
              style: Theme.of(context).textTheme.titleSmall),
          devicesAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox.shrink(),
            data: (devices) {
              if (devices.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(l10n.noDevices,
                      style: const TextStyle(
                          color: Color(Receipt24Colors.textSecondary))),
                );
              }
              return Column(
                children: devices.map((d) {
                  return ListTile(
                    leading: const Icon(Icons.devices),
                    title: Text(d['platform'] as String? ?? 'unknown'),
                    subtitle: Text(d['device_label'] as String? ?? ''),
                  );
                }).toList(),
              );
            },
          ),
          const Divider(),
          Text(l10n.loginHistory,
              style: Theme.of(context).textTheme.titleSmall),
          historyAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => ErrorStateView(
              message: l10n.genericError,
              onRetry: () => ref.invalidate(loginHistoryProvider),
              retryLabel: l10n.retry,
            ),
            data: (logs) {
              if (logs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(Receipt24Spacing.md),
                  child: Text(l10n.noLoginHistory),
                );
              }
              return Column(
                children: logs.map((log) {
                  return ListTile(
                    leading: const Icon(Icons.login),
                    title: Text(log.actionType),
                    subtitle: Text(
                      log.createdAt != null
                          ? dateFormat.format(log.createdAt!)
                          : '',
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

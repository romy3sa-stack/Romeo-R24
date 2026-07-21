import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:receipt24_shared/receipt24_shared.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/l10n/locale_provider.dart';
import '../../../core/widgets/receipt24_widgets.dart';
import '../providers/notification_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  IconData _iconForType(String type) {
    return switch (type) {
      'warranty_expiry_reminder' => Icons.verified_outlined,
      'return_deadline_reminder' => Icons.assignment_return_outlined,
      'duplicate_detected' => Icons.warning_amber,
      'accountant_invitation' => Icons.person_outline,
      'receipt_processed' ||
      'receipt_processing_completed' =>
        Icons.receipt_long,
      _ => Icons.notifications_outlined,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final notificationsAsync = ref.watch(notificationsListProvider);
    final pendingAsync = ref.watch(pendingAccountantRequestsProvider);
    final dateFormat = DateFormat.yMMMd().add_jm();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notifications),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: l10n.markAllRead,
            onPressed: () async {
              final user = ref.read(currentUserProvider);
              if (user == null) return;
              await ref
                  .read(notificationServiceProvider)
                  .markAllAsRead(user.id);
              ref.invalidate(notificationsListProvider);
              ref.invalidate(unreadCountProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(notificationsListProvider);
          ref.invalidate(pendingAccountantRequestsProvider);
          ref.invalidate(unreadCountProvider);
        },
        child: ListView(
          children: [
            pendingAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (requests) {
                if (requests.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(Receipt24Spacing.md),
                      child: Text(
                        l10n.pendingAccountantRequests,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    ...requests.map((req) => Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: Receipt24Spacing.sm,
                            vertical: 4,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(Receipt24Spacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  req.clientName ?? req.invitationEmail ?? '',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                                Text(l10n.accountantAccessRequest),
                                Text(
                                  req.accessScope.replaceAll('_', ' '),
                                  style: const TextStyle(
                                    color: Color(Receipt24Colors.textSecondary),
                                  ),
                                ),
                                const SizedBox(height: Receipt24Spacing.sm),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => _denyAccess(
                                            context, ref, req.id),
                                        child: Text(l10n.denyAccess),
                                      ),
                                    ),
                                    const SizedBox(width: Receipt24Spacing.sm),
                                    Expanded(
                                      child: PrimaryButton(
                                        label: l10n.approveAccess,
                                        onPressed: () => _approveAccess(
                                            context, ref, req.id),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )),
                    const Divider(),
                  ],
                );
              },
            ),
            notificationsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(child: Text(l10n.genericError)),
              data: (notifications) {
                if (notifications.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(Receipt24Spacing.xl),
                    child: Column(
                      children: [
                        Icon(Icons.notifications_none,
                            size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: Receipt24Spacing.sm),
                        Text(l10n.noNotifications,
                            style: Theme.of(context).textTheme.titleSmall),
                        Text(
                          l10n.noNotificationsHint,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Color(Receipt24Colors.textSecondary)),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: notifications.map((n) {
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: Receipt24Spacing.sm,
                        vertical: 4,
                      ),
                      color: n.readStatus
                          ? null
                          : const Color(Receipt24Colors.primary)
                              .withValues(alpha: 0.05),
                      child: ListTile(
                        leading: Icon(_iconForType(n.notificationType)),
                        title: Text(n.title,
                            style: TextStyle(
                              fontWeight: n.readStatus
                                  ? FontWeight.normal
                                  : FontWeight.w600,
                            )),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(n.message),
                            if (n.createdAt != null)
                              Text(
                                dateFormat.format(n.createdAt!),
                                style: const TextStyle(fontSize: 11),
                              ),
                          ],
                        ),
                        onTap: () => _onNotificationTap(context, ref, n),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approveAccess(
    BuildContext context,
    WidgetRef ref,
    String accessId,
  ) async {
    final l10n = context.l10n;
    await ref.read(accountantAccessServiceProvider).approveAccess(accessId);
    ref.invalidate(pendingAccountantRequestsProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.accessApproved)));
    }
  }

  Future<void> _denyAccess(
    BuildContext context,
    WidgetRef ref,
    String accessId,
  ) async {
    final l10n = context.l10n;
    await ref.read(accountantAccessServiceProvider).denyAccess(accessId);
    ref.invalidate(pendingAccountantRequestsProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.accessDenied)));
    }
  }

  Future<void> _onNotificationTap(
    BuildContext context,
    WidgetRef ref,
    NotificationModel notification,
  ) async {
    if (!notification.readStatus) {
      await ref
          .read(notificationServiceProvider)
          .markAsRead(notification.id);
      ref.invalidate(notificationsListProvider);
      ref.invalidate(unreadCountProvider);
    }

    final type = notification.relatedRecordType;
    final id = notification.relatedRecordId;
    if (type == 'receipt' && id != null) {
      if (context.mounted) context.push('/receipts/$id');
    } else if (type == 'warranty' && id != null) {
      if (context.mounted) context.push('/warranties/$id');
    } else if (type == 'return' && id != null) {
      if (context.mounted) context.push('/returns/$id');
    }
  }
}

class NotificationPreferencesScreen extends ConsumerStatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  ConsumerState<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends ConsumerState<NotificationPreferencesScreen> {
  NotificationPreferences? _prefs;
  bool _isSaving = false;

  Future<void> _save() async {
    final l10n = context.l10n;
    final user = ref.read(currentUserProvider);
    if (user == null || _prefs == null) return;

    setState(() => _isSaving = true);
    try {
      await ref
          .read(notificationServiceProvider)
          .updatePreferences(user.id, _prefs!);
      ref.invalidate(notificationPreferencesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.preferencesSaved)));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final prefsAsync = ref.watch(notificationPreferencesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.notificationPreferences)),
      body: prefsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(l10n.genericError)),
        data: (prefs) {
          _prefs ??= prefs;

          return ListView(
            padding: const EdgeInsets.all(Receipt24Spacing.md),
            children: [
              SwitchListTile(
                title: Text(l10n.pushNotifications),
                value: _prefs!.push,
                onChanged: (v) => setState(() => _prefs = _prefs!.copyWith(push: v)),
              ),
              SwitchListTile(
                title: Text(l10n.emailNotifications),
                value: _prefs!.email,
                onChanged: (v) => setState(() => _prefs = _prefs!.copyWith(email: v)),
              ),
              SwitchListTile(
                title: Text(l10n.smsNotifications),
                value: _prefs!.sms,
                onChanged: (v) => setState(() => _prefs = _prefs!.copyWith(sms: v)),
              ),
              const Divider(),
              SwitchListTile(
                title: Text(l10n.warrantyReminders),
                value: _prefs!.warrantyReminders,
                onChanged: (v) => setState(
                    () => _prefs = _prefs!.copyWith(warrantyReminders: v)),
              ),
              SwitchListTile(
                title: Text(l10n.returnReminders),
                value: _prefs!.returnReminders,
                onChanged: (v) => setState(
                    () => _prefs = _prefs!.copyWith(returnReminders: v)),
              ),
              SwitchListTile(
                title: Text(l10n.marketingNotifications),
                value: _prefs!.marketing,
                onChanged: (v) =>
                    setState(() => _prefs = _prefs!.copyWith(marketing: v)),
              ),
              const SizedBox(height: Receipt24Spacing.lg),
              PrimaryButton(
                label: l10n.savePreferences,
                isLoading: _isSaving,
                onPressed: _save,
              ),
            ],
          );
        },
      ),
    );
  }
}

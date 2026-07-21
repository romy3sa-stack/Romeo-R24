import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:receipt24_shared/receipt24_shared.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/l10n/locale_provider.dart';
import '../../../core/widgets/portal_widgets.dart';
import '../../providers/client_providers.dart';

class ClientsScreen extends ConsumerWidget {
  const ClientsScreen({super.key});

  String _statusLabel(String status, AppLocalizations l10n) {
    return switch (status) {
      'approved' => l10n.approved,
      'pending' => l10n.pending,
      'revoked' => l10n.revoked,
      _ => status,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final clientsAsync = ref.watch(clientsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.clients),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: l10n.inviteClient,
            onPressed: () => context.push('/clients/invite'),
          ),
        ],
      ),
      body: clientsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => ErrorStateView(
          message: l10n.genericError,
          onRetry: () => ref.invalidate(clientsListProvider),
          retryLabel: l10n.retry,
        ),
        data: (clients) {
          if (clients.isEmpty) {
            return EmptyStateView(
              icon: Icons.people_outline,
              title: l10n.noClients,
              message: l10n.noClientsHint,
              actionLabel: l10n.inviteClient,
              onAction: () => context.push('/clients/invite'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(clientsListProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(Receipt24Spacing.sm),
              itemCount: clients.length,
              itemBuilder: (context, index) {
                final client = clients[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(client.displayName[0].toUpperCase()),
                    ),
                    title: Text(client.displayName),
                    subtitle: Text(
                      '${_statusLabel(client.accessStatus, l10n)} · ${client.accessScope.replaceAll('_', ' ')}',
                    ),
                    trailing: StatusChip(status: client.accessStatus),
                    onTap: () => context.push('/clients/${client.id}'),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/clients/invite'),
        icon: const Icon(Icons.person_add),
        label: Text(l10n.inviteClient),
      ),
    );
  }
}

class InviteClientScreen extends ConsumerStatefulWidget {
  const InviteClientScreen({super.key});

  @override
  ConsumerState<InviteClientScreen> createState() =>
      _InviteClientScreenState();
}

class _InviteClientScreenState extends ConsumerState<InviteClientScreen> {
  final _emailController = TextEditingController();
  String _scope = AccessScopes.all;
  bool _isSaving = false;
  String? _invitationToken;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String _scopeLabel(String scope, AppLocalizations l10n) {
    return switch (scope) {
      AccessScopes.businessOnly => l10n.scopeBusinessOnly,
      AccessScopes.taxRelatedOnly => l10n.scopeTaxRelated,
      _ => l10n.scopeAllReceipts,
    };
  }

  Future<void> _invite() async {
    final l10n = context.l10n;
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isSaving = true);
    try {
      final access = await ref.read(clientServiceProvider).inviteClient(
            userId: user.id,
            invitationEmail: _emailController.text.trim(),
            accessScope: _scope,
          );
      ref.invalidate(clientsListProvider);
      ref.invalidate(dashboardStatsProvider);
      setState(() => _invitationToken = access.invitationToken);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.clientInvited)));
      }
    } catch (e) {
      if (mounted) {
        final message = e.toString().contains('consumer_not_found')
            ? 'Client must have a Receipt24 account with this email.'
            : l10n.genericError;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.inviteClient)),
      body: ListView(
        padding: const EdgeInsets.all(Receipt24Spacing.md),
        children: [
          AuthTextField(
            label: l10n.email,
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
          ),
          Text(l10n.accessScope,
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: Receipt24Spacing.sm),
          ...AccessScopes.options.map((scope) => RadioListTile<String>(
                title: Text(_scopeLabel(scope, l10n)),
                value: scope,
                groupValue: _scope,
                onChanged: (v) => setState(() => _scope = v!),
              )),
          const SizedBox(height: Receipt24Spacing.lg),
          PrimaryButton(
            label: l10n.inviteClient,
            isLoading: _isSaving,
            onPressed: _invite,
          ),
          if (_invitationToken != null) ...[
            const SizedBox(height: Receipt24Spacing.lg),
            Text(l10n.invitationLink,
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: Receipt24Spacing.sm),
            SelectableText(
              'https://app.receipt24.com/invite/$_invitationToken',
            ),
            const SizedBox(height: Receipt24Spacing.sm),
            OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(
                    text: 'https://app.receipt24.com/invite/$_invitationToken'));
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(l10n.linkCopied)));
              },
              icon: const Icon(Icons.copy),
              label: Text(l10n.copyLink),
            ),
          ],
        ],
      ),
    );
  }
}

class ClientDetailScreen extends ConsumerWidget {
  const ClientDetailScreen({super.key, required this.clientId});

  final String clientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final clientAsync = ref.watch(clientDetailProvider(clientId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.clientDetails)),
      body: clientAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(l10n.genericError)),
        data: (client) {
          if (client == null) {
            return const Center(child: Text('Client not found'));
          }

          return ListView(
            padding: const EdgeInsets.all(Receipt24Spacing.md),
            children: [
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(client.displayName),
                subtitle: Text(client.clientEmail ?? client.invitationEmail ?? ''),
              ),
              ListTile(
                title: Text(l10n.accessStatus),
                trailing: StatusChip(status: client.accessStatus),
              ),
              ListTile(
                title: Text(l10n.accessScope),
                subtitle: Text(client.accessScope.replaceAll('_', ' ')),
              ),
              if (client.isApproved) ...[
                const SizedBox(height: Receipt24Spacing.md),
                PrimaryButton(
                  label: l10n.viewReceipts,
                  onPressed: () =>
                      context.push('/clients/${client.id}/receipts'),
                ),
              ],
              if (client.invitationToken != null && client.isPending) ...[
                const Divider(),
                Text(l10n.invitationLink,
                    style: Theme.of(context).textTheme.titleSmall),
                SelectableText(
                  'https://app.receipt24.com/invite/${client.invitationToken}',
                ),
              ],
              if (!client.isRevoked) ...[
                const SizedBox(height: Receipt24Spacing.lg),
                OutlinedButton(
                  onPressed: () async {
                    await ref
                        .read(clientServiceProvider)
                        .revokeAccess(client.id);
                    ref.invalidate(clientDetailProvider(clientId));
                    ref.invalidate(clientsListProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.accessRevoked)));
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(Receipt24Colors.error),
                  ),
                  child: Text(l10n.revokeAccess),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

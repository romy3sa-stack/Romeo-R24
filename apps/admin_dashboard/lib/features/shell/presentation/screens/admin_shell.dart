import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:receipt24_shared/receipt24_shared.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/l10n/locale_provider.dart';
import '../../../core/widgets/admin_widgets.dart';
import '../../admin/providers/admin_providers.dart';

class AdminShell extends ConsumerWidget {
  const AdminShell({super.key, required this.child});
  final Widget child;

  int _index(String location) {
    if (location.startsWith('/users')) return 1;
    if (location.startsWith('/accountants')) return 2;
    if (location.startsWith('/support')) return 3;
    if (location.startsWith('/audit')) return 4;
    if (location.startsWith('/profile')) return 5;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final location = GoRouterState.of(context).uri.toString();
    final auth = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _index(location),
            onDestinationSelected: (i) {
              switch (i) {
                case 0:
                  context.go('/dashboard');
                case 1:
                  context.go('/users');
                case 2:
                  context.go('/accountants');
                case 3:
                  context.go('/support');
                case 4:
                  if (auth?.isSuperAdmin == true) context.go('/audit');
                case 5:
                  context.go('/profile');
              }
            },
            labelType: NavigationRailLabelType.all,
            destinations: [
              NavigationRailDestination(
                  icon: const Icon(Icons.dashboard_outlined),
                  selectedIcon: const Icon(Icons.dashboard),
                  label: Text(l10n.navDashboard)),
              NavigationRailDestination(
                  icon: const Icon(Icons.people_outline),
                  selectedIcon: const Icon(Icons.people),
                  label: Text(l10n.navUsers)),
              NavigationRailDestination(
                  icon: const Icon(Icons.badge_outlined),
                  selectedIcon: const Icon(Icons.badge),
                  label: Text(l10n.navAccountants)),
              NavigationRailDestination(
                  icon: const Icon(Icons.support_agent_outlined),
                  selectedIcon: const Icon(Icons.support_agent),
                  label: Text(l10n.navSupport)),
              if (auth?.isSuperAdmin == true)
                NavigationRailDestination(
                    icon: const Icon(Icons.history),
                    selectedIcon: const Icon(Icons.history),
                    label: Text(l10n.navAuditLogs)),
              NavigationRailDestination(
                  icon: const Icon(Icons.person_outline),
                  selectedIcon: const Icon(Icons.person),
                  label: Text(l10n.navProfile)),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final auth = ref.watch(authStateProvider).valueOrNull;
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navDashboard)),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(dashboardStatsProvider),
        child: ListView(
          padding: const EdgeInsets.all(Receipt24Spacing.md),
          children: [
            Text(
              l10n.homeGreeting(auth?.fullName?.split(' ').first ?? 'Admin'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: Receipt24Spacing.lg),
            statsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(child: Text(l10n.genericError)),
              data: (stats) => GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: Receipt24Spacing.sm,
                crossAxisSpacing: Receipt24Spacing.sm,
                childAspectRatio: 1.6,
                children: [
                  StatCard(
                    label: l10n.totalUsers,
                    value: '${stats['totalUsers'] ?? 0}',
                    icon: Icons.people,
                    onTap: () => context.go('/users'),
                  ),
                  StatCard(
                    label: l10n.totalConsumers,
                    value: '${stats['consumers'] ?? 0}',
                    icon: Icons.person,
                    onTap: () => context.go('/users'),
                  ),
                  StatCard(
                    label: l10n.totalAccountants,
                    value: '${stats['accountants'] ?? 0}',
                    icon: Icons.badge,
                    onTap: () => context.go('/accountants'),
                  ),
                  StatCard(
                    label: l10n.pendingVerifications,
                    value: '${stats['pendingVerifications'] ?? 0}',
                    icon: Icons.pending_actions,
                    color: const Color(Receipt24Colors.warning),
                    onTap: () => context.go('/accountants'),
                  ),
                  StatCard(
                    label: l10n.openTickets,
                    value: '${stats['openTickets'] ?? 0}',
                    icon: Icons.support_agent,
                    onTap: () => context.go('/support'),
                  ),
                  StatCard(
                    label: l10n.totalReceipts,
                    value: '${stats['totalReceipts'] ?? 0}',
                    icon: Icons.receipt_long,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final usersAsync = ref.watch(usersListProvider(null));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navUsers)),
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(l10n.genericError)),
        data: (users) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(usersListProvider(null)),
          child: ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, i) {
              final u = users[i];
              return ListTile(
                leading: CircleAvatar(child: Text(u.fullName[0])),
                title: Text(u.fullName),
                subtitle: Text('${u.email} · ${u.role}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StatusChip(status: u.accountStatus),
                    if (u.accountStatus == 'active')
                      IconButton(
                        icon: const Icon(Icons.block, size: 20),
                        tooltip: l10n.suspendUser,
                        onPressed: () async {
                          await ref
                              .read(adminServiceProvider)
                              .updateUserStatus(u.id, 'suspended');
                          ref.invalidate(usersListProvider(null));
                        },
                      )
                    else if (u.accountStatus == 'suspended')
                      IconButton(
                        icon: const Icon(Icons.check_circle_outline, size: 20),
                        tooltip: l10n.activateUser,
                        onPressed: () async {
                          await ref
                              .read(adminServiceProvider)
                              .updateUserStatus(u.id, 'active');
                          ref.invalidate(usersListProvider(null));
                        },
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class AccountantsScreen extends ConsumerWidget {
  const AccountantsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final pendingAsync = ref.watch(accountantsListProvider('pending'));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.navAccountants),
          bottom: TabBar(tabs: [
            Tab(text: l10n.pendingVerifications),
            Tab(text: l10n.navAccountants),
          ]),
        ),
        body: TabBarView(
          children: [
            _AccountantList(filter: 'pending'),
            _AccountantList(filter: null),
          ],
        ),
      ),
    );
  }
}

class _AccountantList extends ConsumerWidget {
  const _AccountantList({this.filter});
  final String? filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final async = ref.watch(accountantsListProvider(filter));

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(child: Text(l10n.genericError)),
      data: (accountants) {
        if (accountants.isEmpty) {
          return Center(child: Text(l10n.noPendingVerifications));
        }
        return ListView.builder(
          itemCount: accountants.length,
          itemBuilder: (context, i) {
            final a = accountants[i];
            return Card(
              margin: const EdgeInsets.symmetric(
                  horizontal: Receipt24Spacing.sm, vertical: 4),
              child: ListTile(
                title: Text(a.firmName),
                subtitle: Text(
                    '${a.fullName ?? ''} · ${a.email ?? ''}\n${l10n.verificationStatus}: ${a.verificationStatus}'),
                isThreeLine: true,
                trailing: a.isPending
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close,
                                color: Color(Receipt24Colors.error)),
                            tooltip: l10n.rejectAccountant,
                            onPressed: () async {
                              await ref
                                  .read(adminServiceProvider)
                                  .rejectAccountant(a.id, a.userId);
                              ref.invalidate(accountantsListProvider('pending'));
                              ref.invalidate(accountantsListProvider(null));
                              ref.invalidate(dashboardStatsProvider);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.check,
                                color: Color(Receipt24Colors.success)),
                            tooltip: l10n.verifyAccountant,
                            onPressed: () async {
                              await ref
                                  .read(adminServiceProvider)
                                  .verifyAccountant(a.id, a.userId);
                              ref.invalidate(accountantsListProvider('pending'));
                              ref.invalidate(accountantsListProvider(null));
                              ref.invalidate(dashboardStatsProvider);
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(l10n.accountantVerified)));
                            },
                          ),
                        ],
                      )
                    : StatusChip(status: a.verificationStatus),
              ),
            );
          },
        );
      },
    );
  }
}

class SupportScreen extends ConsumerWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final ticketsAsync = ref.watch(supportTicketsProvider(null));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navSupport)),
      body: ticketsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(l10n.genericError)),
        data: (tickets) {
          if (tickets.isEmpty) return Center(child: Text(l10n.noTickets));
          return ListView.builder(
            itemCount: tickets.length,
            itemBuilder: (context, i) {
              final t = tickets[i];
              return ExpansionTile(
                title: Text('${t.ticketNumber}: ${t.subject}'),
                subtitle: Text('${t.userName ?? ''} · ${t.ticketStatus}'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(Receipt24Spacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.description),
                        const SizedBox(height: Receipt24Spacing.sm),
                        Wrap(
                          spacing: 8,
                          children: [
                            'in_progress',
                            'resolved',
                            'closed',
                          ].map((status) {
                            return ActionChip(
                              label: Text(status.replaceAll('_', ' ')),
                              onPressed: () async {
                                await ref
                                    .read(adminServiceProvider)
                                    .updateTicketStatus(t.id, status);
                                ref.invalidate(supportTicketsProvider(null));
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(l10n.ticketUpdated)));
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class AuditScreen extends ConsumerWidget {
  const AuditScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final logsAsync = ref.watch(auditLogsProvider);
    final dateFormat = DateFormat.yMMMd().add_jm();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navAuditLogs)),
      body: logsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(l10n.genericError)),
        data: (logs) {
          if (logs.isEmpty) return Center(child: Text(l10n.noAuditLogs));
          return ListView.builder(
            itemCount: logs.length,
            itemBuilder: (context, i) {
              final log = logs[i];
              return ListTile(
                title: Text('${log.actionType} · ${log.recordType}'),
                subtitle: Text(
                    '${log.userName ?? 'System'} · ${log.createdAt != null ? dateFormat.format(log.createdAt!) : ''}'),
              );
            },
          );
        },
      ),
    );
  }
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final auth = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navProfile)),
      body: ListView(
        children: [
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.admin_panel_settings)),
            title: Text(auth?.fullName ?? ''),
            subtitle: Text(auth?.user?.email ?? ''),
          ),
          ListTile(
            title: const Text('Role'),
            trailing: Text(auth?.role?.value ?? ''),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Color(Receipt24Colors.error)),
            title: Text(l10n.signOut),
            onTap: () => ref.read(authServiceProvider).signOut(),
          ),
        ],
      ),
    );
  }
}

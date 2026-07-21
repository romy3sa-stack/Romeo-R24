import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:receipt24_shared/receipt24_shared.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/l10n/locale_provider.dart';
import '../../../core/widgets/portal_widgets.dart';
import '../../../clients/providers/client_providers.dart';

class PortalShell extends ConsumerWidget {
  const PortalShell({super.key, required this.child});

  final Widget child;

  int _indexFromLocation(String location) {
    if (location.startsWith('/clients')) return 1;
    if (location.startsWith('/profile')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final location = GoRouterState.of(context).uri.toString();
    final index = _indexFromLocation(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) {
          switch (i) {
            case 0:
              context.go('/dashboard');
            case 1:
              context.go('/clients');
            case 2:
              context.go('/profile');
          }
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard),
            label: l10n.navDashboard,
          ),
          NavigationDestination(
            icon: const Icon(Icons.people_outline),
            selectedIcon: const Icon(Icons.people),
            label: l10n.navClients,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: l10n.navProfile,
          ),
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
              l10n.homeGreeting(auth?.fullName?.split(' ').first ?? 'there'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (auth?.firmName != null)
              Text(
                auth!.firmName!,
                style: const TextStyle(
                    color: Color(Receipt24Colors.textSecondary)),
              ),
            const SizedBox(height: Receipt24Spacing.lg),
            statsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox.shrink(),
              data: (stats) => GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: Receipt24Spacing.sm,
                crossAxisSpacing: Receipt24Spacing.sm,
                childAspectRatio: 1.4,
                children: [
                  StatCard(
                    label: l10n.totalClients,
                    value: '${stats['totalClients'] ?? 0}',
                    icon: Icons.people_outline,
                    color: const Color(Receipt24Colors.primary),
                    onTap: () => context.go('/clients'),
                  ),
                  StatCard(
                    label: l10n.pendingInvitations,
                    value: '${stats['pendingInvitations'] ?? 0}',
                    icon: Icons.mail_outline,
                    color: const Color(Receipt24Colors.warning),
                    onTap: () => context.go('/clients'),
                  ),
                  StatCard(
                    label: l10n.receiptsThisMonth,
                    value: '${stats['receiptsThisMonth'] ?? 0}',
                    icon: Icons.receipt_long_outlined,
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

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final auth = ref.watch(authStateProvider).valueOrNull;
    final profileAsync = ref.watch(accountantProfileProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navProfile)),
      body: ListView(
        padding: const EdgeInsets.all(Receipt24Spacing.md),
        children: [
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(auth?.fullName ?? ''),
            subtitle: Text(auth?.user?.email ?? ''),
          ),
          profileAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (profile) {
              if (profile == null) return const SizedBox.shrink();
              return Column(
                children: [
                  ListTile(
                    title: Text(l10n.firmName),
                    subtitle: Text(profile.firmName),
                  ),
                  if (profile.country != null)
                    ListTile(
                      title: Text(l10n.country),
                      subtitle: Text(profile.country!),
                    ),
                  ListTile(
                    title: Text(l10n.subscriptionPlan),
                    subtitle: Text(profile.subscriptionPlan ?? '—'),
                  ),
                ],
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.card_membership),
            title: Text(l10n.manageSubscription),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/subscription'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout,
                color: Color(Receipt24Colors.error)),
            title: Text(l10n.signOut),
            onTap: () => ref.read(authServiceProvider).signOut(),
          ),
        ],
      ),
    );
  }
}

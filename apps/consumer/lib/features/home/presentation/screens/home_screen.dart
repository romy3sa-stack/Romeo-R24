import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:receipt24_shared/receipt24_shared.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/widgets/receipt24_widgets.dart';

final homeStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return {};
  return ref.read(authServiceProvider).getHomeStats(user.id);
});

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.child});

  final Widget child;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _indexFromLocation(String location) {
    if (location.startsWith('/home/receipts')) return 1;
    if (location.startsWith('/home/scan')) return 2;
    if (location.startsWith('/home/insights')) return 3;
    if (location.startsWith('/home/profile')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final location = GoRouterState.of(context).uri.toString();
    final index = _indexFromLocation(location);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) {
          switch (i) {
            case 0:
              context.go('/home');
            case 1:
              context.go('/home/receipts');
            case 2:
              context.go('/home/scan');
            case 3:
              context.go('/home/insights');
            case 4:
              context.go('/home/profile');
          }
        },
        destinations: [
          NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home),
              label: l10n.navHome),
          NavigationDestination(
              icon: const Icon(Icons.receipt_long_outlined),
              selectedIcon: const Icon(Icons.receipt_long),
              label: l10n.navReceipts),
          NavigationDestination(
              icon: const Icon(Icons.document_scanner_outlined),
              selectedIcon: const Icon(Icons.document_scanner),
              label: l10n.navScan),
          NavigationDestination(
              icon: const Icon(Icons.insights_outlined),
              selectedIcon: const Icon(Icons.insights),
              label: l10n.navInsights),
          NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon: const Icon(Icons.person),
              label: l10n.navProfile),
        ],
      ),
      floatingActionButton: null,
    );
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final auth = ref.watch(authStateProvider).valueOrNull;
    final statsAsync = ref.watch(homeStatsProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(homeStatsProvider),
          child: ListView(
            padding: const EdgeInsets.all(Receipt24Spacing.md),
            children: [
              Text(
                l10n.homeGreeting(auth?.fullName?.split(' ').first ?? 'there'),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: Receipt24Spacing.md),
              TextField(
                decoration: InputDecoration(
                  hintText: l10n.searchReceipts,
                  prefixIcon: const Icon(Icons.search),
                ),
                onTap: () => context.go('/home/receipts'),
                readOnly: true,
              ),
              const SizedBox(height: Receipt24Spacing.md),
              Row(
                children: [
                  Expanded(
                    child: _ActionChip(
                      icon: Icons.document_scanner,
                      label: l10n.scanReceipt,
                      onTap: () => context.go('/home/scan'),
                    ),
                  ),
                  const SizedBox(width: Receipt24Spacing.sm),
                  Expanded(
                    child: _ActionChip(
                      icon: Icons.upload_file,
                      label: l10n.uploadReceipt,
                      onTap: () => context.go('/home/scan'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Receipt24Spacing.sm),
              _ActionChip(
                icon: Icons.edit_note,
                label: l10n.addManually,
                onTap: () => context.go('/home/scan'),
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
                      label: l10n.totalSpendingMonth,
                      value: '\$${(stats['monthlySpending'] ?? 0).toStringAsFixed(2)}',
                      icon: Icons.payments_outlined,
                      color: const Color(Receipt24Colors.primary),
                    ),
                    StatCard(
                      label: l10n.receiptsThisMonth,
                      value: '${stats['receiptCount'] ?? 0}',
                      icon: Icons.receipt_outlined,
                    ),
                    StatCard(
                      label: l10n.activeWarranties,
                      value: '${stats['activeWarranties'] ?? 0}',
                      icon: Icons.verified_outlined,
                      color: const Color(Receipt24Colors.success),
                    ),
                    StatCard(
                      label: l10n.returnDeadlines,
                      value: '${stats['returnDeadlines'] ?? 0}',
                      icon: Icons.assignment_return_outlined,
                      color: const Color(Receipt24Colors.warning),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Receipt24Spacing.lg),
              Text(
                l10n.recentReceipts,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: Receipt24Spacing.sm),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(Receipt24Spacing.xl),
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long,
                          size: 48,
                          color: Colors.grey.shade400),
                      const SizedBox(height: Receipt24Spacing.sm),
                      Text(l10n.noReceiptsYet,
                          style: Theme.of(context).textTheme.titleSmall),
                      Text(
                        l10n.noReceiptsHint,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Color(Receipt24Colors.textSecondary)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: Receipt24Spacing.md,
            horizontal: Receipt24Spacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: Receipt24Spacing.xs),
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
      ),
    );
  }
}

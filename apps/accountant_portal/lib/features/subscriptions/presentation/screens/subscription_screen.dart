import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:receipt24_shared/receipt24_shared.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/l10n/locale_provider.dart';
import '../../../core/widgets/portal_widgets.dart';
import '../providers/subscription_providers.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() =>
      _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  String _billingCycle = 'monthly';
  bool _isLoading = false;

  Future<void> _subscribe(SubscriptionPlanDefinition plan) async {
    final l10n = context.l10n;
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(subscriptionServiceProvider).createCheckoutSession(
            userId: user.id,
            planId: plan.id,
            billingCycle: _billingCycle,
          );
      ref.invalidate(currentSubscriptionProvider);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.subscriptionUpdated)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.genericError)));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cancel(SubscriptionModel subscription) async {
    final l10n = context.l10n;
    setState(() => _isLoading = true);
    try {
      await ref
          .read(subscriptionServiceProvider)
          .cancelSubscription(subscription.id);
      ref.invalidate(currentSubscriptionProvider);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.subscriptionCancelled)));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final subAsync = ref.watch(currentSubscriptionProvider);
    final dateFormat = DateFormat.yMMMd();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.manageSubscription)),
      body: subAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(l10n.genericError)),
        data: (subscription) {
          final effective = ref
              .read(subscriptionServiceProvider)
              .effectivePlan(subscription);

          return ListView(
            padding: const EdgeInsets.all(Receipt24Spacing.md),
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.card_membership),
                  title: Text(l10n.currentPlan),
                  subtitle: Text(l10n.planLabel(effective.nameKey)),
                  trailing: Chip(label: Text(l10n.subscriptionActive)),
                ),
              ),
              if (subscription?.renewalDate != null)
                Text(
                  '${l10n.renewsOn}: ${dateFormat.format(subscription!.renewalDate!)}',
                ),
              const SizedBox(height: Receipt24Spacing.md),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(value: 'monthly', label: Text(l10n.monthly)),
                  ButtonSegment(value: 'annual', label: Text(l10n.annual)),
                ],
                selected: {_billingCycle},
                onSelectionChanged: (s) =>
                    setState(() => _billingCycle = s.first),
              ),
              const SizedBox(height: Receipt24Spacing.lg),
              ...SubscriptionPlans.accountantPlans.map((plan) {
                final price = plan.priceForCycle(_billingCycle);
                final isCurrent = effective.id == plan.id;

                return Card(
                  margin: const EdgeInsets.only(bottom: Receipt24Spacing.sm),
                  child: Padding(
                    padding: const EdgeInsets.all(Receipt24Spacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.planLabel(plan.nameKey),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '\$${price.toStringAsFixed(2)}${_billingCycle == 'annual' ? l10n.perYear : l10n.perMonth}',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        ...plan.featureKeys.map(
                          (f) => Row(
                            children: [
                              const Icon(Icons.check, size: 16),
                              const SizedBox(width: 8),
                              Expanded(child: Text(l10n.featureLabel(f))),
                            ],
                          ),
                        ),
                        if (!isCurrent) ...[
                          const SizedBox(height: Receipt24Spacing.md),
                          PrimaryButton(
                            label: l10n.upgradePlan,
                            isLoading: _isLoading,
                            onPressed: () => _subscribe(plan),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
              if (subscription?.isActive == true) ...[
                const Divider(),
                OutlinedButton(
                  onPressed: _isLoading
                      ? null
                      : () => _cancel(subscription!),
                  child: Text(l10n.cancelSubscription),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

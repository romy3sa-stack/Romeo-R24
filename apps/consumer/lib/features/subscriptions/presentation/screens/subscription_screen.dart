import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:receipt24_shared/receipt24_shared.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/l10n/locale_provider.dart';
import '../../../core/widgets/receipt24_widgets.dart';
import '../providers/subscription_providers.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  String _billingCycle = 'monthly';
  bool _isLoading = false;

  String _planLabel(AppLocalizations l10n, SubscriptionPlanDefinition plan) {
    return l10n.planLabel(plan.nameKey);
  }

  String _featureLabel(AppLocalizations l10n, String key) {
    return l10n.featureLabel(key);
  }

  Future<void> _subscribe(SubscriptionPlanDefinition plan) async {
    if (plan.isFree) return;

    final l10n = context.l10n;
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(subscriptionServiceProvider).createCheckoutSession(
            userId: user.id,
            planId: plan.id,
            billingCycle: _billingCycle,
            successUrl: 'https://app.receipt24.com/subscription?success=true',
            cancelUrl: 'https://app.receipt24.com/subscription?cancelled=true',
          );

      ref.invalidate(currentSubscriptionProvider);
      ref.invalidate(effectivePlanProvider);

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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.cancelSubscription),
        content: const Text('Are you sure you want to cancel?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.continueButton)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.cancelSubscription)),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await ref
          .read(subscriptionServiceProvider)
          .cancelSubscription(subscription.id);
      ref.invalidate(currentSubscriptionProvider);
      ref.invalidate(effectivePlanProvider);
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
          final effective = ref.read(subscriptionServiceProvider).effectivePlan(
                subscription: subscription,
                ownerType: 'consumer',
              );

          return ListView(
            padding: const EdgeInsets.all(Receipt24Spacing.md),
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.card_membership),
                  title: Text(l10n.currentPlan),
                  subtitle: Text(_planLabel(l10n, effective)),
                  trailing: subscription?.isActive == true
                      ? Chip(label: Text(l10n.subscriptionActive))
                      : Chip(label: Text(l10n.freePlan)),
                ),
              ),
              if (subscription?.renewalDate != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: Receipt24Spacing.md),
                  child: Text(
                    '${l10n.renewsOn}: ${dateFormat.format(subscription!.renewalDate!)}',
                    style: const TextStyle(
                        color: Color(Receipt24Colors.textSecondary)),
                  ),
                ),
              Text(l10n.billingCycle,
                  style: Theme.of(context).textTheme.titleSmall),
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
              Text(l10n.choosePlan,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: Receipt24Spacing.sm),
              ...SubscriptionPlans.consumerPlans.map((plan) {
                final price = plan.priceForCycle(_billingCycle);
                final isCurrent = effective.id == plan.id;

                return Card(
                  margin: const EdgeInsets.only(bottom: Receipt24Spacing.sm),
                  child: Padding(
                    padding: const EdgeInsets.all(Receipt24Spacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _planLabel(l10n, plan),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            if (isCurrent)
                              Chip(
                                label: Text(l10n.currentPlan,
                                    style: const TextStyle(fontSize: 10)),
                              ),
                          ],
                        ),
                        Text(
                          plan.isFree
                              ? l10n.freePlan
                              : '\$${price.toStringAsFixed(2)}${_billingCycle == 'annual' ? l10n.perYear : l10n.perMonth}',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: Receipt24Spacing.sm),
                        ...plan.featureKeys.map(
                          (f) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                const Icon(Icons.check,
                                    size: 16,
                                    color: Color(Receipt24Colors.success)),
                                const SizedBox(width: 8),
                                Expanded(child: Text(_featureLabel(l10n, f))),
                              ],
                            ),
                          ),
                        ),
                        if (!plan.isFree && !isCurrent) ...[
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
              if (subscription?.isActive == true &&
                  !subscription!.isCancelled) ...[
                const Divider(),
                OutlinedButton(
                  onPressed: _isLoading
                      ? null
                      : () => _cancel(subscription),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(Receipt24Colors.error),
                  ),
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

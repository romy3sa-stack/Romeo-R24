# Phase 11 Testing Checklist

## Consumer Subscription Screen
- [ ] Accessible from profile → Manage subscription
- [ ] Current plan displayed (Free when no subscription)
- [ ] Billing cycle toggle (monthly/annual) updates prices
- [ ] Three consumer plans shown: Free, Plus, Pro
- [ ] Feature list displayed per plan
- [ ] Current plan chip shown on active plan
- [ ] Upgrade button on non-current paid plans
- [ ] Cancel subscription button when active paid plan exists

## Accountant Subscription Screen
- [ ] Accessible from profile → Manage subscription
- [ ] Three accountant plans: Solo, Professional, Enterprise
- [ ] Prices update with billing cycle toggle
- [ ] Upgrade and cancel flows work

## Checkout (Mock Mode — no STRIPE_SECRET_KEY)
- [ ] create-checkout-session inserts subscription row directly
- [ ] payment_provider set to "mock"
- [ ] Success snackbar shown after upgrade
- [ ] Current plan updates after refresh

## Checkout (Stripe Mode)
- [ ] create-checkout-session returns Stripe checkout URL
- [ ] Stripe Checkout session created with correct amount
- [ ] Metadata includes user_id, plan_id, billing_cycle, owner_type

## Stripe Webhook
- [ ] checkout.session.completed creates subscription row
- [ ] subscription_renewal notification created for user
- [ ] customer.subscription.updated updates status and renewal_date
- [ ] customer.subscription.deleted sets status to cancelled

## Cancel Subscription
- [ ] cancel-subscription edge function updates status to cancelled
- [ ] Stripe subscription deleted when external ID present
- [ ] Mock subscriptions cancelled without Stripe call

## Database
- [ ] subscriptions owner constraint enforced (user XOR accountant)
- [ ] RLS: users see own subscriptions
- [ ] RLS: accountants see own firm subscriptions via get_accountant_id()

## Plan Definitions
- [ ] SubscriptionPlans.consumerPlans has 3 plans
- [ ] SubscriptionPlans.accountantPlans has 3 plans
- [ ] findById resolves plan by ID
- [ ] effectivePlan returns free tier when no active subscription

## Integration
- [ ] Route /subscription works in consumer app
- [ ] Route /subscription works in accountant portal
- [ ] Providers invalidate after subscribe/cancel

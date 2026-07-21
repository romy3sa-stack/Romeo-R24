// Supabase Edge Function: stripe-webhook
// Handles Stripe webhook events for subscription lifecycle.
// Deploy: supabase functions deploy stripe-webhook --no-verify-jwt

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type, stripe-signature',
};

function mapStripeStatus(status: string): string {
  switch (status) {
    case 'active':
      return 'active';
    case 'trialing':
      return 'trialing';
    case 'past_due':
      return 'past_due';
    case 'canceled':
      return 'cancelled';
    default:
      return 'expired';
  }
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    );

    const body = await req.text();
    const event = JSON.parse(body);
    const type = event.type;
    const data = event.data?.object;

    if (type === 'checkout.session.completed') {
      const metadata = data.metadata ?? {};
      const planId = metadata.plan_id;
      const billingCycle = metadata.billing_cycle ?? 'monthly';
      const ownerType = metadata.owner_type ?? 'consumer';
      const userId = metadata.user_id ?? data.client_reference_id;
      const accountantId = metadata.accountant_id;
      const subscriptionId = data.subscription;
      const amountTotal = (data.amount_total ?? 0) / 100;

      const today = new Date().toISOString().split('T')[0];
      const renewal = new Date();
      if (billingCycle === 'annual') {
        renewal.setFullYear(renewal.getFullYear() + 1);
      } else {
        renewal.setMonth(renewal.getMonth() + 1);
      }

      const insertData: Record<string, unknown> = {
        plan_name: planId,
        billing_cycle: billingCycle,
        amount: amountTotal,
        currency: (data.currency ?? 'usd').toUpperCase(),
        subscription_status: 'active',
        start_date: today,
        renewal_date: renewal.toISOString().split('T')[0],
        payment_provider: 'stripe',
        external_subscription_id: subscriptionId,
      };

      if (ownerType === 'accountant' && accountantId) {
        insertData.accountant_id = accountantId;
      } else {
        insertData.user_id = userId;
      }

      await supabase.from('subscriptions').insert(insertData);

      if (userId) {
        await supabase.from('notifications').insert({
          user_id: userId,
          notification_type: 'subscription_renewal',
          title: 'Subscription activated',
          message: `Your ${planId} plan is now active.`,
          read_status: false,
        });
      }
    }

    if (
      type === 'customer.subscription.updated' ||
      type === 'customer.subscription.deleted'
    ) {
      const status = mapStripeStatus(data.status);
      await supabase
        .from('subscriptions')
        .update({
          subscription_status: status,
          renewal_date: data.current_period_end
            ? new Date(data.current_period_end * 1000)
                .toISOString()
                .split('T')[0]
            : null,
        })
        .eq('external_subscription_id', data.id);
    }

    return new Response(JSON.stringify({ received: true }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: String(error) }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});

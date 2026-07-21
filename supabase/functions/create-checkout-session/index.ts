// Supabase Edge Function: create-checkout-session
// Creates a Stripe Checkout session for subscription purchase.
// Deploy: supabase functions deploy create-checkout-session

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
};

const PLAN_PRICES: Record<string, { monthly: number; annual: number }> = {
  consumer_plus: { monthly: 4.99, annual: 49.99 },
  consumer_pro: { monthly: 9.99, annual: 99.99 },
  solo_accountant: { monthly: 29.99, annual: 299.99 },
  professional_firm: { monthly: 79.99, annual: 799.99 },
  enterprise_firm: { monthly: 199.99, annual: 1999.99 },
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const {
      userId,
      planId,
      billingCycle = 'monthly',
      ownerType = 'consumer',
      accountantId,
      successUrl,
      cancelUrl,
    } = await req.json();

    const prices = PLAN_PRICES[planId];
    if (!prices) {
      return new Response(JSON.stringify({ error: 'Invalid plan' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const amount =
      billingCycle === 'annual' ? prices.annual : prices.monthly;
    const stripeKey = Deno.env.get('STRIPE_SECRET_KEY');

    if (!stripeKey) {
      const supabase = createClient(
        Deno.env.get('SUPABASE_URL') ?? '',
        Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      );

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
        amount,
        currency: 'USD',
        subscription_status: 'active',
        start_date: today,
        renewal_date: renewal.toISOString().split('T')[0],
        payment_provider: 'mock',
        external_subscription_id: `mock_${crypto.randomUUID()}`,
      };

      if (ownerType === 'accountant' && accountantId) {
        insertData.accountant_id = accountantId;
      } else {
        insertData.user_id = userId;
      }

      await supabase.from('subscriptions').insert(insertData);

      return new Response(
        JSON.stringify({
          checkoutUrl: successUrl ?? `${Deno.env.get('APP_URL')}/subscription?success=true`,
          mock: true,
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    const params = new URLSearchParams();
    params.append('mode', 'subscription');
    params.append('success_url', successUrl);
    params.append('cancel_url', cancelUrl);
    params.append('client_reference_id', userId);
    params.append('metadata[user_id]', userId);
    params.append('metadata[plan_id]', planId);
    params.append('metadata[billing_cycle]', billingCycle);
    params.append('metadata[owner_type]', ownerType);
    if (accountantId) {
      params.append('metadata[accountant_id]', accountantId);
    }
    params.append(
      'line_items[0][price_data][currency]',
      'usd',
    );
    params.append(
      'line_items[0][price_data][product_data][name]',
      `Receipt24 ${planId}`,
    );
    params.append(
      'line_items[0][price_data][unit_amount]',
      String(Math.round(amount * 100)),
    );
    params.append(
      'line_items[0][price_data][recurring][interval]',
      billingCycle === 'annual' ? 'year' : 'month',
    );
    params.append('line_items[0][quantity]', '1');

    const response = await fetch('https://api.stripe.com/v1/checkout/sessions', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${stripeKey}`,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: params,
    });

    const session = await response.json();
    if (!response.ok) {
      throw new Error(session.error?.message ?? 'Stripe error');
    }

    return new Response(
      JSON.stringify({ checkoutUrl: session.url, sessionId: session.id }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  } catch (error) {
    return new Response(JSON.stringify({ error: String(error) }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});

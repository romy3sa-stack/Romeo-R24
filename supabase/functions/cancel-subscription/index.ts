// Supabase Edge Function: cancel-subscription
// Cancels an active subscription (mock or Stripe).
// Deploy: supabase functions deploy cancel-subscription

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { subscriptionId } = await req.json();

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    );

    const { data: sub } = await supabase
      .from('subscriptions')
      .select('*')
      .eq('id', subscriptionId)
      .single();

    if (!sub) {
      return new Response(JSON.stringify({ error: 'Not found' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const stripeKey = Deno.env.get('STRIPE_SECRET_KEY');
    if (
      stripeKey &&
      sub.external_subscription_id &&
      !sub.external_subscription_id.startsWith('mock_')
    ) {
      await fetch(
        `https://api.stripe.com/v1/subscriptions/${sub.external_subscription_id}`,
        {
          method: 'DELETE',
          headers: { Authorization: `Bearer ${stripeKey}` },
        },
      );
    }

    await supabase
      .from('subscriptions')
      .update({ subscription_status: 'cancelled' })
      .eq('id', subscriptionId);

    return new Response(JSON.stringify({ cancelled: true }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: String(error) }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});

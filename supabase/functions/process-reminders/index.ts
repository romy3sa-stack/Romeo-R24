// Supabase Edge Function: process-reminders
// Scheduled job for warranty expiry and return deadline reminders.
// Deploy: supabase functions deploy process-reminders
// Schedule via Supabase cron or external trigger.

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
};

function daysUntil(dateStr: string): number {
  const target = new Date(dateStr);
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  target.setHours(0, 0, 0, 0);
  return Math.ceil((target.getTime() - today.getTime()) / (1000 * 60 * 60 * 24));
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

    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
    const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
    const results = { warranties: 0, returns: 0 };

    const { data: warranties } = await supabase
      .from('warranties')
      .select('id, consumer_user_id, warranty_end_date, reminder_status, receipt_items(item_name)')
      .eq('warranty_status', 'active')
      .neq('reminder_status', 'disabled');

    for (const w of warranties ?? []) {
      const days = daysUntil(w.warranty_end_date);
      const productName =
        (w.receipt_items as { item_name?: string } | null)?.item_name ??
        'your product';

      let shouldSend = false;
      let nextStatus = w.reminder_status;

      if (days === 30 && w.reminder_status === 'pending') {
        shouldSend = true;
        nextStatus = 'sent_30_days';
      } else if (days === 7 && w.reminder_status === 'sent_30_days') {
        shouldSend = true;
        nextStatus = 'sent_7_days';
      } else if (days === 0 && w.reminder_status === 'sent_7_days') {
        shouldSend = true;
        nextStatus = 'sent_on_expiry';
      }

      if (!shouldSend) continue;

      await fetch(`${supabaseUrl}/functions/v1/send-notification`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${serviceKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          userId: w.consumer_user_id,
          notificationType: 'warranty_expiry_reminder',
          title: 'Warranty expiring soon',
          message: `Warranty for ${productName} expires in ${days} days.`,
          relatedRecordType: 'warranty',
          relatedRecordId: w.id,
          channels: ['push', 'email'],
          templateKey: 'warranty_expiry_reminder',
          templateVars: {
            product_name: productName,
            expiry_date: w.warranty_end_date,
            days_remaining: String(days),
          },
        }),
      });

      await supabase
        .from('warranties')
        .update({ reminder_status: nextStatus })
        .eq('id', w.id);

      results.warranties++;
    }

    const { data: returns } = await supabase
      .from('returns_and_refunds')
      .select('id, consumer_user_id, return_deadline, request_status, receipt_items(item_name)')
      .not('return_deadline', 'is', null)
      .not('request_status', 'in', '("closed","refund_received")');

    for (const r of returns ?? []) {
      if (!r.return_deadline) continue;
      const days = daysUntil(r.return_deadline);
      if (days !== 7 && days !== 3 && days !== 1) continue;

      const productName =
        (r.receipt_items as { item_name?: string } | null)?.item_name ??
        'your item';

      await fetch(`${supabaseUrl}/functions/v1/send-notification`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${serviceKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          userId: r.consumer_user_id,
          notificationType: 'return_deadline_reminder',
          title: 'Return deadline approaching',
          message: `Return deadline for ${productName} is in ${days} days.`,
          relatedRecordType: 'return',
          relatedRecordId: r.id,
          channels: ['push', 'email'],
          templateKey: 'return_deadline_reminder',
          templateVars: {
            product_name: productName,
            deadline_date: r.return_deadline,
            days_remaining: String(days),
          },
        }),
      });

      results.returns++;
    }

    return new Response(JSON.stringify({ processed: results }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: String(error) }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});

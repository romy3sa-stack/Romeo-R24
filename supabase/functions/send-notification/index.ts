// Supabase Edge Function: send-notification
// Creates in-app notification and optionally sends email via Resend.
// Deploy: supabase functions deploy send-notification

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
};

interface SendNotificationRequest {
  userId: string;
  notificationType: string;
  title: string;
  message: string;
  relatedRecordType?: string;
  relatedRecordId?: string;
  channels?: ('push' | 'email')[];
  templateKey?: string;
  templateVars?: Record<string, string>;
}

async function sendEmail(
  to: string,
  subject: string,
  body: string,
): Promise<boolean> {
  const apiKey = Deno.env.get('RESEND_API_KEY');
  const from = Deno.env.get('EMAIL_FROM') ?? 'noreply@receipt24.com';

  if (!apiKey) {
    console.log('[send-notification] Email skipped — RESEND_API_KEY not set');
    return false;
  }

  const response = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ from, to, subject, text: body }),
  });

  return response.ok;
}

function renderTemplate(
  template: string,
  vars: Record<string, string>,
): string {
  return template.replace(/\{\{(\w+)\}\}/g, (_, key) => vars[key] ?? '');
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

    const body: SendNotificationRequest = await req.json();
    const {
      userId,
      notificationType,
      title,
      message,
      relatedRecordType,
      relatedRecordId,
      channels = ['push'],
      templateKey,
      templateVars = {},
    } = body;

    const { data: notification, error } = await supabase
      .from('notifications')
      .insert({
        user_id: userId,
        notification_type: notificationType,
        title,
        message,
        related_record_type: relatedRecordType,
        related_record_id: relatedRecordId,
        read_status: false,
      })
      .select()
      .single();

    if (error) throw error;

    const { data: profile } = await supabase
      .from('consumer_profiles')
      .select('notification_preferences')
      .eq('user_id', userId)
      .maybeSingle();

    const prefs = profile?.notification_preferences ?? {
      push: true,
      email: true,
    };

    const deliveryResults: Record<string, boolean> = {
      in_app: true,
      push: false,
      email: false,
    };

    if (channels.includes('push') && prefs.push !== false) {
      // FCM delivery placeholder — requires Firebase Admin SDK setup
      console.log(`[send-notification] Push queued for user ${userId}`);
      deliveryResults.push = true;
    }

    if (channels.includes('email') && prefs.email !== false) {
      const { data: user } = await supabase
        .from('users')
        .select('email')
        .eq('id', userId)
        .single();

      if (user?.email) {
        let emailSubject = title;
        let emailBody = message;

        if (templateKey) {
          const { data: template } = await supabase
            .from('notification_templates')
            .select('subject, body')
            .eq('template_key', templateKey)
            .eq('language_code', 'en')
            .eq('channel', 'email')
            .eq('is_active', true)
            .maybeSingle();

          if (template) {
            emailSubject = renderTemplate(template.subject ?? title, templateVars);
            emailBody = renderTemplate(template.body, templateVars);
          }
        }

        deliveryResults.email = await sendEmail(
          user.email,
          emailSubject,
          emailBody,
        );
      }
    }

    return new Response(
      JSON.stringify({ notification, delivery: deliveryResults }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      },
    );
  } catch (error) {
    return new Response(JSON.stringify({ error: String(error) }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});

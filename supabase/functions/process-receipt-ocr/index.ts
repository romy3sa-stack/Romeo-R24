// Supabase Edge Function: process-receipt-ocr
// Invokes Google Vision / AWS Textract for receipt OCR.
// Deploy: supabase functions deploy process-receipt-ocr

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    );

    const { uploadId, storagePath, bucket } = await req.json();

    // TODO: Download file from storage, call OCR provider
    // const visionApiKey = Deno.env.get('GOOGLE_VISION_API_KEY');

    const mockResult = {
      merchantName: 'Extracted Merchant',
      totalAmount: 0,
      confidenceScore: 0,
      rawText: 'OCR processing placeholder',
    };

    await supabase
      .from('receipt_uploads')
      .update({
        ocr_status: 'completed',
        ocr_raw_text: mockResult.rawText,
        processing_status: 'completed',
      })
      .eq('id', uploadId);

    return new Response(JSON.stringify(mockResult), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: String(error) }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});

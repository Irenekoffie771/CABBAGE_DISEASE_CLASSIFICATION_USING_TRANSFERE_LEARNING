import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import * as ort from "https://cdn.jsdelivr.net/npm/onnxruntime-web/dist/ort.min.js";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
);

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const arrayBuffer = await req.arrayBuffer();

    // 1. Download
    const { data: modelData, error: downloadError } = await supabase.storage
      .from('models')
      .download('mobilenetv2/cabbage_model.onnx');
    if (downloadError) throw new Error("Download Error: " + downloadError.message);

    // 2. Load Session
    const modelBuffer = await modelData.arrayBuffer();
    const session = await ort.InferenceSession.create(modelBuffer);

    // 3. Create Tensor safely
    const float32Array = new Float32Array(arrayBuffer);
    const inputTensor = new ort.Tensor('float32', float32Array, [1, 224, 224, 3]);

    // 4. Run
    const feeds = { [session.inputNames[0]]: inputTensor };
    const outputData = await session.run(feeds);

    // Convert output to Array
    const outputTensor = outputData[session.outputNames[0]];
    const output = Array.from(outputTensor.data as Float32Array);

    // 5. Process result
    const labels = ['Alternaria Leaf Spot', 'Black Rot', 'Downy Mildew', 'Healthy'];
    const maxIndex = output.indexOf(Math.max(...output));

    return new Response(JSON.stringify({
      disease: labels[maxIndex],
      confidence: parseFloat(output[maxIndex].toFixed(2))
    }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });

  } catch (error: any) {
    console.error("CRITICAL ERROR:", error.message);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});

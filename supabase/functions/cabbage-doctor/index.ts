import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { GoogleGenerativeAI } from "https://esm.sh/@google/generative-ai@0.1.1"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const body = await req.json().catch(() => ({}));
    const prompt = body.prompt || "Hello";

    console.log(`Received prompt: ${prompt}`);

    const apiKey = Deno.env.get('GEMINI_API_KEY');
    if (!apiKey) {
      throw new Error("GEMINI_API_KEY is not set in Supabase Secrets");
    }

    const genAI = new GoogleGenerativeAI(apiKey)
    const model = genAI.getGenerativeModel({ model: "gemini-pro" })

    const fullPrompt = `You are an expert Agricultural AI assistant specializing in cabbage farming.
    A farmer is asking: "${prompt}".
    Provide a concise, helpful, and professional answer.
    If they ask in Twi, respond in Twi if possible, otherwise English is fine.`

    const result = await model.generateContent(fullPrompt)
    const response = await result.response
    const text = response.text()

    return new Response(
      JSON.stringify({ reply: text }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error(`Error: ${error.message}`);
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})

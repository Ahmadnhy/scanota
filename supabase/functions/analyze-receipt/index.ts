import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { GoogleGenerativeAI } from "https://esm.sh/@google/generative-ai@0.21.0"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { imageBase64 } = await req.json()
    const apiKey = Deno.env.get('GEMINI_API_KEY')
    const genAI = new GoogleGenerativeAI(apiKey!)
    const prompt = "Analisis struk ini dan kembalikan JSON: {tanggal, nama_merchant, total_pengeluaran, kategori}"
    const parts = [
      prompt,
      { inlineData: { data: imageBase64, mimeType: "image/jpeg" } }
    ]

    let result;
    try {
      // First try with the newer, faster 2.5 model
      const model25 = genAI.getGenerativeModel({ model: "gemini-2.5-flash" })
      result = await model25.generateContent(parts)
    } catch (e) {
      // Fallback to the stable 1.5 model if 2.5 is experiencing high demand (503)
      console.log("gemini-2.5-flash failed, falling back to gemini-1.5-flash. Error:", e.message)
      const model15 = genAI.getGenerativeModel({ model: "gemini-1.5-flash" })
      result = await model15.generateContent(parts)
    }

    let responseText = result.response.text()
    
    // Hapus format markdown ```json dan ``` jika ada
    responseText = responseText.replace(/```json/gi, '').replace(/```/g, '').trim()
    
    return new Response(responseText, {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})

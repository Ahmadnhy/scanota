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
      // First try with the faster flash model
      const modelFlash = genAI.getGenerativeModel({ model: "gemini-1.5-flash-latest" })
      result = await modelFlash.generateContent(parts)
    } catch (e) {
      // Fallback to pro model if flash is experiencing high demand (503) or 404
      console.log("gemini-1.5-flash-latest failed, falling back to gemini-1.5-pro-latest. Error:", e.message)
      const modelPro = genAI.getGenerativeModel({ model: "gemini-1.5-pro-latest" })
      result = await modelPro.generateContent(parts)
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

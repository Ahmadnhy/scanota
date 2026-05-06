import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
   import { GoogleGenerativeAI, SchemaType } from "npm:@google/generative-ai"

   // CORS agar aplikasi Flutter bisa memanggil fungsi ini tanpa error block
   const corsHeaders = {
     'Access-Control-Allow-Origin': '*',
     'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
   }

   serve(async (req) => {
     // Handle preflight request
     if (req.method === 'OPTIONS') {
       return new Response('ok', { headers: corsHeaders })
     }

     try {
       // 1. Terima gambar dari Flutter
       const { imageBase64 } = await req.json()
       if (!imageBase64) throw new Error('Gambar tidak ditemukan')

       // 2. Ambil API Key dari brankas rahasia Supabase
       const apiKey = Deno.env.get('GEMINI_API_KEY')
       if (!apiKey) throw new Error('API Key belum di-setting di server')

       const genAI = new GoogleGenerativeAI(apiKey)

       // 3. Aturan ketat JSON Schema agar data tidak bocor/rusak
       const model = genAI.getGenerativeModel({
         model: "gemini-2.5-flash",
         generationConfig: {
           responseMimeType: "application/json",
           temperature: 0.1, // Suhu rendah agar AI tidak mengobrol
           responseSchema: {
             type: SchemaType.OBJECT,
             properties: {
               tanggal: { type: SchemaType.STRING, description: "Format YYYY-MM-DD" },
               nama_merchant: { type: SchemaType.STRING },
               total_pengeluaran: { type: SchemaType.NUMBER },
               kategori: { type: SchemaType.STRING, description: "makanan, transportasi, belanja, tagihan, kesehatan, hiburan, atau lainnya" },
             },
             required: ["tanggal", "nama_merchant", "total_pengeluaran", "kategori"]
           }
         }
       })

       // 4. Perintahkan Gemini
       const prompt = "Ekstrak data dari struk belanja ini. Kembalikan HANYA format JSON."
       const imagePart = { inlineData: { data: imageBase64, mimeType: "image/jpeg" } }

       const result = await model.generateContent([prompt, imagePart])
       
       // 5. Kembalikan hasil JSON ke Flutter
       return new Response(
         result.response.text(), 
         { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
       )

     } catch (error) {
       return new Response(
         JSON.stringify({ error: error.message }),
         { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
       )
     }
   })
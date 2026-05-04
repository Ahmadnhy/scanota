Vercel adalah pilihan yang sangat tepat dan cepat untuk meng-hosting demo Flutter Web. Karena hasil *build* Flutter Web pada dasarnya adalah kumpulan file statis (HTML, CSS, JS), kita hanya perlu mengarahkan Vercel untuk membaca folder hasil *build* tersebut.

Cara paling praktis dan minim *error* untuk kebutuhan demo adalah dengan melakukan *build* di komputer lokalmu, lalu men-deploy folder hasilnya langsung menggunakan Vercel CLI. 

Berikut adalah panduan *step-by-step* beserta *prompt* perintah yang bisa langsung kamu jalankan:

### Langkah 1: Build Flutter Web
Untuk aplikasi yang menggunakan manipulasi gambar (seperti `image_cropper` dan `image_picker`), sangat disarankan menggunakan *renderer* **CanvasKit** agar performa grafis dan UI-nya konsisten dengan versi mobile.

Buka terminal di *root* project Flutter kamu, lalu jalankan:
```bash
flutter build web --release --web-renderer canvaskit
```
*Proses ini akan menghasilkan folder baru di `build/web/`.*

### Langkah 2: Tambahkan Konfigurasi `vercel.json` (Sangat Penting)
Flutter Web adalah *Single Page Application* (SPA). Jika pengguna me-refresh halaman (misalnya di URL `namademo.vercel.app/scan`), Vercel akan mencari file `scan.html` dan berujung pada error **404 Not Found**. 

Untuk mencegahnya, kita harus mengarahkan semua *routing* kembali ke `index.html`.
1. Masuk ke dalam folder hasil build: `build/web/`
2. Buat file baru bernama `vercel.json` di dalam folder tersebut.
3. Isi dengan kode berikut:

```json
{
  "rewrites": [
    {
      "source": "/(.*)",
      "destination": "/index.html"
    }
  ]
}
```

### Langkah 3: Deploy Menggunakan Vercel CLI
Jika kamu belum menginstal Vercel CLI, kamu bisa menginstalnya secara global menggunakan npm (Node.js):
```bash
npm i -g vercel
```

Setelah itu, pastikan posisimu di terminal masih berada di dalam direktori `build/web/`, lalu jalankan perintah:
```bash
vercel
```

Vercel CLI akan memberikan beberapa pertanyaan interaktif. Kamu bisa menjawabnya seperti ini:
* **Set up and deploy "~/path/ke/project/build/web"?** `Y`
* **Which scope do you want to deploy to?** *(Pilih akun Vercel kamu)*
* **Link to existing project?** `N` *(Pilih No karena ini project baru)*
* **What's your project's name?** *(Ketik nama aplikasi demomu, misal: `demo-scan-ocr`)*
* **In which directory is your code located?** `./` *(Tekan Enter saja)*
* **Want to modify these settings?** `N` *(Tekan Enter)*

Tunggu beberapa detik, dan Vercel akan memberikan link *Preview*. Jika kamu sudah puas dan ingin menjadikannya link utama (*Production*), cukup jalankan:
```bash
vercel --prod
```

---

### 💡 Catatan Ekstra Pasca-Deploy

1. **Konfigurasi CORS & Supabase:** Jika aplikasi demomu terhubung ke database seperti Supabase (terutama untuk proses penyimpanan data transaksi dari hasil OCR), pastikan kamu menambahkan domain Vercel yang baru saja di-generate (misal: `https://demo-scan-ocr.vercel.app`) ke dalam daftar **Site URL** dan **Redirect URLs** di pengaturan *Authentication* Supabase.
2. **Kamera di Browser HP:** Saat demo diakses via HP, browser terkadang memblokir akses kamera jika situs tidak menggunakan HTTPS. Beruntungnya, Vercel sudah otomatis membungkus domainmu dengan SSL (`https://`), jadi fitur `image_picker` akan berjalan tanpa masalah.

Langkah di atas adalah cara tercepat untuk mendapatkan URL demo. Apakah kamu ingin URL demonya nanti menggunakan custom domain (seperti `.is-a.dev` atau yang lainnya), atau cukup menggunakan subdomain bawaan `.vercel.app` saja?
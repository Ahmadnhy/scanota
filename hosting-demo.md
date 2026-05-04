Vercel adalah pilihan yang sangat tepat dan cepat untuk meng-hosting demo Flutter Web. Karena hasil *build* Flutter Web pada dasarnya adalah kumpulan file statis (HTML, CSS, JS), kita hanya perlu mengarahkan Vercel untuk membaca folder hasil *build* tersebut.

Berikut adalah panduan terbaru yang lebih praktis dan minim *error* untuk memperbarui aplikasi Anda:

### Langkah 1: Build Flutter Web
Buka terminal di *root* project Flutter Anda, lalu jalankan perintah ini untuk mengompilasi kode terbaru:

```powershell
flutter build web --release --web-renderer canvaskit
```
*Renderer **CanvasKit** sangat disarankan untuk aplikasi yang menggunakan fitur kamera/gambar agar performa UI konsisten.*

### Langkah 2: Konfigurasi Routing (`vercel.json`)
Pastikan file `vercel.json` sudah ada di dalam folder `build/web/` agar fitur navigasi (SPA) berjalan lancar saat di-refresh. Jika belum ada, buat file `build/web/vercel.json` dengan isi:

```json
{
  "version": 2,
  "rewrites": [
    {
      "source": "/(.*)",
      "destination": "/index.html"
    }
  ]
}
```

### Langkah 3: Deploy ke Vercel (Production)
Gunakan `npx` agar Anda tidak perlu menginstal Vercel CLI secara global. Jalankan perintah ini langsung dari *root* folder project Anda:

```powershell
npx vercel --prod build/web
```

**Mengapa menggunakan cara ini?**
- **Tanpa Instalasi Global:** `npx` langsung menjalankan Vercel CLI versi terbaru tanpa mengotori sistem Anda.
- **Langsung ke Root:** Anda tidak perlu berpindah-pindah folder (`cd build/web`).
- **Instant Live:** Flag `--prod` langsung memperbarui link utama Anda (misal: `expensnap.vercel.app`).

---

### 💡 Catatan Ekstra Pasca-Deploy

1. **Konfigurasi CORS & Supabase:** Pastikan domain Vercel Anda sudah terdaftar di **Site URL** dan **Redirect URLs** pada pengaturan *Authentication* Supabase.
2. **Kamera & HTTPS:** Vercel otomatis menggunakan HTTPS, sehingga fitur `image_picker` (kamera) akan berfungsi dengan baik di browser mobile.

Langkah di atas adalah cara tercepat untuk mempublikasikan perubahan UI terbaru Anda. Apakah Anda ingin mencoba integrasi CI/CD (otomatis deploy saat push ke GitHub) untuk selanjutnya?
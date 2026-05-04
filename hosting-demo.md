Vercel adalah pilihan yang sangat tepat dan cepat untuk meng-hosting demo Flutter Web. Karena hasil *build* Flutter Web pada dasarnya adalah kumpulan file statis (HTML, CSS, JS), kita hanya perlu mengarahkan Vercel untuk membaca folder hasil *build* tersebut.

Berikut adalah panduan lengkap, baik untuk pertama kali setup maupun untuk memperbarui aplikasi Anda:

### Langkah 1: Persiapan (Build & Routing)
Langkah ini wajib dilakukan setiap kali ada perubahan kode.

1.  **Build Flutter Web:**
    Jalankan perintah ini di terminal *root* project:
    ```powershell
    flutter build web --release --web-renderer canvaskit
    ```

2.  **Konfigurasi `vercel.json`:**
    Pastikan file `build/web/vercel.json` sudah ada (untuk menangani refresh halaman/SPA). Jika belum, buat file tersebut dan isi dengan:
    ```json
    {
      "version": 2,
      "rewrites": [{ "source": "/(.*)", "destination": "/index.html" }]
    }
    ```

---

### Langkah 2: Setup Pertama Kali (Inisialisasi)
Lakukan langkah ini hanya jika Anda baru pertama kali menghubungkan folder ini ke Vercel.

1.  **Login ke Vercel (Jika belum):**
    ```powershell
    npx vercel login
    ```
    *Ikuti instruksi di browser untuk masuk ke akun Anda.*

2.  **Hubungkan Project:**
    Jalankan perintah ini di root folder:
    ```powershell
    npx vercel build/web
    ```
    Lalu jawab pertanyaannya sebagai berikut:
    - `Set up and deploy "~/path/ke/project/build/web"?` **Y**
    - `Which scope...?` **(Pilih akun Anda)**
    - `Link to existing project?` **N**
    - `What's your project's name?` **(Ketik nama aplikasi Anda)**
    - `In which directory is your code located?` **./** (Tekan Enter)
    - `Want to modify these settings?` **N** (Tekan Enter)

---

### Langkah 3: Memperbarui Aplikasi (Selanjutnya)
Setelah project terhubung (Langkah 2 selesai), gunakan perintah ini setiap kali Anda ingin mempublikasikan perubahan terbaru ke link utama:

```powershell
# 1. Build ulang
flutter build web --release --web-renderer canvaskit

# 2. Deploy langsung ke Production
npx vercel --prod build/web
```

**Mengapa menggunakan cara ini?**
- **Cepat:** Tanpa perlu instalasi software tambahan (cukup `npx`).
- **Akurat:** Mengunggah folder `build/web` secara spesifik, bukan seluruh source code.
- **Instant:** Link `namaproject.vercel.app` akan langsung terupdate.

---

### 💡 Tips Tambahan
1.  **Supabase & CORS:** Jika menggunakan Supabase, tambahkan domain Vercel Anda ke menu **Authentication > URL Configuration**.
2.  **Kamera:** Vercel menggunakan HTTPS secara default, sehingga fitur kamera (`image_picker`) akan langsung berfungsi di HP.



flutter build web --release

npx vercel --prod build/web
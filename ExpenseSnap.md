Saya ingin membuat project aplikasi berbasis flutter untuk scan struk nota yang difoto lalu ia akan otomatis masuk ke aplikasi sebagai catatan pengeluaran harian, mingguan, bulanan, bahkan tahunan.

---

**_ Tech Stack Utama _**

1. Frontend & Framework Mobile

- Framework: Flutter (Bisa langsung di-build untuk Android & iOS).
- State Management: Riverpod (Menggunakan package flutter_riverpod dan riverpod_annotation untuk code-generation). Sangat tangguh untuk menangani loading state saat memanggil API Gemini dan menyimpan data ke database.

2. AI & Ekstraksi Data (OCR)

- Engine: Google Gemini 2.5 Flash API.
- Integrasi: Package google_generative_ai (SDK resmi dari Google untuk Dart/Flutter).
- Konsep: Kita akan mengirimkan gambar struk beserta System Prompt agar Gemini membaca teksnya dan langsung mengembalikan data dalam format JSON (Tanggal, Total Harga, Nama Toko, dsb).

3. Backend, Database & Auth

- BaaS (Backend as a Service): Supabase.
- Database: PostgreSQL bawaan Supabase. Kita akan membuat tabel transactions yang berisi kolom-kolom hasil ekstraksi tadi.
- Storage: Supabase Storage untuk menyimpan foto asli struk sebagai bukti audit/arsip (jika user ingin melihat kembali struk aslinya).
- Auth: Supabase Auth agar setiap pengguna punya data keuangan masing-masing yang aman.

4. Visualisasi & UI Tools (Package Pendukung Flutter)

- Kamera & Gambar: image_picker (untuk ambil foto/galeri).
- Grafik Laporan: fl_chart untuk membuat grafik pie chart (kategori pengeluaran) atau bar chart (pengeluaran harian/mingguan/bulanan).
- Export Laporan (Opsional): Package pdf atau excel jika ke depannya ingin ada fitur cetak laporan tahunan.

---

**_ Alur Kerja Aplikasi (Data Flow) _**

1. Ambil Gambar: User memfoto struk (menggunakan image_picker).

2. Kirim ke Gemini (via Riverpod): \* Gambar dikonversi menjadi bytes.

- Riverpod memanggil fungsi untuk menembak Gemini API.
- Di UI, Riverpod secara otomatis menampilkan loading spinner menggunakan AsyncValue.loading().

3. Terima & Parse JSON: Gemini membalas dengan teks berformat JSON. Aplikasi Flutter men-decode JSON tersebut menjadi objek Dart (misal: TransactionModel).

4. Validasi (Form UI): \* Riverpod mengubah state menjadi AsyncValue.data().

- Layar menampilkan Form Input yang sudah terisi otomatis dengan data dari Gemini.
- User memvalidasi (misal: memperbaiki harga kalau ada salah baca, atau mengubah kategori dari "Lainnya" menjadi "Makan Siang").

5. Simpan ke Supabase: Setelah user klik "Simpan", Riverpod akan mengirim data tersebut ke tabel PostgreSQL di Supabase.

6. Update Dashboard: Beranda aplikasi yang menggunakan Stream dari Supabase secara otomatis (real-time) akan memperbarui grafik pengeluaran (Harian/Bulanan) tanpa perlu refresh halaman.

---

**_ Database SQL Buat Supabase _**

-- 1. Buat tipe ENUM untuk kategori pengeluaran (Opsional, tapi bagus untuk konsistensi)
CREATE TYPE expense_category AS ENUM (
'makanan', 'transportasi', 'belanja', 'tagihan', 'kesehatan', 'hiburan', 'lainnya'
);

-- 2. Buat tabel transactions
CREATE TABLE transactions (
id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
user_id UUID REFERENCES auth.users(id) NOT NULL, -- Relasi ke sistem Auth bawaan Supabase
transaction_date DATE NOT NULL,
merchant_name TEXT NOT NULL,
total_amount DECIMAL(12, 2) NOT NULL CHECK (total_amount >= 0),
category expense_category DEFAULT 'lainnya',
receipt_image_url TEXT, -- URL file struk di Supabase Storage
raw_ocr_text TEXT, -- Opsional: menyimpan data mentah JSON dari Gemini untuk debug
created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 3. Aktifkan Row Level Security (RLS)
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;

-- 4. Buat Kebijakan RLS (Policies)
-- User hanya bisa melihat data mereka sendiri
CREATE POLICY "Users can view their own transactions"
ON transactions FOR SELECT
USING (auth.uid() = user_id);

-- User hanya bisa memasukkan data mereka sendiri
CREATE POLICY "Users can insert their own transactions"
ON transactions FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- User hanya bisa mengupdate data mereka sendiri
CREATE POLICY "Users can update their own transactions"
ON transactions FOR UPDATE
USING (auth.uid() = user_id);

-- User hanya bisa menghapus data mereka sendiri
CREATE POLICY "Users can delete their own transactions"
ON transactions FOR DELETE
USING (auth.uid() = user_id);

---

**_ Struktur Folder Dan Files Flutter Yang Clean _**

lib/
├── core/ # Kode fundamental yang dipakai di seluruh aplikasi
│ ├── constants/ # Warna, tema, API keys
│ ├── network/ # Setup Supabase client & Gemini client
│ ├── utils/ # Format mata uang (Rupiah), date formatter
│ └── widgets/ # Reusable UI (CustomButton, LoadingOverlay)
│
├── features/ # Modul berdasarkan fitur utama aplikasi
│ ├── auth/ # Fitur Login/Register
│ │ ├── data/ # Repository untuk Auth Supabase
│ │ ├── domain/ # Model User
│ │ └── presentation/ # UI Login & provider state Auth
│ │
│ ├── dashboard/ # Fitur Ringkasan & Grafik Utama
│ │ └── presentation/ # Halaman beranda, widget grafik, provider filter bulan
│ │
│ ├── scanner/ # Fitur Kamera & OCR Gemini (Inti Aplikasi)
│ │ ├── data/ # Repository pemanggil API Gemini & Storage
│ │ ├── domain/ # Model struktur JSON dari Gemini
│ │ └── presentation/ # UI Kamera, provider Gemini state
│ │
│ ├── transactions/ # Fitur CRUD & Daftar Pengeluaran
│ │ ├── data/ # Repository operasi CRUD ke Supabase DB
│ │ ├── domain/ # TransactionModel (dari data JSON / DB)
│ │ └── presentation/ # Halaman riwayat, form validasi, provider daftar transaksi
│ │
├── app.dart # Konfigurasi MaterialApp, routing (go_router disarankan)
└── main.dart # Entry point, inisialisasi ProviderScope & Supabase

---

**_ Daftar Halaman (Screens) yang Dibutuhkan _**

1. Authentication Screens
   Splash Screen: Memeriksa apakah user session (Supabase Auth) masih aktif. Jika aktif, lempar ke Dashboard. Jika tidak, lempar ke Login.
   Login / Register Page: Form masuk menggunakan email/password atau OAuth (Google Sign-In).

2. Main App (Dibungkus Bottom Navigation Bar)
   Dashboard Page (Tab 1 - Beranda):
   Menampilkan total pengeluaran bulan ini (Angka besar di atas).
   Grafik statistik (Pie chart untuk kategori, Bar chart untuk harian).
   List 5 transaksi terbaru.
   History Page (Tab 2 - Riwayat):
   Menampilkan daftar lengkap seluruh transaksi.
   Terdapat fitur filter (Bulan, Tahun, Kategori).
   Settings / Profile Page (Tab 3):
   Informasi akun.
   Tombol Export Data (Generate PDF/Excel laporan bulanan).
   Tombol Logout.

3. Flow Scanner & Entry (Floating Action Button di tengah Bottom Nav)
   Camera Screen: Halaman penuh membuka kamera untuk memfoto struk (dilengkapi grid/guidelines). Juga menyediakan tombol untuk mengambil gambar dari Gallery.

   Validation / Form Entry Screen: \* Halaman menampilkan loading state (animasi memproses OCR).
   Setelah JSON dari Gemini diterima, muncul Form Input yang sudah terisi otomatis (pre-filled): Tanggal, Nama Toko, Kategori, dan Total Harga.
   User memverifikasi dan mengoreksi data tersebut, lalu menekan tombol "Simpan ke Database".

4. Detail Transaksi (Sub-Page)
   Transaction Detail Screen: Halaman saat user menekan salah satu riwayat transaksi. Menampilkan detail data beserta gambar struk asli (diambil dari URL Supabase Storage) jika mereka butuh mengecek ulang.

Mari kita mulai eksekusinya. Karena kita akan membangun ini secara bertahap dan terstruktur, langkah pertama yang paling krusial adalah inisialisasi project dan memasang semua _dependencies_ dasar yang sudah kita bahas.

### 1. Inisialisasi Project Flutter

Jalankan perintah ini di terminal untuk membuat project baru. Kita beri nama `ExpenseSnap` (atau sesuaikan dengan preferensimu):

```bash
flutter create expensesnap
cd expensesnap
```

### 2. Install Dependencies (Package)

Kita akan menginstal _package_ utama dan _package_ khusus _development_ (untuk _code generation_ Riverpod). Jalankan dua perintah ini secara berurutan:

**Package Utama:**

```bash
flutter pub add flutter_riverpod riverpod_annotation supabase_flutter google_generative_ai image_picker go_router intl
```

_(Catatan: `intl` ditambahkan untuk memformat angka menjadi Rupiah (Rp) nanti)._

**Package Development (Dev Dependencies):**

```bash
flutter pub add dev:build_runner dev:riverpod_generator dev:riverpod_lint dev:custom_lint
```

### 3. Setup Koneksi Supabase & ProviderScope di `main.dart`

Sekarang, buka project-nya di _code editor_ favoritmu (VS Code / Android Studio). Buka file `lib/main.dart`, hapus semua kodenya, dan ganti dengan inisialisasi dasar berikut.

Pastikan kamu mengganti `YOUR_SUPABASE_URL` dan `YOUR_SUPABASE_ANON_KEY` dengan kredensial dari _dashboard_ Supabase milikmu (di menu Project Settings > API).

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// TODO: Ganti dengan URL dan Anon Key dari dashboard Supabase kamu
const String supabaseUrl = 'YOUR_SUPABASE_URL';
const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Supabase
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  // Bungkus aplikasi dengan ProviderScope agar Riverpod bisa berjalan
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OCR Keuangan',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      // Untuk sementara kita arahkan ke Scaffold kosong
      // Nanti akan diganti menggunakan go_router
      home: const Scaffold(
        body: Center(
          child: Text('Setup Berhasil! Aplikasi Siap Dibangun.'),
        ),
      ),
    );
  }
}
```

### 4. Setup Struktur Folder

Sesuai arsitektur _Feature-First_ yang kita sepakati, buatlah struktur folder di dalam direktori `lib/` agar rapi sejak awal. Kamu bisa membuatnya manual atau menjalankan perintah _bash_ ini jika menggunakan terminal Unix/Git Bash:

```bash
mkdir -p lib/core/constants lib/core/network lib/core/utils lib/core/widgets
mkdir -p lib/features/auth/presentation lib/features/auth/domain lib/features/auth/data
mkdir -p lib/features/dashboard/presentation
mkdir -p lib/features/scanner/presentation lib/features/scanner/domain lib/features/scanner/data
mkdir -p lib/features/transactions/presentation lib/features/transactions/domain lib/features/transactions/data
```

---

Setelah _setup_ dasar dan _wiring_ ke Supabase ini selesai, dari mana kamu ingin kita mulai mengkoding fiturnya: apakah kita bangun halaman Auth (Splash & Login) terlebih dahulu agar _session_ Supabase aman, atau ingin langsung melompat membuat halaman Scanner dan integrasi Gemini API untuk memastikan _proof of concept_ OCR-nya berjalan mulus?

Kita akan membangun sistem autentikasi yang solid menggunakan **Supabase Auth** dan mengelola statusnya dengan **Riverpod**. Dengan pendekatan ini, aplikasi akan secara otomatis mendeteksi apakah pengguna sudah login atau belum.

### 1. Auth Repository (Data Layer)

Buat file baru di `lib/features/auth/data/auth_repository.dart`. File ini berfungsi untuk membungkus fungsi-fungsi utama dari Supabase.

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final _supabase = Supabase.instance.client;

  // Mendapatkan session saat ini
  Session? get currentSession => _supabase.auth.currentSession;

  // Mendengarkan perubahan status auth
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Sign Up
  Future<AuthResponse> signUp(String email, String password) async {
    return await _supabase.auth.signUp(email: email, password: password);
  }

  // Login
  Future<AuthResponse> signIn(String email, String password) async {
    return await _supabase.auth.signInWithPassword(email: email, password: password);
  }

  // Logout
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
```

### 2. Auth Provider (Logic Layer)

Buat file `lib/features/auth/presentation/auth_provider.dart`. Kita akan menggunakan `StreamProvider` untuk memantau status login secara _real-time_.

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/auth_repository.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository());

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.read(authRepositoryProvider).authStateChanges;
});
```

### 3. Setup Routing dengan GoRouter

Agar perpindahan halaman antar Splash, Login, dan Dashboard mulus, kita gunakan `go_router`. Buat file `lib/core/network/router.dart`.

```dart
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/dashboard', builder: (context, state) => const DashboardScreen()),
    ],
  );
});
```

### 4. Implementasi UI Halaman

#### A. Splash Screen (`lib/features/auth/presentation/splash_screen.dart`)

Halaman ini bertugas mengarahkan pengguna berdasarkan status sesi mereka.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'auth_provider.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen status auth
    ref.listen(authStateProvider, (previous, next) {
      next.whenData((state) {
        if (state.session != null) {
          context.go('/dashboard');
        } else {
          context.go('/login');
        }
      });
    });

    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet, size: 80, color: Colors.teal),
            SizedBox(height: 20),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
```

#### B. Login Screen (`lib/features/auth/presentation/login_screen.dart`)

Form sederhana untuk masuk ke aplikasi.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  void _login() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).signIn(
        _emailController.text,
        _passwordController.text,
      );
      // Navigasi ditangani otomatis oleh listener di Splash atau Router
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Masuk')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
            const SizedBox(height: 20),
            _isLoading
              ? const CircularProgressIndicator()
              : ElevatedButton(onPressed: _login, child: const Text('Login')),
            TextButton(
              onPressed: () => context.push('/register'),
              child: const Text('Belum punya akun? Daftar di sini'),
            ),
          ],
        ),
      ),
    );
  }
}
```

#### C. Register Screen (`lib/features/auth/presentation/register_screen.dart`)

Hampir sama dengan login, namun memanggil fungsi `signUp`.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _register() async {
    try {
      await ref.read(authRepositoryProvider).signUp(
        _emailController.text,
        _passwordController.text,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cek email Anda untuk konfirmasi!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Akun')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _register, child: const Text('Daftar')),
          ],
        ),
      ),
    );
  }
}
```

### Langkah Terakhir: Update `main.dart`

Ubah `MyApp` untuk menggunakan `routerProvider`.

```dart
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'OCR Keuangan',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
```

### 1. Persiapan Data (Repository & Provider)

Sebelum ke UI, kita butuh cara mengambil data dari Supabase. Buat file `lib/features/transactions/data/transaction_repository.dart`:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/transaction_model.dart'; // Kita asumsikan model sudah ada nanti

class TransactionRepository {
  final _supabase = Supabase.instance.client;

  // Mengambil transaksi terbaru
  Stream<List<Map<String, dynamic>>> watchRecentTransactions() {
    return _supabase
        .from('transactions')
        .stream(primaryKey: ['id'])
        .order('transaction_date', ascending: false)
        .limit(10);
  }

  // Mengambil total pengeluaran bulan ini (Logic sederhana)
  Future<double> getTotalSpendingThisMonth() async {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1).toIso8601String();

    final response = await _supabase
        .from('transactions')
        .select('total_amount')
        .gte('transaction_date', firstDay);

    final List data = response as List;
    return data.fold(0.0, (prev, element) => prev + (element['total_amount'] ?? 0));
  }
}
```

### 2. Implementasi UI Dashboard Utama

Buka `lib/features/dashboard/presentation/dashboard_screen.dart`. Kita akan menggunakan `Stack` untuk membuat navigasi "Pill" yang melayang.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;

  // List halaman untuk navigasi
  final List<Widget> _pages = [
    const HomeView(),       // Ringkasan & Grafik
    const HistoryView(),    // Daftar Riwayat Lengkap
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Agar konten muncul di balik navbar melayang
      body: _pages[_selectedIndex],

      // Floating Pill Navigation Bar
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 30),
        height: 70,
        decoration: BoxDecoration(
          color: Colors.teal.shade900,
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _navItem(Icons.grid_view_rounded, 0, "Beranda"),

            // Tombol Scan di Tengah
            GestureDetector(
              onTap: () => context.push('/scanner'), // Nanti kita buat routernya
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.qr_code_scanner_rounded,
                  color: Colors.teal, size: 30),
              ),
            ),

            _navItem(Icons.history_rounded, 1, "Riwayat"),
          ],
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, int index, String label) {
    bool isActive = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isActive ? Colors.white : Colors.white60, size: 28),
          if (isActive)
            Container(
              margin: const EdgeInsets.only(top: 4),
              height: 4,
              width: 4,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            )
        ],
      ),
    );
  }
}
```

### 3. Tampilan Konten Beranda (`HomeView`)

Halaman ini berisi ringkasan angka dan grafik. (Gunakan `intl` untuk format Rupiah).

```dart
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 120,
          floating: true,
          backgroundColor: Colors.transparent,
          flexibleSpace: FlexibleSpaceBar(
            title: const Text("Halo, Penghemat!",
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            centerTitle: false,
          ),
          actions: [
            IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none))
          ],
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ringkasan Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.teal, Colors.teal.shade700]),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Pengeluaran Bulan Ini", style: TextStyle(color: Colors.white70)),
                      SizedBox(height: 8),
                      Text("Rp 2.450.000",
                        style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
                const Text("Statistik Mingguan",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),

                // Placeholder untuk Grafik (fl_chart)
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(child: Text("Grafik Pengeluaran")),
                ),

                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Transaksi Terakhir",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    TextButton(onPressed: () {}, child: const Text("Lihat Semua")),
                  ],
                ),

                // List Transaksi Terakhir
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 5,
                  itemBuilder: (context, index) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: Colors.orange.shade100,
                        child: const Icon(Icons.fastfood, color: Colors.orange),
                      ),
                      title: const Text("Makan Siang - Warteg"),
                      subtitle: const Text("Hari ini, 12:30"),
                      trailing: const Text("-Rp 25.000",
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                    );
                  },
                ),
                const SizedBox(height: 100), // Spasi agar tidak tertutup navbar
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// View sederhana untuk Riwayat
class HistoryView extends StatelessWidget {
  const HistoryView({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text("Halaman Riwayat"));
}
```

### Langkah Selanjutnya:

Sekarang Dashboard sudah siap dengan UI yang _clean_. Kita punya:

1.  **Top Bar** yang menyapa user.
2.  **Summary Card** dengan gradien warna teal.
3.  **Floating Pill Navbar** yang memiliki tombol Scan di tengah.

### 1. Buat Model Data (Domain Layer)

Buat file `lib/features/scanner/domain/receipt_data.dart`. Ini adalah _blueprint_ untuk menampung hasil ekstrak dari Gemini sebelum masuk ke _database_.

```dart
class ReceiptData {
  final String date;
  final String merchantName;
  final double totalAmount;
  final String category;

  ReceiptData({
    required this.date,
    required this.merchantName,
    required this.totalAmount,
    required this.category,
  });

  factory ReceiptData.fromJson(Map<String, dynamic> json) {
    return ReceiptData(
      // Memberikan fallback value jika OCR gagal membaca bagian tertentu
      date: json['tanggal'] ?? DateTime.now().toIso8601String().split('T')[0],
      merchantName: json['nama_merchant'] ?? 'Tidak Diketahui',
      totalAmount: (json['total_pengeluaran'] ?? 0).toDouble(),
      category: json['kategori'] ?? 'lainnya',
    );
  }
}
```

### 2. Setup Gemini Repository (Data Layer)

Buat file `lib/features/scanner/data/gemini_repository.dart`. Di sini kita menembak API Gemini. Fitur keren dari Gemini Flash adalah kita bisa memaksa outputnya menjadi JSON murni menggunakan `responseMimeType`.

````dart
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiRepository {
  // TODO: Masukkan API Key kamu di sini atau gunakan environment variable (.env)
  static const String _apiKey = 'YOUR_GEMINI_API_KEY';

  late final GenerativeModel _model;

  GeminiRepository() {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        // Ini kunci agar output pasti berupa JSON murni tanpa markdown ```json
        responseMimeType: 'application/json',
      ),
    );
  }

  Future<String> analyzeReceipt(Uint8List imageBytes) async {
    // System prompt yang sangat spesifik
    final prompt = '''
      Kamu adalah sistem OCR keuangan ahli. Analisis gambar struk ini dan ekstrak informasinya.
      Kembalikan HANYA format JSON dengan struktur persis seperti ini:
      {
        "tanggal": "YYYY-MM-DD",
        "nama_merchant": "Nama Toko/Merchant",
        "total_pengeluaran": 50000,
        "kategori": "makanan/transportasi/belanja/tagihan/kesehatan/hiburan/lainnya"
      }
      Jika tanggal tidak terlihat, tebak dari konteks atau kosongkan.
      Pastikan total_pengeluaran adalah angka (integer/float) tanpa simbol mata uang.
    ''';

    final content = [
      Content.multi([
        TextPart(prompt),
        DataPart('image/jpeg', imageBytes),
      ])
    ];

    final response = await _model.generateContent(content);

    if (response.text == null) {
      throw Exception("Gagal mengekstrak data dari struk.");
    }

    return response.text!;
  }
}
````

### 3. Buat Provider & Logic Scanner (Controller)

Buat file `lib/features/scanner/presentation/scanner_provider.dart`. Ini akan menyatukan `image_picker`, `image_cropper`, dan `GeminiRepository`.

_(Catatan: pastikan kamu sudah menambahkan konfigurasi Android/iOS untuk `image_cropper` sesuai dokumentasi package-nya di `AndroidManifest.xml` dan `Info.plist`)_.

```dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../data/gemini_repository.dart';
import '../domain/receipt_data.dart';

final geminiRepoProvider = Provider((ref) => GeminiRepository());

// State untuk menyimpan hasil scan
final scannedReceiptProvider = StateProvider<ReceiptData?>((ref) => null);

// Provider untuk menangani status loading & error selama proses
final scannerControllerProvider = StateNotifierProvider<ScannerController, AsyncValue<void>>((ref) {
  return ScannerController(ref);
});

class ScannerController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  final ImagePicker _picker = ImagePicker();

  ScannerController(this._ref) : super(const AsyncData(null));

  Future<void> processReceipt(ImageSource source) async {
    try {
      state = const AsyncLoading(); // Trigger loading state di UI

      // 1. Ambil Gambar
      final XFile? image = await _picker.pickImage(source: source);
      if (image == null) {
        state = const AsyncData(null); // User cancel
        return;
      }

      // 2. Crop Gambar agar fokus ke struk
      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Potong Struk',
            toolbarColor: Colors.teal,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
        ],
      );

      if (croppedFile == null) {
        state = const AsyncData(null); // User cancel crop
        return;
      }

      // 3. Konversi ke Bytes untuk Gemini
      final bytes = await File(croppedFile.path).readAsBytes();

      // 4. Kirim ke Gemini API
      final geminiRepo = _ref.read(geminiRepoProvider);
      final jsonString = await geminiRepo.analyzeReceipt(bytes);

      // 5. Parse JSON ke Model
      final Map<String, dynamic> jsonData = jsonDecode(jsonString);
      final receiptData = ReceiptData.fromJson(jsonData);

      // 6. Simpan hasil ke State Provider agar bisa dibaca di halaman form
      _ref.read(scannedReceiptProvider.notifier).state = receiptData;

      state = const AsyncData(null); // Selesai loading
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
```

### 4. UI Halaman Scanner (`ScannerScreen`)

Buat file `lib/features/scanner/presentation/scanner_screen.dart`. Halaman ini akan memanggil logic di atas dan menampilkan _loading overlay_ saat Gemini sedang berpikir.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'scanner_provider.dart';

class ScannerScreen extends ConsumerWidget {
  const ScannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Memantau state loading/error dari proses scan
    final scannerState = ref.watch(scannerControllerProvider);

    // Listener untuk navigasi otomatis jika sukses scan
    ref.listen(scannerControllerProvider, (previous, next) {
      next.whenOrNull(
        data: (_) {
          // Jika tidak loading dan hasil struk sudah ada, pindah ke form validasi
          if (ref.read(scannedReceiptProvider) != null) {
             // context.pushReplacement('/form-validasi'); // Nanti kita buat rutenya
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('Berhasil! Data siap di-review.'), backgroundColor: Colors.green)
             );
          }
        },
        error: (err, stack) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal membaca struk: $err'), backgroundColor: Colors.red)
          );
        },
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Struk Baru'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.receipt_long_rounded, size: 100, color: Colors.teal),
                const SizedBox(height: 30),
                const Text(
                  'Ambil foto struk atau pilih dari galeri.\nAI kami akan mengekstrak datanya otomatis.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildActionButton(
                      icon: Icons.camera_alt,
                      label: 'Kamera',
                      onTap: () => ref.read(scannerControllerProvider.notifier).processReceipt(ImageSource.camera),
                    ),
                    const SizedBox(width: 20),
                    _buildActionButton(
                      icon: Icons.photo_library,
                      label: 'Galeri',
                      onTap: () => ref.read(scannerControllerProvider.notifier).processReceipt(ImageSource.gallery),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Loading Overlay jika Gemini sedang memproses
          if (scannerState.isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.teal),
                    SizedBox(height: 16),
                    Text(
                      'AI sedang membaca struk...',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
        decoration: BoxDecoration(
          color: Colors.teal.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.teal.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: Colors.teal),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
          ],
        ),
      ),
    );
  }
}
```

_Jangan lupa tambahkan `GoRoute(path: '/scanner', builder: (context, state) => const ScannerScreen()),` di file router kamu ya!_

---

### Alur yang Terjadi:

1. User tap **Kamera/Galeri**.
2. Aplikasi membuka kamera/galeri, lalu membuka mode **Crop**.
3. UI memunculkan _overlay_ "AI sedang membaca struk...".
4. _Bytes_ gambar dikirim ke Gemini. Gemini menjawab dengan **JSON murni**.
5. JSON di-decode menjadi `ReceiptData` dan disimpan ke dalam _state_ `scannedReceiptProvider`.
6. Tampil notifikasi berhasil (nanti ini akan kita arahkan ke halaman form).

### 🔑 1. Cara Mendapatkan API Key Gemini

Untuk menggunakan model Gemini 2.5 Flash, kamu membutuhkan API Key dari platform resmi Google untuk developer.

1. Buka browser dan akses **[Google AI Studio](https://aistudio.google.com/)**.
2. _Login_ menggunakan akun Google kamu.
3. Di panel sebelah kiri, cari dan klik menu **"Get API key"**.
4. Klik tombol biru **"Create API key"**.
5. Pilih **"Create API key in a new project"**.
6. Salin (copy) kombinasi huruf dan angka acak yang muncul. Itu adalah API Key kamu. Jaga kerahasiaannya!

---

### ⚙️ 2. Konfigurasi `image_cropper` (dan `image_picker`)

**Untuk Android (`android/app/src/main/AndroidManifest.xml`):**
Buka file tersebut dan tambahkan _activity_ untuk `UCropActivity` di dalam tag `<application>`, sejajar dengan `<activity>` utama Flutter.

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application
        android:label="ocr_keuangan"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">

        <activity android:name=".MainActivity" ... >
           ...
        </activity>

        <activity
            android:name="com.yalantis.ucrop.UCropActivity"
            android:screenOrientation="portrait"
            android:theme="@style/Theme.AppCompat.Light.NoActionBar"/>

    </application>
</manifest>
```

**Untuk iOS (`ios/Runner/Info.plist`):**
_Package_ `image_cropper` tidak membutuhkan pengaturan khusus di iOS, **tetapi** karena kita menggunakan `image_picker` (untuk mengambil foto sebelum di-crop), Apple mewajibkan kamu mendeklarasikan alasan penggunaan kamera dan galeri. Tambahkan _key_ berikut sebelum tag `</dict>` terakhir:

```xml
<key>NSCameraUsageDescription</key>
<string>Aplikasi membutuhkan akses kamera untuk memindai struk pengeluaran.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Aplikasi membutuhkan akses galeri untuk memilih foto struk yang sudah ada.</string>
```

---

### 🔀 3. Update File Router

Buka file `lib/core/network/router.dart` dan tambahkan rute untuk `ScannerScreen`.

```dart
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/scanner/presentation/scanner_screen.dart'; // Import Scanner

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/dashboard', builder: (context, state) => const DashboardScreen()),
      // Tambahkan route ini
      GoRoute(path: '/scanner', builder: (context, state) => const ScannerScreen()),
    ],
  );
});
```

---

### 🔒 4. Setup `.env` untuk Arsitektur Clean

Menyimpan API Key atau URL di dalam _source code_ secara langsung (di-_hardcode_) sangat berbahaya jika diunggah ke GitHub. Kita akan menggunakan `flutter_dotenv`.

**Langkah A: Install Package**
Jalankan di terminal:

```bash
flutter pub add flutter_dotenv
```

**Langkah B: Buat File `.env`**
Buat file baru tepat di folder utama (sejajar dengan `pubspec.yaml`), beri nama `.env`, lalu isi dengan _credentials_ milikmu:

```env
SUPABASE_URL=https://xyzxyz.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUz...
GEMINI_API_KEY=AIzaSy...
```

**Langkah C: Daftarkan di `pubspec.yaml`**
Agar file `.env` bisa dibaca oleh Flutter, tambahkan di bagian `assets`:

```yaml
flutter:
  uses-material-design: true
  assets:
    - .env # Tambahkan baris ini
```

_(Penting: Tambahkan tulisan `.env` di dalam file `.gitignore` agar file ini tidak ikut ter-push ke GitHub)._

**Langkah D: Buat Class Pengelola (Clean Architecture)**
Buat file `lib/core/constants/env_config.dart`. Ini adalah _best practice_ agar kalau ada variabel yang kosong, aplikasi langsung memberikan peringatan.

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String get supabaseUrl => _get('SUPABASE_URL');
  static String get supabaseAnonKey => _get('SUPABASE_ANON_KEY');
  static String get geminiApiKey => _get('GEMINI_API_KEY');

  static String _get(String name) {
    final value = dotenv.env[name];
    if (value == null) {
      throw Exception('Environment variable $name tidak ditemukan di file .env');
    }
    return value;
  }
}
```

**Langkah E: Inisialisasi di `main.dart` & Update Repository**
Terakhir, pastikan memuat `.env` saat aplikasi pertama kali berjalan.

```dart
// Buka lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import ini
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/env_config.dart';
import 'core/network/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load file .env pertama kali
  await dotenv.load(fileName: ".env");

  // Inisialisasi Supabase menggunakan EnvConfig
  await Supabase.initialize(
    url: EnvConfig.supabaseUrl,
    anonKey: EnvConfig.supabaseAnonKey,
  );

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}
```

_(Setelah ini, kamu bisa membuka `lib/features/scanner/data/gemini_repository.dart` dan mengganti `static const String _apiKey = 'YOUR_GEMINI_API_KEY';` menjadi `final String apiKey = EnvConfig.geminiApiKey;`)_

### 1. Buat Bucket Storage di Supabase

Sebelum mengubah kode Flutter, kita harus menyiapkan "wadah" penyimpanannya di Supabase. Buka **SQL Editor** di dashboard Supabase kamu dan jalankan _query_ ini untuk membuat _bucket_ bernama `receipts` lengkap dengan aturan RLS-nya:

```sql
-- Membuat bucket public bernama 'receipts'
INSERT INTO storage.buckets (id, name, public)
VALUES ('receipts', 'receipts', true);

-- Policy: User yang login bisa mengupload file
CREATE POLICY "User bisa upload struk"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'receipts' AND (storage.foldername(name))[1] = auth.uid()::text);

-- Policy: User yang login bisa melihat file
CREATE POLICY "User bisa melihat struk"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'receipts');
```

_(Catatan: Policy `foldername` di atas memastikan user hanya bisa upload ke dalam folder dengan nama ID mereka sendiri)._

---

### 2. Update Model `ReceiptData`

Kita perlu menambahkan _path_ (lokasi) gambar hasil _crop_ agar bisa dibawa ke halaman Validasi. Buka `lib/features/scanner/domain/receipt_data.dart`:

```dart
class ReceiptData {
  final String date;
  final String merchantName;
  final double totalAmount;
  final String category;
  final String imagePath; // TAMBAHAN: Menyimpan lokasi file lokal

  ReceiptData({
    required this.date,
    required this.merchantName,
    required this.totalAmount,
    required this.category,
    required this.imagePath, // TAMBAHAN
  });

  // Tambahkan parameter imagePath di factory
  factory ReceiptData.fromJson(Map<String, dynamic> json, String imagePath) {
    return ReceiptData(
      date: json['tanggal'] ?? DateTime.now().toIso8601String().split('T')[0],
      merchantName: json['nama_merchant'] ?? 'Tidak Diketahui',
      totalAmount: (json['total_pengeluaran'] ?? 0).toDouble(),
      category: json['kategori'] ?? 'lainnya',
      imagePath: imagePath, // TAMBAHAN
    );
  }
}
```

---

### 3. Update `ScannerController`

Buka `lib/features/scanner/presentation/scanner_provider.dart`. Kita update cara memanggil `ReceiptData.fromJson` agar memasukkan `croppedFile.path`.

```dart
// ... (kode sebelumnya)
      // 4. Kirim ke Gemini API
      final geminiRepo = _ref.read(geminiRepoProvider);
      final jsonString = await geminiRepo.analyzeReceipt(bytes);

      // 5. Parse JSON ke Model (UPDATE BAGIAN INI)
      final Map<String, dynamic> jsonData = jsonDecode(jsonString);

      // Masukkan path gambar hasil crop ke dalam model
      final receiptData = ReceiptData.fromJson(jsonData, croppedFile.path);

      // 6. Simpan hasil ke State Provider
      _ref.read(scannedReceiptProvider.notifier).state = receiptData;
// ...
```

---

### 4. Update `TransactionRepository` (Target Utama)

Buka `lib/features/transactions/data/transaction_repository.dart`. Kita akan memodifikasi `insertTransaction` untuk mengupload `File` gambar terlebih dahulu, mengambil URL publiknya, lalu menyimpannya bersama data transaksi.

```dart
import 'dart:io'; // Pastikan import dart:io untuk File
import 'package:supabase_flutter/supabase_flutter.dart';

class TransactionRepository {
  final _supabase = Supabase.instance.client;

  // ... (fungsi lainnya) ...

  Future<void> insertTransaction({
    required String date,
    required String merchantName,
    required double amount,
    required String category,
    required File imageFile, // TAMBAHAN: Menerima File gambar
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User belum login!');

    String? imageUrl;

    try {
      // 1. Persiapkan nama file unik (Format: user_id/timestamp_namafile.jpg)
      final fileExtension = imageFile.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      final filePath = '${user.id}/$fileName'; // Folder per user

      // 2. Upload ke Supabase Storage (bucket: receipts)
      await _supabase.storage.from('receipts').upload(
            filePath,
            imageFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      // 3. Dapatkan Public URL dari gambar yang baru diupload
      imageUrl = _supabase.storage.from('receipts').getPublicUrl(filePath);

    } catch (e) {
      // Kamu bisa melempar error di sini jika upload gambar adalah WAJIB
      throw Exception('Gagal mengupload gambar struk: $e');
    }

    // 4. Simpan ke tabel transactions beserta URL gambarnya
    await _supabase.from('transactions').insert({
      'user_id': user.id,
      'transaction_date': date,
      'merchant_name': merchantName,
      'total_amount': amount,
      'category': category,
      'receipt_image_url': imageUrl, // TAMBAHAN: Menyimpan URL
    });
  }
}
```

---

### 5. Update `ValidationScreen`

Terakhir, buka `lib/features/scanner/presentation/validation_screen.dart`. Kita akan mengubah fungsi `_saveToDatabase` untuk mengirimkan file gambar, dan (sebagai bonus UX) menampilkan _thumbnail_ gambar struk di atas form!

Tambahkan `dart:io` di bagian atas file:

```dart
import 'dart:io';
// ... import lainnya
```

Lalu sesuaikan fungsi `_saveToDatabase`:

```dart
  Future<void> _saveToDatabase() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final receiptData = ref.read(scannedReceiptProvider);
      if (receiptData == null) throw Exception('Data struk hilang!');

      final repo = ref.read(transactionRepoProvider);

      // Mengirimkan File ke repository
      await repo.insertTransaction(
        date: _dateController.text,
        merchantName: _merchantController.text,
        amount: double.parse(_amountController.text),
        category: _selectedCategory,
        imageFile: File(receiptData.imagePath), // BACA PATH DARI MODEL
      );

      ref.read(scannedReceiptProvider.notifier).state = null;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaksi & Struk berhasil disimpan!'), backgroundColor: Colors.green),
        );
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
```

_Agar tampilan Form Validasi makin cantik, kamu bisa menambahkan widget ini di dalam `Column` paling atas di `ValidationScreen` untuk menampilkan gambar struknya._

```dart
              // Tambahkan ini di bawah teks instruksi di ValidationScreen
              if (ref.read(scannedReceiptProvider)?.imagePath != null)
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(ref.read(scannedReceiptProvider)!.imagePath),
                      height: 150,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
```

Untuk menghidupkan **Dashboard**, kita akan mengintegrasikan data dari Supabase agar grafik dan daftar riwayat tidak lagi menggunakan data statis (_dummy_). Kita akan menggunakan package `fl_chart` yang sudah kita rencanakan sebelumnya.

Pastikan kamu sudah menjalankan `flutter pub add fl_chart` di terminal.

### 1. Buat Transaction Model

Buat file `lib/features/transactions/domain/transaction_model.dart` untuk memetakan data dari PostgreSQL ke objek Dart.

```dart
class TransactionModel {
  final String id;
  final DateTime date;
  final String merchantName;
  final double amount;
  final String category;
  final String? imageUrl;

  TransactionModel({
    required this.id,
    required this.date,
    required this.merchantName,
    required this.amount,
    required this.category,
    this.imageUrl,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      date: DateTime.parse(map['transaction_date']),
      merchantName: map['merchant_name'],
      amount: (map['total_amount'] as num).toDouble(),
      category: map['category'],
      imageUrl: map['receipt_image_url'],
    );
  }
}
```

### 2. Update Transaction Provider

Buka `lib/features/transactions/data/transaction_repository.dart` dan tambahkan provider untuk mengambil data secara _real-time_.

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ... import lainnya

final transactionsStreamProvider = StreamProvider<List<TransactionModel>>((ref) {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;

  return supabase
      .from('transactions')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId ?? '')
      .order('transaction_date', ascending: false)
      .map((data) => data.map((map) => TransactionModel.fromMap(map)).toList());
});

// Provider untuk menghitung total bulan ini
final monthlyTotalProvider = Provider<double>((ref) {
  final transactions = ref.watch(transactionsStreamProvider).value ?? [];
  final now = DateTime.now();

  return transactions
      .where((t) => t.date.month == now.month && t.date.year == now.year)
      .fold(0.0, (sum, item) => sum + item.amount);
});
```

### 3. Implementasi Grafik (Pie Chart Kategori)

Buat file widget baru `lib/features/dashboard/presentation/widgets/category_chart.dart`.

```dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../features/transactions/domain/transaction_model.dart';

class CategoryChart extends StatelessWidget {
  final List<TransactionModel> transactions;
  const CategoryChart({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    // Logika mengelompokkan data berdasarkan kategori
    Map<String, double> data = {};
    for (var t in transactions) {
      data[t.category] = (data[t.category] ?? 0) + t.amount;
    }

    final List<Color> colors = [Colors.teal, Colors.orange, Colors.red, Colors.blue, Colors.purple, Colors.amber];

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: data.entries.map((e) {
          int index = data.keys.toList().indexOf(e.key);
          return PieChartSectionData(
            color: colors[index % colors.length],
            value: e.value,
            title: '', // Kita kosongkan agar tidak berantakan
            radius: 50,
          );
        }).toList(),
      ),
    );
  }
}
```

### 4. Merapikan HomeView (Beranda)

Update `HomeView` di `lib/features/dashboard/presentation/dashboard_screen.dart` agar terhubung ke data asli.

```dart
class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsStreamProvider);
    final totalSpending = ref.watch(monthlyTotalProvider);

    return CustomScrollView(
      slivers: [
        const SliverAppBar(
          expandedHeight: 80,
          title: Text("Dashboard", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                // Card Ringkasan
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Colors.teal, Color(0xFF00796B)]),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Pengeluaran Bulan Ini", style: TextStyle(color: Colors.white70)),
                      Text(
                        "Rp ${totalSpending.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}",
                        style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Grafik Section
                const Text("Alokasi Dana", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(
                  height: 200,
                  child: transactionsAsync.when(
                    data: (data) => data.isEmpty
                        ? const Center(child: Text("Belum ada data"))
                        : CategoryChart(transactions: data),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text("Error: $e")),
                  ),
                ),

                const SizedBox(height: 30),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Terakhir", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),

                // List Terbatas (5 item terakhir)
                transactionsAsync.when(
                  data: (data) => ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: data.length > 5 ? 5 : data.length,
                    itemBuilder: (context, index) {
                      final t = data[index];
                      return ListTile(
                        leading: CircleAvatar(child: Icon(_getCategoryIcon(t.category))),
                        title: Text(t.merchantName),
                        subtitle: Text(t.date.toString().split(' ')[0]),
                        trailing: Text("-Rp ${t.amount.toInt()}", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      );
                    },
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'makanan': return Icons.restaurant;
      case 'transportasi': return Icons.directions_car;
      case 'belanja': return Icons.shopping_bag;
      default: return Icons.account_balance_wallet;
    }
  }
}
```

### 5. Merapikan HistoryView (Riwayat Lengkap)

Ubah `HistoryView` untuk menampilkan seluruh data dengan scroll yang nyaman.

```dart
class HistoryView extends ConsumerWidget {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Semua Transaksi")),
      body: transactionsAsync.when(
        data: (data) => data.isEmpty
          ? const Center(child: Text("Belum ada riwayat transaksi."))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: data.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final t = data[index];
                return ListTile(
                  leading: t.imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(t.imageUrl!, width: 50, height: 50, fit: BoxFit.cover),
                        )
                      : const CircleAvatar(child: Icon(Icons.receipt)),
                  title: Text(t.merchantName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${t.date.day}/${t.date.month}/${t.date.year} • ${t.category.toUpperCase()}"),
                  trailing: Text("Rp ${t.amount.toInt()}", style: const TextStyle(color: Colors.red)),
                );
              },
            ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Gagal memuat: $e")),
      ),
    );
  }
}
```

Dengan perubahan ini, Dashboard kamu sekarang sudah fungsional sepenuhnya:

1. **Real-time Sync**: Begitu user menyimpan struk di halaman validasi, angka di Dashboard dan grafik akan langsung berubah tanpa perlu refresh.
2. **Visualisasi**: `CategoryChart` memberikan gambaran jelas ke mana uang dihabiskan.
3. **Audit Evidence**: Di halaman Riwayat, user bisa melihat kembali bukti foto struk yang diambil dari Supabase Storage.

### 1. Tambah Dependencies

Jalankan perintah ini di terminal:

```bash
flutter pub add pdf printing path_provider
```

### 2. Manajemen State Filter (Riverpod)

Buka `lib/features/transactions/data/transaction_repository.dart`. Kita akan membuat `StateProvider` untuk menyimpan bulan dan tahun yang dipilih pengguna.

```dart
// Provider untuk menyimpan tanggal filter (default: bulan & tahun sekarang)
final filterDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

// Provider untuk mengambil data transaksi yang SUDAH DIFILTER
final filteredTransactionsProvider = StreamProvider<List<TransactionModel>>((ref) {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;
  final filterDate = ref.watch(filterDateProvider);

  // Menghitung batas awal dan akhir bulan
  final firstDay = DateTime(filterDate.year, filterDate.month, 1).toIso8601String();
  final lastDay = DateTime(filterDate.year, filterDate.month + 1, 0, 23, 59, 59).toIso8601String();

  return supabase
      .from('transactions')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId ?? '')
      .gte('transaction_date', firstDay)
      .lte('transaction_date', lastDay)
      .order('transaction_date', ascending: false)
      .map((data) => data.map((map) => TransactionModel.fromMap(map)).toList());
});
```

### 3. Service Ekspor PDF

Buat file baru `lib/core/utils/pdf_service.dart`. Service ini akan mengonversi daftar transaksi menjadi tabel di PDF.

```dart
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../features/transactions/domain/transaction_model.dart';

class PdfService {
  static Future<void> generateTransactionReport(List<TransactionModel> transactions, DateTime date) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text("Laporan Pengeluaran - ${date.month}/${date.year}",
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headers: ['Tanggal', 'Merchant', 'Kategori', 'Total'],
            data: transactions.map((t) => [
              "${t.date.day}/${t.date.month}/${t.date.year}",
              t.merchantName,
              t.category.toUpperCase(),
              "Rp ${t.amount.toInt()}"
            ]).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignment: pw.Alignment.centerLeft,
          ),
          pw.Divider(),
          pw.Container(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              "Total Keseluruhan: Rp ${transactions.fold(0.0, (sum, item) => sum + item.amount).toInt()}",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );

    // Menampilkan preview print atau langsung simpan
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }
}
```

### 4. Update UI HistoryView dengan Filter & Export

Buka `lib/features/dashboard/presentation/dashboard_screen.dart` dan perbarui bagian `HistoryView`.

```dart
class HistoryView extends ConsumerWidget {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(filterDateProvider);
    final transactionsAsync = ref.watch(filteredTransactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Riwayat Laporan"),
        actions: [
          // Tombol Ekspor PDF
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () {
              transactionsAsync.whenData((data) {
                if (data.isNotEmpty) {
                  PdfService.generateTransactionReport(data, selectedDate);
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Row Filter Bulan & Tahun
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.filter_list, color: Colors.teal),
                const SizedBox(width: 10),
                TextButton(
                  onPressed: () async {
                    // Sederhana: Pakai Month Picker (atau showDatePicker)
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2101),
                    );
                    if (picked != null) {
                      ref.read(filterDateProvider.notifier).state = picked;
                    }
                  },
                  child: Text(
                    "${_getMonthName(selectedDate.month)} ${selectedDate.year}",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // List Transaksi
          Expanded(
            child: transactionsAsync.when(
              data: (data) => data.isEmpty
                ? const Center(child: Text("Tidak ada transaksi di bulan ini."))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      final t = data[index];
                      return Card(
                        child: ListTile(
                          title: Text(t.merchantName),
                          subtitle: Text("${t.date.day} ${_getMonthName(t.date.month)}"),
                          trailing: Text("Rp ${t.amount.toInt()}",
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ),
                      );
                    },
                  ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text("Error: $e")),
            ),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ["Januari", "Februari", "Maret", "April", "Mei", "Juni",
                    "Juli", "Agustus", "September", "Oktober", "November", "Desember"];
    return months[month - 1];
  }
}
```

### Keunggulan Alur Ini:

1.  **Server-Side Filtering**: Kita menggunakan `.gte()` dan `.lte()` di Supabase. Ini jauh lebih efisien daripada mengambil semua data lalu memfilternya di aplikasi (hemat RAM dan kuota).
2.  **Reactive UI**: Begitu `filterDateProvider` berubah, data di daftar riwayat akan otomatis ter-_refresh_ secara instan.
3.  **Clean PDF**: Laporan PDF yang dihasilkan memiliki tabel yang rapi dan kalkulasi total otomatis, siap dikirim via WhatsApp atau Email.

Aplikasi sistem pencatat struk ini sekarang sudah lengkap secara fungsional (End-to-End). Mulai dari **Auth -> OCR AI -> Database -> Storage -> Statistik -> Laporan PDF**.

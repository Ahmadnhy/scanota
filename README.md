# 📸 Scanota

**Scanota** is a premium, AI-powered financial management application built with Flutter. It revolutionizes how you track expenses by using Google's Gemini AI to automatically scan and extract data from receipt images, saving you time and reducing manual entry errors.

🔗 **Live Demo**: [scanota.vercel.app](https://scanota.vercel.app/)

---

## 🌟 Key Features

-   **🤖 Smart AI Scanning**: Take a photo of your receipt and let Gemini AI automatically detect the merchant name, transaction date, total amount, and category.
-   **📝 Manual Entry**: Easily input transactions manually when you don't have a physical receipt.
-   **📅 Smart Grouping**: Transactions are automatically grouped into *Today*, *Yesterday*, *This Week*, *This Month*, and *Older* for easy navigation.
-   **📊 Insightful Analytics**: Visualize your spending habits with dynamic pie charts and bar charts on the report page.
-   **☁️ Real-time Cloud Sync**: Your data is securely stored and synchronized across devices using Supabase.
-   **🎨 Premium UI/UX**: A clean, minimalist, and responsive design with smooth micro-animations and a curated color palette.
-   **🔐 Secure Authentication**: Robust user login and registration powered by Supabase Auth.

---

## 🛠️ Tech Stack

-   **Frontend**: [Flutter](https://flutter.dev) (Dart)
-   **State Management**: [Riverpod](https://riverpod.dev)
-   **Backend (BaaS)**: [Supabase](https://supabase.com) (Auth, PostgreSQL, Storage)
-   **AI Engine**: [Google Gemini AI](https://deepmind.google/technologies/gemini/) (via Google Generative AI SDK)
-   **Navigation**: [GoRouter](https://pub.dev/packages/go_router)
-   **Charts**: [FL Chart](https://pub.dev/packages/fl_chart)
-   **Icons**: Lucide Icons & Material Symbols

---

## 📂 Project Structure

The project follows a **Feature-First Architecture** to ensure maintainability and scalability:

```text
lib/
├── core/                # Core configurations, constants, and utilities
│   ├── constants/       # App colors, themes, etc.
│   ├── utils/           # Global helpers (Notifications, Formatter)
│   └── widgets/         # Shared UI components
├── features/            # Feature-based modules
│   ├── auth/            # Login, Register, & Welcome logic
│   ├── dashboard/       # Main screen, History, & Reports
│   ├── scanner/         # AI Receipt Scanning & Validation logic
│   └── transactions/    # CRUD operations & Data models
└── main.dart            # Entry point & ProviderScope setup
```

---

## 🚀 Getting Started

### Prerequisites

-   Flutter SDK (v3.0.0 or higher)
-   A Supabase Project (URL and Anon Key)
-   A Google Gemini API Key

### Installation

1.  **Clone the repository**:
    ```bash
    git clone https://github.com/yourusername/Scanota.git
    ```
2.  **Install dependencies**:
    ```bash
    flutter pub get
    ```
3.  **Setup Environment Variables**:
    Create a `.env` file in the root directory and add your credentials:
    ```env
    SUPABASE_URL=your_supabase_url
    SUPABASE_ANON_KEY=your_supabase_anon_key
    GEMINI_API_KEY=your_gemini_api_key
    ```
4.  **Run the app**:
    ```bash
    flutter run
    ```

---

## 📜 Database Schema

The app uses a `transactions` table in Supabase with the following fields:
- `id`: UUID (Primary Key)
- `user_id`: UUID (Foreign Key to Auth)
- `merchant_name`: Text
- `transaction_date`: Date
- `total_amount`: Numeric
- `category`: Text
- `receipt_image_url`: Text (Nullable)
- `created_at`: Timestamp (Default: now())

---

## 🤝 Contributing

Contributions are welcome! If you have suggestions for improvements or new features, feel free to open an issue or submit a pull request.

---

## 📄 License

This project is licensed under the MIT License.

---

Developed by Ahmad nh👾 | [ahmadnh.is-a.dev](https://ahmadnh.is-a.dev)
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

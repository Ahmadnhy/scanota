import 'dart:convert';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class GeminiRepository {
  // Panggil client Supabase yang sudah diinisialisasi di main.dart
  final _supabase = Supabase.instance.client;

  Future<String> analyzeReceipt(Uint8List imageBytes) async {
    try {
      // 1. Ubah gambar fisik menjadi teks Base64
      final String base64Image = base64Encode(imageBytes);

      // 2. Tembak fungsi 'analyze-receipt' di server Supabase
      final response = await _supabase.functions.invoke(
        'analyze-receipt',
        body: {'imageBase64': base64Image},
      );

      // 3. Tangkap respons JSON dari server
      if (response.status == 200) {
        // Karena respons server bisa berupa String atau objek Map, kita pastikan formatnya:
        if (response.data is String) {
          return response.data;
        } else {
          return jsonEncode(response.data);
        }
      } else {
        throw Exception("Server menolak permintaan: ${response.status}");
      }
    } on FunctionException catch (e) {
      throw Exception(
        "Error pada fungsi server: ${e.details ?? e.reasonPhrase}",
      );
    } catch (e) {
      throw Exception("Gagal mengekstrak struk: $e");
    }
  }
}

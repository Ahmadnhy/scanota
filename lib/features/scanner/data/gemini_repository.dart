import 'dart:convert';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class GeminiRepository {
  final _supabase = Supabase.instance.client;

  Future<String> analyzeReceipt(Uint8List imageBytes) async {
    try {
      // Encode image to Base64
      final base64Image = base64Encode(imageBytes);

      // Call Supabase Edge Function
      final response = await _supabase.functions.invoke(
        'analyze-receipt',
        body: {'imageBase64': base64Image},
      );

      if (response.data == null) {
        throw Exception("Gagal mengekstrak data dari struk (Edge Function returned null).");
      }

      // Pastikan output adalah string (jika function mengembalikan JSON object, convert ke string)
      if (response.data is Map || response.data is List) {
        return jsonEncode(response.data);
      }
      
      return response.data.toString();
    } catch (e) {
      throw Exception("Gagal memproses struk via Edge Function: $e");
    }
  }
}

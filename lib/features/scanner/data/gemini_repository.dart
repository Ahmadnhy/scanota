import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../core/constants/env_config.dart';

class GeminiRepository {
  late final GenerativeModel _model;

  GeminiRepository() {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: EnvConfig.geminiApiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
      ),
    );
  }

  Future<String> analyzeReceipt(Uint8List imageBytes) async {
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

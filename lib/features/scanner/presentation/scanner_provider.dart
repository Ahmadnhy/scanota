import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../data/gemini_repository.dart';
import '../domain/receipt_data.dart';

final geminiRepoProvider = Provider((ref) => GeminiRepository());

final scannedReceiptProvider = StateProvider<ReceiptData?>((ref) => null);

final scannerControllerProvider = StateNotifierProvider<ScannerController, AsyncValue<void>>((ref) {
  return ScannerController(ref);
});

class ScannerController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  final ImagePicker _picker = ImagePicker();

  ScannerController(this._ref) : super(const AsyncValue.data(null));

  Future<void> processReceipt(ImageSource source) async {
    try {
      state = const AsyncValue.loading();

      final XFile? image = await _picker.pickImage(source: source);
      if (image == null) {
        state = const AsyncValue.data(null);
        return;
      }

      final bytes = await image.readAsBytes();

      final geminiRepo = _ref.read(geminiRepoProvider);
      final jsonString = await geminiRepo.analyzeReceipt(bytes);
      final cleanedStr = jsonString.replaceAll(RegExp(r'```(?:json)?\n?'), '').replaceAll('```', '').trim();

      final Map<String, dynamic> jsonData = jsonDecode(cleanedStr);
      final receiptData = ReceiptData.fromJson(jsonData, image.path, imageBytes: bytes);

      _ref.read(scannedReceiptProvider.notifier).state = receiptData;

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> processReceiptFromFile() async {
    try {
      state = const AsyncValue.loading();

      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        state = const AsyncValue.data(null);
        return;
      }

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        throw Exception("Failed to read file bytes");
      }

      final geminiRepo = _ref.read(geminiRepoProvider);
      final jsonString = await geminiRepo.analyzeReceipt(bytes);
      final cleanedStr = jsonString.replaceAll(RegExp(r'```(?:json)?\n?'), '').replaceAll('```', '').trim();

      final Map<String, dynamic> jsonData = jsonDecode(cleanedStr);
      final receiptData = ReceiptData.fromJson(jsonData, file.path ?? 'file_${DateTime.now().millisecondsSinceEpoch}', imageBytes: bytes);

      _ref.read(scannedReceiptProvider.notifier).state = receiptData;

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

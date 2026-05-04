import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/router.dart';
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

      final context = _ref.read(navigatorKeyProvider).currentContext!;
      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Receipt',
            toolbarColor: AppColors.primary,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            activeControlsWidgetColor: AppColors.primary,
          ),
          IOSUiSettings(
            title: 'Crop Receipt',
            aspectRatioLockEnabled: false,
            resetAspectRatioEnabled: true,
          ),
          WebUiSettings(
            context: context,
            presentStyle: WebPresentStyle.dialog,
          ),
        ],
      );

      if (croppedFile == null) {
        state = const AsyncValue.data(null);
        return;
      }

      final bytes = await croppedFile.readAsBytes();

      final geminiRepo = _ref.read(geminiRepoProvider);
      final jsonString = await geminiRepo.analyzeReceipt(bytes);

      final Map<String, dynamic> jsonData = jsonDecode(jsonString);
      final receiptData = ReceiptData.fromJson(jsonData, croppedFile.path, imageBytes: bytes);

      _ref.read(scannedReceiptProvider.notifier).state = receiptData;

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// ignore_for_file: unused_import, unused_field, unused_local_variable, unused_element
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'ai_config_service.dart';

class ReceiptResult {
  final double? amount;
  final String description;
  final String category;
  final String? imagePath;

  ReceiptResult({
    this.amount,
    required this.description,
    this.category = 'Market',
    this.imagePath,
  });
}

class ReceiptScannerService {
  final _picker = ImagePicker();
  final AIConfigService _configService;
  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  ReceiptScannerService([AIConfigService? configService])
    : _configService = configService ?? AIConfigService();

  Future<XFile?> pickImageFromCamera() async {
    try {
      return await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
    } catch (e) {
      return null;
    }
  }

  Future<String> saveImageLocally(XFile image) async {
    final appDir = await getApplicationDocumentsDirectory();
    final receiptDir = Directory(p.join(appDir.path, 'receipts'));
    if (!await receiptDir.exists()) {
      await receiptDir.create(recursive: true);
    }

    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedImage = await File(
      image.path,
    ).copy(p.join(receiptDir.path, fileName));
    return savedImage.path;
  }

  Future<void> clearAllReceiptImages() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final receiptDir = Directory(p.join(appDir.path, 'receipts'));
      if (await receiptDir.exists()) {
        await receiptDir.delete(recursive: true);
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<ReceiptResult> scanReceipt(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizedText = await _textRecognizer.processImage(inputImage);
    final rawText = recognizedText.text;

    // Heuristic analysis
    double? maxAmount;
    String description = '';

    final lines = recognizedText.blocks.expand((block) => block.lines).toList();

    // Find Description (Merchant Name)
    if (lines.isNotEmpty) {
      String firstLine = lines.first.text.trim();
      if (firstLine.length > 40) {
        firstLine = firstLine.substring(0, 40);
      }
      description = firstLine;
    }

    final priceRegex = RegExp(r'\d+[.,]\d{2}');
    double currentMax = 0.0;

    for (var line in lines) {
      final text = line.text;
      final matches = priceRegex.allMatches(text);
      for (var match in matches) {
        String numberStr = match.group(0)!;
        numberStr = numberStr.replaceAll('.', '').replaceAll(',', '.');
        try {
          double val = double.parse(numberStr);
          if (val > currentMax) {
            currentMax = val;
          }
        } catch (e) {
          // Skip non-parsable number strings
        }
      }
    }

    if (currentMax > 0) {
      maxAmount = currentMax;
    }

    return ReceiptResult(
      amount: maxAmount,
      description: description,
      category: 'Market',
      imagePath: imagePath,
    );
  }

  void dispose() {
    _textRecognizer.close();
  }
}

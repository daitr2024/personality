// ignore_for_file: unused_import, unused_field, unused_local_variable, unused_element
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'ai_config_service.dart';

class ReceiptResult {
  final double? amount;
  final String description;
  final String category;
  final String? imagePath;
  final DateTime? receiptDate;

  ReceiptResult({
    this.amount,
    required this.description,
    this.category = 'Market',
    this.imagePath,
    this.receiptDate,
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

  /// AI Vision receipt analysis — extracts amount, description, date, category
  Future<ReceiptResult> scanReceipt(String imagePath) async {
    // Try AI Vision first, fall back to OCR heuristics
    try {
      final result = await _scanWithAIVision(imagePath);
      if (result != null) return result;
    } catch (e) {
      debugPrint('AI Vision receipt scan failed: $e');
    }

    // Fallback: basic OCR
    return _scanWithOCR(imagePath);
  }

  /// Use Gemini Vision API to analyze the receipt
  Future<ReceiptResult?> _scanWithAIVision(String imagePath) async {
    final visionKey = (await _configService.getVisionApiKey())?.trim();
    final generalKey = (await _configService.getApiKey())?.trim();
    final effectiveKey = (visionKey != null && visionKey.isNotEmpty)
        ? visionKey
        : generalKey;

    if (effectiveKey == null || effectiveKey.isEmpty) return null;

    final model = await _configService.getVisionModel();

    // Read and resize image
    final file = File(imagePath);
    final originalBytes = await file.readAsBytes();
    Uint8List imgBytes = originalBytes;

    try {
      final image = img.decodeImage(originalBytes);
      if (image != null && (image.width > 2000 || image.height > 2000)) {
        final resized = img.copyResize(image, width: 1600);
        imgBytes = Uint8List.fromList(img.encodeJpg(resized, quality: 85));
      }
    } catch (_) {}

    final base64Image = base64Encode(imgBytes);

    final now = DateTime.now();
    final currentDate =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    const prompt = '''
You are an expert receipt analyzer. Analyze the receipt/invoice image and extract:
1. Total amount (the FINAL total, including tax)
2. Store/merchant name
3. Receipt date (the date printed on the receipt)
4. Category (one of: Market, Yeme-İçme, Fatura, Kira, Ulaşım, Sağlık, Giyim, Teknoloji / Abonelik, Eğlence, Eğitim, Seyahat, Diğer)

Return ONLY JSON in this exact format:
{
  "amount": 123.45,
  "description": "Store Name",
  "category": "Market",
  "date": "YYYY-MM-DD"
}

Rules:
- amount must be a number (not string), the TOTAL/TOPLAM amount
- description should be the store/merchant name (max 40 chars)
- category must be one of the listed categories above
- date should be in YYYY-MM-DD format, extracted from the receipt
- If you can't determine a field, use null for amount, empty string for description, "Diğer" for category, null for date
''';

    final requestBody = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt},
            {
              'inline_data': {'mime_type': 'image/jpeg', 'data': base64Image},
            },
          ],
        },
      ],
      'generationConfig': {'temperature': 0.1},
    });

    final baseUrl = 'https://generativelanguage.googleapis.com/v1beta';
    var url = '$baseUrl/models/$model:generateContent?key=$effectiveKey';

    var response = await http
        .post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: requestBody,
        )
        .timeout(const Duration(seconds: 60));

    // Fallback models
    if (response.statusCode == 404) {
      final fallbackModels = [
        'gemini-2.0-flash',
        'gemini-2.5-flash',
        'gemini-2.0-flash-lite',
      ];
      for (final fallback in fallbackModels) {
        if (fallback == model) continue;
        url = '$baseUrl/models/$fallback:generateContent?key=$effectiveKey';
        response = await http
            .post(
              Uri.parse(url),
              headers: {'Content-Type': 'application/json'},
              body: requestBody,
            )
            .timeout(const Duration(seconds: 60));
        if (response.statusCode != 404) break;
      }
    }

    if (response.statusCode == 200) {
      final rawBody = utf8.decode(response.bodyBytes);
      final outerJson = jsonDecode(rawBody);

      String content = '';
      try {
        content =
            outerJson['candidates'][0]['content']['parts'][0]['text']
                ?.toString() ??
            '';
      } catch (e) {
        debugPrint('Gemini receipt parse error: $e');
        return null;
      }

      // Extract JSON from response
      final data = _extractJson(content);
      if (data == null) return null;

      // Parse results
      double? amount;
      if (data['amount'] != null) {
        amount = (data['amount'] is num)
            ? (data['amount'] as num).toDouble()
            : double.tryParse(data['amount'].toString());
      }

      DateTime? receiptDate;
      if (data['date'] != null && data['date'].toString().isNotEmpty) {
        try {
          receiptDate = DateTime.parse(data['date'].toString());
        } catch (_) {}
      }

      return ReceiptResult(
        amount: amount,
        description: data['description']?.toString() ?? '',
        category: data['category']?.toString() ?? 'Diğer',
        imagePath: imagePath,
        receiptDate: receiptDate,
      );
    }

    return null;
  }

  /// Fallback: basic OCR-based receipt scanning
  Future<ReceiptResult> _scanWithOCR(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizedText = await _textRecognizer.processImage(inputImage);

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

    // Try to find date in OCR text
    DateTime? ocrDate;
    final dateRegex = RegExp(r'(\d{2})[./](\d{2})[./](\d{4})');
    for (var line in lines) {
      final match = dateRegex.firstMatch(line.text);
      if (match != null) {
        try {
          ocrDate = DateTime(
            int.parse(match.group(3)!),
            int.parse(match.group(2)!),
            int.parse(match.group(1)!),
          );
          break;
        } catch (_) {}
      }
    }

    return ReceiptResult(
      amount: maxAmount,
      description: description,
      category: 'Market',
      imagePath: imagePath,
      receiptDate: ocrDate,
    );
  }

  Map<String, dynamic>? _extractJson(String content) {
    try {
      final codeBlockRegex = RegExp(r'```(?:json)?\s*(\{[\s\S]*?\})\s*```');
      final match = codeBlockRegex.firstMatch(content);
      if (match != null) {
        return jsonDecode(match.group(1)!);
      }

      final start = content.indexOf('{');
      final end = content.lastIndexOf('}');
      if (start != -1 && end != -1) {
        return jsonDecode(content.substring(start, end + 1));
      }
    } catch (e) {
      debugPrint('Receipt JSON extraction error: $e');
    }
    return null;
  }

  void dispose() {
    _textRecognizer.close();
  }
}

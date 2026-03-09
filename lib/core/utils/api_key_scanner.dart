// ignore_for_file: use_build_context_synchronously
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

/// Utility class for scanning API keys from images using OCR.
/// Used by both AI Settings page and AI Setup Wizard.
class ApiKeyScanner {
  ApiKeyScanner._();

  /// Regex pattern for Google API keys
  static final _keyPattern = RegExp(r'AIza[A-Za-z0-9_\-]{25,45}');

  /// Common OCR misreads and their corrections
  static final _ocrCorrections = {
    'AlzA': 'AIzA', // lowercase L → uppercase I
    'Alza': 'AIza',
    'A1za': 'AIza', // digit 1 → uppercase I
    'A|za': 'AIza', // pipe → I
    'AIZa': 'AIza', // uppercase Z → lowercase z
    'Aiza': 'AIza', // lowercase i → uppercase I
  };

  /// Validates that a string looks like a Google API key.
  static bool isValidFormat(String key) {
    final trimmed = key.trim();
    return trimmed.startsWith('AIza') &&
        trimmed.length >= 30 &&
        trimmed.length <= 50;
  }

  /// Fix common OCR character misreadings in a text string.
  @visibleForTesting
  static String fixOcrErrors(String text) {
    var fixed = text;
    // Fix common prefix misreads
    for (final entry in _ocrCorrections.entries) {
      if (fixed.contains(entry.key)) {
        fixed = fixed.replaceAll(entry.key, entry.value);
      }
    }
    // Remove zero-width and invisible unicode characters
    fixed = fixed.replaceAll(RegExp(r'[\u200B-\u200D\uFEFF\u00AD]'), '');
    return fixed;
  }

  /// Extract API key from recognized text using multiple strategies.
  @visibleForTesting
  static String? extractKey(String fullText) {
    // Strategy 1: Direct regex match on full text
    final match = _keyPattern.firstMatch(fullText);
    if (match != null) {
      final key = match.group(0)!;
      if (key.length >= 30) return key;
    }

    // Strategy 2: Try with OCR error corrections
    final corrected = fixOcrErrors(fullText);
    final correctedMatch = _keyPattern.firstMatch(corrected);
    if (correctedMatch != null) {
      final key = correctedMatch.group(0)!;
      if (key.length >= 30) return key;
    }

    // Strategy 3: Remove all whitespace/newlines and search again
    final noSpaces = fullText.replaceAll(RegExp(r'\s+'), '');
    final noSpaceMatch = _keyPattern.firstMatch(noSpaces);
    if (noSpaceMatch != null) {
      final key = noSpaceMatch.group(0)!;
      if (key.length >= 30) return key;
    }

    // Strategy 4: Corrected + no spaces combined
    final correctedNoSpaces = fixOcrErrors(noSpaces);
    final combinedMatch = _keyPattern.firstMatch(correctedNoSpaces);
    if (combinedMatch != null) {
      final key = combinedMatch.group(0)!;
      if (key.length >= 30) return key;
    }

    // Strategy 5: Find "AIza" or similar prefix and grab 39 chars after it
    final prefixPatterns = ['AIza', 'Alza', 'A1za', 'Aiza'];
    for (final prefix in prefixPatterns) {
      final idx = correctedNoSpaces.indexOf(prefix);
      if (idx == -1) continue;
      // Google API keys are exactly 39 characters
      final endIdx = idx + 39;
      if (endIdx <= correctedNoSpaces.length) {
        var candidate = correctedNoSpaces.substring(idx, endIdx);
        // Ensure it starts with AIza after correction
        if (!candidate.startsWith('AIza')) {
          candidate = 'AIza${candidate.substring(4)}';
        }
        // Clean: only allow alphanumeric, dash, underscore
        candidate = candidate.replaceAll(RegExp(r'[^A-Za-z0-9_\-]'), '');
        if (candidate.length >= 30 && candidate.startsWith('AIza')) {
          return candidate;
        }
      }
    }

    return null;
  }

  /// Scans an image for a Google API key using ML Kit OCR.
  ///
  /// [useCamera] - true for camera, false for gallery
  /// Returns the found key or null if not found.
  /// Throws on errors (caller should handle).
  static Future<String?> scanFromImage({required bool useCamera}) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: useCamera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 3000, // Higher resolution for better OCR
      maxHeight: 3000,
      imageQuality: 95, // Higher quality
    );
    if (pickedFile == null) return null;

    final inputImage = InputImage.fromFilePath(pickedFile.path);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final recognizedText = await textRecognizer.processImage(inputImage);

      // Collect all text from all blocks and lines
      final allLines = <String>[];
      final allText = StringBuffer();

      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          final lineText = line.text.trim();
          if (lineText.isNotEmpty) {
            allLines.add(lineText);
            allText.write(lineText);
          }
        }
      }

      debugPrint(
        'OCR recognized ${allLines.length} lines, total ${allText.length} chars',
      );
      debugPrint('OCR full text: $allText');

      // Attempt 1: Search each individual line
      for (final line in allLines) {
        final key = extractKey(line);
        if (key != null) {
          debugPrint('OCR found key in single line: ${key.substring(0, 8)}...');
          return key;
        }
      }

      // Attempt 2: Search adjacent line pairs (key might be split across 2 lines)
      for (int i = 0; i < allLines.length - 1; i++) {
        final combined = '${allLines[i]}${allLines[i + 1]}';
        final key = extractKey(combined);
        if (key != null) {
          debugPrint(
            'OCR found key in combined lines [$i, ${i + 1}]: ${key.substring(0, 8)}...',
          );
          return key;
        }
      }

      // Attempt 3: Search the entire text as one blob
      final key = extractKey(allText.toString());
      if (key != null) {
        debugPrint(
          'OCR found key in full text blob: ${key.substring(0, 8)}...',
        );
        return key;
      }

      debugPrint('OCR: No API key found in recognized text');
      return null;
    } finally {
      textRecognizer.close();
      // Clean up temp file
      try {
        final file = File(pickedFile.path);
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
  }

  /// Shows a scanning flow with loading indicator and result feedback.
  /// Returns the found key or null.
  static Future<String?> scanWithFeedback({
    required BuildContext context,
    required bool useCamera,
  }) async {
    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Text('Görsel taranıyor...'),
          ],
        ),
        duration: Duration(seconds: 10),
      ),
    );

    try {
      final foundKey = await scanFromImage(useCamera: useCamera);

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (foundKey != null) {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'API anahtarı bulundu! ✓ (${foundKey.substring(0, 8)}...)',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Görselde API anahtarı bulunamadı. '
              '"AIza..." ile başlayan anahtarın net göründüğünden emin olun.',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }

      return foundKey;
    } catch (e) {
      debugPrint('OCR error: $e');
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Görsel tarama hatası: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }
  }
}

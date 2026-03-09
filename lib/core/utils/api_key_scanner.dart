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
  static final _keyPattern = RegExp(r'AIza[A-Za-z0-9_-]{25,45}');

  /// Validates that a string looks like a Google API key.
  static bool isValidFormat(String key) {
    final trimmed = key.trim();
    return trimmed.startsWith('AIza') &&
        trimmed.length >= 30 &&
        trimmed.length <= 50;
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
      maxWidth: 2000,
      maxHeight: 2000,
      imageQuality: 90,
    );
    if (pickedFile == null) return null;

    final inputImage = InputImage.fromFilePath(pickedFile.path);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final recognizedText = await textRecognizer.processImage(inputImage);

      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          final lineText = line.text.trim();

          // Direct match: entire line is a key
          if (isValidFormat(lineText)) {
            return lineText.replaceAll(RegExp(r'\s'), '');
          }

          // Regex match: key embedded in longer text
          final keyMatch = _keyPattern.firstMatch(lineText);
          if (keyMatch != null) {
            return keyMatch.group(0);
          }
        }
      }
      return null; // No key found
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

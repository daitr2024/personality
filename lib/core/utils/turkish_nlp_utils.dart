import 'dart:math';
import 'package:flutter/foundation.dart';

class TurkishNLPUtils {
  /// Calculates the Levenshtein distance between two strings.
  /// Used for fuzzy matching.
  static int _levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<int> v0 = List<int>.filled(s2.length + 1, 0);
    List<int> v1 = List<int>.filled(s2.length + 1, 0);

    for (int i = 0; i <= s2.length; i++) {
      v0[i] = i;
    }

    for (int i = 0; i < s1.length; i++) {
      v1[0] = i + 1;

      for (int j = 0; j < s2.length; j++) {
        int cost = (s1[i] == s2[j]) ? 0 : 1;
        v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + cost));
      }

      for (int j = 0; j <= s2.length; j++) {
        v0[j] = v1[j];
      }
    }

    return v1[s2.length];
  }

  /// Returns the similarity score between two strings (0.0 to 1.0).
  static double _similarity(String s1, String s2) {
    int maxLength = max(s1.length, s2.length);
    if (maxLength == 0) return 1.0;
    int distance = _levenshteinDistance(s1, s2);
    return 1.0 - (distance / maxLength);
  }

  /// Analyzes and corrects the input text using fuzzy matching against a dictionary.
  /// Wrapped in a try-catch to ensure it never crashes the app.
  static String applyFuzzyCorrections(String input) {
    try {
      if (input.isEmpty) return input;

      // 0. Character level correction
      String processedInput = _deepCharacterCorrection(input);

      // 1. First run EXACT common OCR/STT artifact replacements
      // Because fuzzy matching might not catch completely mangled words (like qünu -> günü)
      final exactTypoMap = {
        'clkarmı': 'çıkarımı',
        'gikanmı': 'çıkarımı',
        'qünu': 'günü',
        'toplantis': 'toplantısı',
        'dosyasınin': 'dosyasının',
        'güncellerinesi': 'güncellenmesi',
        'yazılim': 'yazılım',
        'kontral': 'kontrol',
        'orevetkinlik': 'görev etkinlik',
        'orev': 'görev',
        'etkirilik': 'etkinlik',
        'hazrlan': 'hazırlan',
        'kayit': 'kayıt',
        'blgi': 'bilgi',
        'metn': 'metin',
        'toplanti': 'toplantı',
      };

      exactTypoMap.forEach((wrong, correct) {
        processedInput = processedInput.replaceAll(
          RegExp('\\b$wrong\\b', caseSensitive: false),
          correct,
        );
      });

      final words = processedInput.split(RegExp(r'\s+'));
      final correctedWords = <String>[];

      // Dictionary of target words we want to correctly identify.
      // We expand this to catch common root words.
      final dictionary = [
        'toplantı',
        'toplantısı',
        'randevu',
        'yarın',
        'bugün',
        'günü',
        'pazartesi',
        'salı',
        'çarşamba',
        'perşembe',
        'cuma',
        'cumartesi',
        'pazar',
        'görev',
        'etkinlik',
        'tamamla',
        'hatırlat',
        'kaydet',
        'ekle',
        'dosya',
        'dosyasının',
        'güncellenmesi',
        'yazılım',
        'kontrol',
        'çıkarımı',
        'hazırlan',
        'bilgi',
        'metin',
        'görüşme',
        'listesi',
        'alışveriş',
      ];

      for (var word in words) {
        // Strip punctuation for matching
        final cleanWord = word
            .replaceAll(RegExp(r'[^\w\sçğıöşüÇĞİÖŞÜ]'), '')
            .toLowerCase();

        if (cleanWord.length > 3) {
          String bestMatch = word;
          double highestSimilarity = 0.0;

          for (var dictWord in dictionary) {
            final sim = _similarity(cleanWord, dictWord);
            if (sim > highestSimilarity) {
              highestSimilarity = sim;
              bestMatch = dictWord;
            }
          }

          // If the similarity is above an 80% threshold but not identical, we replace it.
          // This avoids replacing completely different words.
          if (highestSimilarity >= 0.8 && highestSimilarity < 1.0) {
            debugPrint(
              'TurkishNLPUtils: Corrected typo "$cleanWord" -> "$bestMatch" ($highestSimilarity)',
            );

            // Preserve original capitalization structure if possible (simple approach)
            if (word[0] == word[0].toUpperCase()) {
              bestMatch = bestMatch[0].toUpperCase() + bestMatch.substring(1);
            }
            correctedWords.add(bestMatch);
          } else {
            correctedWords.add(word);
          }
        } else {
          correctedWords.add(word);
        }
      }

      return correctedWords.join(' ');
    } catch (e) {
      // If anything fails during heuristic NLP, log it and return the original input
      // so the app never throws an error directly to the user here.
      debugPrint('TurkishNLPUtils Fuzzy Match Error: $e');
      return input;
    }
  }

  /// Corrects specific single-character OCR artifacts in Turkish context
  static String _deepCharacterCorrection(String input) {
    String text = input;
    // Common OCR mixups for Turkish
    final corrections = {
      'ı1': 'ı',
      'l1': 'ı',
      'l0': 'lo',
      '0r': 'ör',
      'şs': 'ş',
      'ğg': 'ğ',
      'cl': 'çı',
      'gi': 'çü',
    };

    corrections.forEach((wrong, correct) {
      text = text.replaceAll(wrong, correct);
    });

    // Special case for 'l' inside a word where it should be 'ı'
    // e.g. 'yazılım' often comes as 'yazilim' or 'yazılim'
    // But ML Kit usually gets 'i' and 'ı' right if the image is clear.

    return text;
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:personality_ai/core/utils/api_key_scanner.dart';
import 'package:personality_ai/core/utils/recording_defaults.dart';
import 'package:personality_ai/core/exceptions/app_exceptions.dart';

void main() {
  group('ApiKeyScanner', () {
    group('isValidFormat', () {
      test('accepts valid Google API key', () {
        expect(
          ApiKeyScanner.isValidFormat('AIzaSyA1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P'),
          isTrue,
        );
      });

      test('accepts key with exactly 30 chars', () {
        // AIza + 26 chars = 30 total
        expect(
          ApiKeyScanner.isValidFormat('AIzaSyA1B2C3D4E5F6G7H8I9J0K1L2'),
          isTrue,
        );
      });

      test('rejects key shorter than 30 chars', () {
        expect(ApiKeyScanner.isValidFormat('AIzaSyTooShort'), isFalse);
      });

      test('rejects key that does not start with AIza', () {
        expect(
          ApiKeyScanner.isValidFormat('NotAnApiKeyAtAllNotAnApiKeyAtAll'),
          isFalse,
        );
      });

      test('rejects empty string', () {
        expect(ApiKeyScanner.isValidFormat(''), isFalse);
      });

      test('rejects key longer than 50 chars', () {
        final longKey = 'AIza${'A' * 50}';
        expect(ApiKeyScanner.isValidFormat(longKey), isFalse);
      });

      test('handles whitespace-padded key', () {
        expect(
          ApiKeyScanner.isValidFormat(
            '  AIzaSyA1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P  ',
          ),
          isTrue,
        );
      });
    });

    group('extractKey', () {
      test('extracts key from clean text', () {
        final key = ApiKeyScanner.extractKey(
          'Your key: AIzaSyA1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P',
        );
        expect(key, equals('AIzaSyA1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P'));
      });

      test('extracts key with spaces (OCR artifact)', () {
        final key = ApiKeyScanner.extractKey(
          'AIza SyA1B2C3 D4E5F6G7 H8I9J0K1L2M3N4O5P',
        );
        expect(key, isNotNull);
        expect(key!.startsWith('AIza'), isTrue);
        expect(key.length, greaterThanOrEqualTo(30));
      });

      test('extracts key with OCR l→I misread', () {
        // OCR might read 'I' as 'l' (lowercase L)
        final key = ApiKeyScanner.extractKey(
          'AlzaSyA1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P',
        );
        expect(key, isNotNull);
        expect(key!.startsWith('AIza'), isTrue);
      });

      test('extracts key with OCR 1→I misread', () {
        // OCR might read 'I' as '1'
        final key = ApiKeyScanner.extractKey(
          'A1zaSyA1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P',
        );
        expect(key, isNotNull);
        expect(key!.startsWith('AIza'), isTrue);
      });

      test('extracts key split across two lines', () {
        // Key split in middle — combined should work
        final combined =
            'AIzaSyA1B2C3D4E5F6G7'
            'H8I9J0K1L2M3N4O5P';
        final key = ApiKeyScanner.extractKey(combined);
        expect(key, isNotNull);
        expect(key!.length, greaterThanOrEqualTo(30));
      });

      test('returns null for text without key', () {
        final key = ApiKeyScanner.extractKey('Hello world, no key here');
        expect(key, isNull);
      });

      test('extracts key from noisy OCR text', () {
        final key = ApiKeyScanner.extractKey(
          'Google AI Studio\nAPI Key: AIzaSyA1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P\nCopy this key',
        );
        expect(key, isNotNull);
        expect(key!.startsWith('AIza'), isTrue);
      });
    });

    group('fixOcrErrors', () {
      test('corrects Alza to AIza', () {
        expect(ApiKeyScanner.fixOcrErrors('AlzaSyTest'), contains('AIza'));
      });

      test('corrects A1za to AIza', () {
        expect(ApiKeyScanner.fixOcrErrors('A1zaSyTest'), contains('AIza'));
      });

      test('leaves correct AIza unchanged', () {
        expect(ApiKeyScanner.fixOcrErrors('AIzaSyTest'), equals('AIzaSyTest'));
      });
    });
  });

  group('RecordingDefaults', () {
    test('voiceConfig has WAV encoder', () {
      expect(RecordingDefaults.voiceConfig.encoder.name, 'wav');
    });

    test('voiceConfig uses mono channel', () {
      expect(RecordingDefaults.voiceConfig.numChannels, 1);
    });

    test('voiceConfig has noise suppression enabled', () {
      expect(RecordingDefaults.voiceConfig.noiseSuppress, isTrue);
    });

    test('voiceConfig has echo cancel enabled', () {
      expect(RecordingDefaults.voiceConfig.echoCancel, isTrue);
    });

    test('voiceConfig has auto gain enabled', () {
      expect(RecordingDefaults.voiceConfig.autoGain, isTrue);
    });

    test('silence threshold is -50 dB', () {
      expect(RecordingDefaults.silenceThresholdDb, -50.0);
    });

    test('grace period is 3 seconds', () {
      expect(RecordingDefaults.gracePeriod, const Duration(seconds: 3));
    });

    test('silence duration is 3 seconds', () {
      expect(RecordingDefaults.silenceDuration, const Duration(seconds: 3));
    });

    test('amplitude check interval is 200ms', () {
      expect(
        RecordingDefaults.amplitudeCheckInterval,
        const Duration(milliseconds: 200),
      );
    });
  });

  group('AppExceptions', () {
    test('ApiKeyNotSetException has correct message', () {
      expect(ApiKeyNotSetException().toString(), 'API anahtarı ayarlanmamış');
    });

    test('ApiKeyInvalidException includes status code', () {
      expect(const ApiKeyInvalidException(401).toString(), contains('401'));
    });

    test('ApiQuotaExceededException has correct message', () {
      expect(ApiQuotaExceededException().toString(), contains('kota limiti'));
    });

    test('ApiErrorException includes status code', () {
      expect(const ApiErrorException(500).toString(), contains('500'));
    });

    test('ApiErrorException includes optional details', () {
      expect(
        const ApiErrorException(500, 'server error').toString(),
        contains('server error'),
      );
    });

    test('TranscriptionEmptyException has correct message', () {
      expect(
        TranscriptionEmptyException().toString(),
        contains('anlaşılamadı'),
      );
    });

    test('FileNotFoundException includes path', () {
      expect(
        const FileNotFoundException('/path/to/file').toString(),
        contains('/path/to/file'),
      );
    });

    test('NetworkException includes message', () {
      expect(const NetworkException('timeout').toString(), contains('timeout'));
    });
  });
}

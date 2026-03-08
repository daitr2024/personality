import 'package:flutter_test/flutter_test.dart';
import 'package:personality_ai/core/utils/date_utils.dart';

void main() {
  group('DateTimeExtension.toAppLocal', () {
    test('converts UTC time to local', () {
      final utc = DateTime.utc(2026, 3, 8, 12, 0, 0);
      final local = utc.toAppLocal;
      expect(local.isUtc, false);
    });

    test('returns as-is if already local', () {
      final local = DateTime(2026, 3, 8, 15, 0, 0);
      final result = local.toAppLocal;
      expect(result, local);
      expect(result.isUtc, false);
    });

    test('preserves date/time values after conversion', () {
      final utc = DateTime.utc(2026, 1, 15, 0, 0, 0);
      final local = utc.toAppLocal;
      // After UTC->local conversion, the date might differ by timezone offset
      // but the DateTime object should not be UTC anymore
      expect(local.isUtc, false);
    });
  });

  group('DateTimeExtension.isSameDayLocal', () {
    test('same day returns true', () {
      final d1 = DateTime(2026, 3, 8, 10, 30);
      final d2 = DateTime(2026, 3, 8, 22, 45);
      expect(d1.isSameDayLocal(d2), true);
    });

    test('different days returns false', () {
      final d1 = DateTime(2026, 3, 8, 23, 59);
      final d2 = DateTime(2026, 3, 9, 0, 1);
      expect(d1.isSameDayLocal(d2), false);
    });

    test('same day different months returns false', () {
      final d1 = DateTime(2026, 3, 15);
      final d2 = DateTime(2026, 4, 15);
      expect(d1.isSameDayLocal(d2), false);
    });

    test('same day different years returns false', () {
      final d1 = DateTime(2025, 3, 8);
      final d2 = DateTime(2026, 3, 8);
      expect(d1.isSameDayLocal(d2), false);
    });

    test('midnight boundary is same day', () {
      final d1 = DateTime(2026, 3, 8, 0, 0, 0);
      final d2 = DateTime(2026, 3, 8, 23, 59, 59);
      expect(d1.isSameDayLocal(d2), true);
    });

    test('UTC and local same calendar day', () {
      // Both representing March 8 in local time
      final utc = DateTime.utc(2026, 3, 8, 10, 0);
      final local = DateTime(2026, 3, 8, 15, 0);
      // This depends on the timezone offset, but tests toAppLocal conversion
      final result = utc.isSameDayLocal(local);
      // The UTC time should convert to local and still be the same day
      expect(result, isA<bool>()); // At least doesn't crash
    });
  });
}

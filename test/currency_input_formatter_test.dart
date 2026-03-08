import 'package:flutter_test/flutter_test.dart';
import 'package:personality_ai/features/finance/presentation/utils/currency_input_formatter.dart';

void main() {
  group('CurrencyInputFormatter (TR locale)', () {
    late CurrencyInputFormatter formatter;

    setUp(() {
      formatter = CurrencyInputFormatter(locale: 'tr_TR');
    });

    test('empty input returns empty', () {
      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        TextEditingValue.empty,
      );
      expect(result.text, '');
    });

    test('single digit input stays as-is', () {
      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '5'),
      );
      expect(result.text, '5');
    });

    test('formats thousands with dot separator (TR)', () {
      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '1234'),
      );
      expect(result.text, '1.234');
    });

    test('formats large numbers correctly', () {
      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '1234567'),
      );
      expect(result.text, '1.234.567');
    });

    test('allows decimal input with comma (TR)', () {
      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '100,50'),
      );
      expect(result.text, '100,50');
    });

    test('limits decimal places to 2', () {
      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '100,999'),
      );
      expect(result.text, '100,99');
    });

    test('handles zero correctly', () {
      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '0'),
      );
      expect(result.text, '0');
    });

    test('handles trailing decimal separator', () {
      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '0,'),
      );
      expect(result.text, '0,');
    });
  });

  group('CurrencyInputFormatter (EN locale)', () {
    late CurrencyInputFormatter formatter;

    setUp(() {
      formatter = CurrencyInputFormatter(locale: 'en_US');
    });

    test('formats thousands with comma separator (EN)', () {
      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '1234'),
      );
      expect(result.text, '1,234');
    });

    test('allows decimal input with dot (EN)', () {
      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '100.50'),
      );
      expect(result.text, '100.50');
    });
  });

  group('parseCurrencyInput', () {
    test('parses TR formatted input (dot = group, comma = decimal)', () {
      final result = parseCurrencyInput('1.234,56', 'tr_TR');
      expect(result, closeTo(1234.56, 0.001));
    });

    test('parses EN formatted input (comma = group, dot = decimal)', () {
      final result = parseCurrencyInput('1,234.56', 'en_US');
      expect(result, closeTo(1234.56, 0.001));
    });

    test('parses simple integer', () {
      final result = parseCurrencyInput('500', 'tr_TR');
      expect(result, 500.0);
    });

    test('returns null for empty string', () {
      final result = parseCurrencyInput('', 'tr_TR');
      expect(result, isNull);
    });

    test('parses large number correctly', () {
      final result = parseCurrencyInput('1.000.000,99', 'tr_TR');
      expect(result, closeTo(1000000.99, 0.001));
    });

    test('parses without group separator', () {
      final result = parseCurrencyInput('499,99', 'tr_TR');
      expect(result, closeTo(499.99, 0.001));
    });
  });
}

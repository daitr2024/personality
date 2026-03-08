import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Formats numeric input with thousands separators and 2 decimal places.
/// Example: 1234.5 → 1,234.50  or  1.234,50 depending on locale.
class CurrencyInputFormatter extends TextInputFormatter {
  final String locale;

  CurrencyInputFormatter({this.locale = 'tr_TR'});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Allow empty
    if (newValue.text.isEmpty) return newValue;

    // Determine locale-specific separators
    final format = NumberFormat.decimalPattern(locale);
    final decimalSep = format.symbols.DECIMAL_SEP; // ',' for TR, '.' for EN
    final groupSep = format.symbols.GROUP_SEP; // '.' for TR, ',' for EN

    // Strip group separators to get raw digits
    String raw = newValue.text.replaceAll(groupSep, '');

    // Allow only digits and decimal separator
    final allowedChars = RegExp('[0-9${RegExp.escape(decimalSep)}]');
    raw = raw.split('').where((c) => allowedChars.hasMatch(c)).join();

    // Ensure only one decimal separator
    final parts = raw.split(decimalSep);
    if (parts.length > 2) {
      raw = '${parts[0]}$decimalSep${parts.sublist(1).join()}';
    }

    // Limit decimal places to 2
    if (parts.length == 2 && parts[1].length > 2) {
      raw = '${parts[0]}$decimalSep${parts[1].substring(0, 2)}';
    }

    // Parse to number for formatting
    final normalizedRaw = raw.replaceAll(decimalSep, '.');
    final number = double.tryParse(normalizedRaw);
    if (number == null) return newValue;

    // Check if user is still typing decimals (trailing decimal sep or incomplete decimals)
    final hasDecimal = raw.contains(decimalSep);
    final decimalPart = hasDecimal ? raw.split(decimalSep).last : '';

    // Format integer part with grouping
    final intPart = number.truncate();
    final formattedInt = NumberFormat('#,###', locale).format(intPart);

    String formatted;
    if (!hasDecimal) {
      formatted = intPart == 0 && raw == '0' ? '0' : formattedInt;
    } else {
      formatted = '$formattedInt$decimalSep$decimalPart';
    }

    // Handle case where raw is just "0" or starts with 0
    if (raw == '0$decimalSep') {
      formatted = '0$decimalSep';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Parses a formatted currency string back to a double.
/// Handles both TR (1.234,56) and EN (1,234.56) formats.
double? parseCurrencyInput(String text, String locale) {
  if (text.isEmpty) return null;
  final format = NumberFormat.decimalPattern(locale);
  final groupSep = format.symbols.GROUP_SEP;
  final decimalSep = format.symbols.DECIMAL_SEP;

  String normalized = text.replaceAll(groupSep, '');
  normalized = normalized.replaceAll(decimalSep, '.');
  return double.tryParse(normalized);
}

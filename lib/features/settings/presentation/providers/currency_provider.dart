import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'locale_provider.dart';

/// Currency state provider — auto-syncs with app language unless user manually chose
class CurrencyNotifier extends Notifier<String> {
  static const String _currencyKey = 'app_currency';
  static const String _currencySymbolKey = 'app_currency_symbol';
  static const String _manualCurrencyKey = 'app_currency_manual';

  @override
  String build() {
    // Listen to locale changes
    final locale = ref.watch(localeProvider);
    _initCurrency(locale.languageCode);
    return _defaultForLanguage(locale.languageCode);
  }

  Future<void> _initCurrency(String langCode) async {
    final prefs = await SharedPreferences.getInstance();
    final isManual = prefs.getBool(_manualCurrencyKey) ?? false;

    if (isManual) {
      // User manually selected a currency — use that
      final saved = prefs.getString(_currencyKey);
      if (saved != null && saved != state) {
        state = saved;
      }
    } else {
      // Auto-sync with language
      final suggested = _defaultForLanguage(langCode);
      if (suggested != state) {
        state = suggested;
        await prefs.setString(_currencyKey, suggested);
        await prefs.setString(_currencySymbolKey, getSymbol(suggested));
      }
    }
  }

  /// User explicitly picks a currency — mark as manual
  Future<void> setCurrency(String currencyCode) async {
    state = currencyCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, currencyCode);
    await prefs.setString(_currencySymbolKey, getSymbol(currencyCode));
    await prefs.setBool(_manualCurrencyKey, true);
  }

  /// Reset to auto (language-based) currency
  Future<void> resetToAuto() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_manualCurrencyKey, false);
    final locale = ref.read(localeProvider);
    final suggested = _defaultForLanguage(locale.languageCode);
    state = suggested;
    await prefs.setString(_currencyKey, suggested);
    await prefs.setString(_currencySymbolKey, getSymbol(suggested));
  }

  /// Default currency for a given language code
  static String _defaultForLanguage(String langCode) {
    return suggestedCurrencyByLanguage[langCode] ?? 'USD';
  }

  /// Get the symbol for a given currency code
  static String getSymbol(String code) {
    switch (code) {
      case 'TRY':
        return '₺';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'AED':
        return 'د.إ';
      case 'SAR':
        return '﷼';
      case 'JPY':
        return '¥';
      case 'KRW':
        return '₩';
      case 'INR':
        return '₹';
      case 'RUB':
        return '₽';
      case 'BRL':
        return 'R\$';
      case 'CNY':
        return '¥';
      default:
        return code;
    }
  }

  String get symbol => getSymbol(state);
}

final currencyProvider = NotifierProvider<CurrencyNotifier, String>(() {
  return CurrencyNotifier();
});

/// Convenience provider for the currency symbol
final currencySymbolProvider = Provider<String>((ref) {
  final code = ref.watch(currencyProvider);
  return CurrencyNotifier.getSymbol(code);
});

/// Map of suggested currencies per language
const Map<String, String> suggestedCurrencyByLanguage = {
  'tr': 'TRY',
  'en': 'USD',
  'ar': 'AED',
  'de': 'EUR',
  'fr': 'EUR',
  'es': 'EUR',
  'ja': 'JPY',
  'ko': 'KRW',
  'pt': 'BRL',
  'ru': 'RUB',
  'zh': 'CNY',
  'hi': 'INR',
};

/// All available currencies
const List<Map<String, String>> availableCurrencies = [
  {'code': 'TRY', 'name': 'Türk Lirası', 'symbol': '₺', 'flag': '🇹🇷'},
  {'code': 'USD', 'name': 'US Dollar', 'symbol': '\$', 'flag': '🇺🇸'},
  {'code': 'EUR', 'name': 'Euro', 'symbol': '€', 'flag': '🇪🇺'},
  {'code': 'GBP', 'name': 'British Pound', 'symbol': '£', 'flag': '🇬🇧'},
  {'code': 'AED', 'name': 'UAE Dirham', 'symbol': 'د.إ', 'flag': '🇦🇪'},
  {'code': 'SAR', 'name': 'Saudi Riyal', 'symbol': '﷼', 'flag': '🇸🇦'},
  {'code': 'JPY', 'name': 'Japanese Yen', 'symbol': '¥', 'flag': '🇯🇵'},
  {'code': 'KRW', 'name': 'Korean Won', 'symbol': '₩', 'flag': '🇰🇷'},
  {'code': 'INR', 'name': 'Indian Rupee', 'symbol': '₹', 'flag': '🇮🇳'},
  {'code': 'RUB', 'name': 'Russian Ruble', 'symbol': '₽', 'flag': '🇷🇺'},
  {'code': 'BRL', 'name': 'Brazilian Real', 'symbol': 'R\$', 'flag': '🇧🇷'},
  {'code': 'CNY', 'name': 'Chinese Yuan', 'symbol': '¥', 'flag': '🇨🇳'},
];

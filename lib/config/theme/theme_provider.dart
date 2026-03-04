import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

/// Available color schemes
enum AppColorScheme { blue, green, purple, orange, red }

/// Theme state containing mode and color scheme
class ThemeState {
  final ThemeMode themeMode;
  final AppColorScheme colorScheme;

  const ThemeState({required this.themeMode, required this.colorScheme});

  ThemeState copyWith({ThemeMode? themeMode, AppColorScheme? colorScheme}) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      colorScheme: colorScheme ?? this.colorScheme,
    );
  }
}

/// Theme provider managing theme mode and color scheme
class ThemeNotifier extends Notifier<ThemeState> {
  static const String _themeModeKey = 'theme_mode';
  static const String _colorSchemeKey = 'color_scheme';

  @override
  ThemeState build() {
    _loadTheme();
    return const ThemeState(
      themeMode: ThemeMode.system,
      colorScheme: AppColorScheme.blue,
    );
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();

    // Load theme mode
    final themeModeIndex = prefs.getInt(_themeModeKey);
    final themeMode = themeModeIndex != null
        ? ThemeMode.values[themeModeIndex]
        : ThemeMode.system;

    // Load color scheme
    final colorSchemeIndex = prefs.getInt(_colorSchemeKey);
    final colorScheme = colorSchemeIndex != null
        ? AppColorScheme.values[colorSchemeIndex]
        : AppColorScheme.blue;

    state = ThemeState(themeMode: themeMode, colorScheme: colorScheme);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, mode.index);
    state = state.copyWith(themeMode: mode);
  }

  Future<void> setColorScheme(AppColorScheme scheme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_colorSchemeKey, scheme.index);
    state = state.copyWith(colorScheme: scheme);
  }

  /// Get color seed for the selected color scheme
  Color getColorSeed() {
    switch (state.colorScheme) {
      case AppColorScheme.blue:
        return AppTheme.seedColors['blue']!;
      case AppColorScheme.green:
        return AppTheme.seedColors['green']!;
      case AppColorScheme.purple:
        return AppTheme.seedColors['purple']!;
      case AppColorScheme.orange:
        return AppTheme.seedColors['orange']!;
      case AppColorScheme.red:
        return AppTheme.seedColors['red']!;
    }
  }

  /// Get light theme using AppTheme system
  ThemeData getLightTheme() {
    return AppTheme.lightTheme(getColorSeed());
  }

  /// Get dark theme using AppTheme system
  ThemeData getDarkTheme() {
    return AppTheme.darkTheme(getColorSeed());
  }
}

/// Provider for theme notifier
final themeProvider = NotifierProvider<ThemeNotifier, ThemeState>(() {
  return ThemeNotifier();
});

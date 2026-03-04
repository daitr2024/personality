import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../config/theme/app_theme.dart';
import '../../../../config/theme/theme_provider.dart';
import '../../../../features/settings/presentation/providers/locale_provider.dart';
import '../../../../features/settings/presentation/providers/currency_provider.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Provider to check if onboarding has been completed
final onboardingCompletedProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('onboarding_completed') ?? false;
});

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _pageController = PageController();
  int _currentPage = 0;

  // Step selections
  String _selectedLanguage = 'tr';
  ThemeMode _selectedThemeMode = ThemeMode.system;
  AppColorScheme _selectedColorScheme = AppColorScheme.blue;
  String _selectedCurrency = 'TRY';

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    // Apply settings
    ref.read(localeProvider.notifier).setLocale(Locale(_selectedLanguage));
    ref.read(themeProvider.notifier).setThemeMode(_selectedThemeMode);
    ref.read(themeProvider.notifier).setColorScheme(_selectedColorScheme);
    ref.read(currencyProvider.notifier).setCurrency(_selectedCurrency);

    // Mark onboarding complete
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);

    // Navigate to home
    if (mounted) {
      ref.invalidate(onboardingCompletedProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: List.generate(3, (i) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                      decoration: BoxDecoration(
                        color: i <= _currentPage
                            ? cs.primary
                            : cs.outlineVariant.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildLanguagePage(cs),
                  _buildThemePage(cs),
                  _buildCurrencyPage(cs),
                ],
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  if (_currentPage > 0) ...[
                    TextButton.icon(
                      onPressed: _previousPage,
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: Text(AppLocalizations.of(context)!.back),
                    ),
                    const Spacer(),
                  ] else
                    const Spacer(),
                  ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _currentPage == 2 ? 'Başla' : 'Devam',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Gap(8),
                        Icon(
                          _currentPage == 2
                              ? Icons.check_rounded
                              : Icons.arrow_forward_rounded,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Step 1: Language ─────────────────────────────────────────

  Widget _buildLanguagePage(ColorScheme cs) {
    final languages = [
      {'code': 'tr', 'name': 'Türkçe', 'native': 'Türkçe', 'flag': '🇹🇷'},
      {'code': 'en', 'name': 'English', 'native': 'English', 'flag': '🇬🇧'},
      {'code': 'ar', 'name': 'العربية', 'native': 'Arabic', 'flag': '🇸🇦'},
    ];

    return _buildPageLayout(
      icon: Icons.language_rounded,
      iconColor: AppTheme.eventColor,
      title: 'Dil Seçimi',
      subtitle: 'Uygulamayı hangi dilde kullanmak istersiniz?',
      child: Column(
        children: languages.map((lang) {
          final isSelected = _selectedLanguage == lang['code'];
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedLanguage = lang['code']!;
                // Auto-suggest currency based on language
                _selectedCurrency =
                    suggestedCurrencyByLanguage[lang['code']] ?? 'USD';
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: isSelected
                    ? cs.primary.withValues(alpha: 0.08)
                    : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected
                      ? cs.primary.withValues(alpha: 0.4)
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Text(lang['flag']!, style: const TextStyle(fontSize: 28)),
                  const Gap(16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lang['name']!,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                        if (lang['name'] != lang['native']) ...[
                          const Gap(2),
                          Text(
                            lang['native']!,
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle_rounded,
                      color: cs.primary,
                      size: 24,
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Step 2: Theme ────────────────────────────────────────────

  Widget _buildThemePage(ColorScheme cs) {
    final modes = [
      (ThemeMode.light, 'Açık', Icons.light_mode_rounded, '☀️'),
      (ThemeMode.dark, 'Koyu', Icons.dark_mode_rounded, '🌙'),
      (ThemeMode.system, 'Sistem', Icons.smartphone_rounded, '📱'),
    ];

    final colors = [
      (AppColorScheme.blue, 'Mavi', AppTheme.seedColors['blue']!),
      (AppColorScheme.green, 'Yeşil', AppTheme.seedColors['green']!),
      (AppColorScheme.purple, 'Mor', AppTheme.seedColors['purple']!),
      (AppColorScheme.orange, 'Turuncu', AppTheme.seedColors['orange']!),
      (AppColorScheme.red, 'Kırmızı', AppTheme.seedColors['red']!),
    ];

    return _buildPageLayout(
      icon: Icons.palette_rounded,
      iconColor: AppTheme.noteColor,
      title: 'Tema Tercihi',
      subtitle: 'Uygulama görünümünü kişiselleştirin',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Theme mode
          Text(
            'Tema Modu',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: cs.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const Gap(10),
          Row(
            children: modes.map((mode) {
              final isSelected = _selectedThemeMode == mode.$1;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedThemeMode = mode.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.only(
                      right: mode.$1 != ThemeMode.system ? 8 : 0,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? cs.primary.withValues(alpha: 0.1)
                          : cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? cs.primary.withValues(alpha: 0.4)
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(mode.$4, style: const TextStyle(fontSize: 24)),
                        const Gap(6),
                        Text(
                          mode.$2,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isSelected
                                ? cs.primary
                                : cs.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const Gap(24),

          // Color scheme
          Text(
            'Renk Teması',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: cs.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const Gap(10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: colors.map((colorEntry) {
              final isSelected = _selectedColorScheme == colorEntry.$1;
              return GestureDetector(
                onTap: () =>
                    setState(() => _selectedColorScheme = colorEntry.$1),
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: isSelected ? 52 : 44,
                      height: isSelected ? 52 : 44,
                      decoration: BoxDecoration(
                        color: colorEntry.$3,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: cs.surface, width: 3)
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: colorEntry.$3.withValues(alpha: 0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 24,
                            )
                          : null,
                    ),
                    const Gap(6),
                    Text(
                      colorEntry.$2,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isSelected
                            ? colorEntry.$3
                            : cs.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── Step 3: Currency ─────────────────────────────────────────

  Widget _buildCurrencyPage(ColorScheme cs) {
    return _buildPageLayout(
      icon: Icons.account_balance_wallet_rounded,
      iconColor: AppTheme.completedColor,
      title: 'Para Birimi',
      subtitle: 'Finans modülünde kullanılacak para birimini seçin',
      child: Column(
        children: availableCurrencies.map((c) {
          final isSelected = _selectedCurrency == c['code'];
          return GestureDetector(
            onTap: () => setState(() => _selectedCurrency = c['code']!),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? cs.primary.withValues(alpha: 0.08)
                    : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? cs.primary.withValues(alpha: 0.4)
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Text(c['flag']!, style: const TextStyle(fontSize: 22)),
                  const Gap(14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c['name']!,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                        Text(
                          '${c['code']} (${c['symbol']})',
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle_rounded,
                      color: cs.primary,
                      size: 22,
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Shared Page Layout ───────────────────────────────────────

  Widget _buildPageLayout({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: iconColor, size: 32),
          ),
          const Gap(20),
          Text(
            title,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const Gap(8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: cs.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const Gap(28),
          // Content
          child,
        ],
      ),
    );
  }
}

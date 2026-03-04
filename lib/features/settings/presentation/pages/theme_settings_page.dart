import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../config/theme/theme_provider.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Theme settings page for customizing app appearance
class ThemeSettingsPage extends ConsumerWidget {
  const ThemeSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.themeSettings)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Theme Mode Section
          Text(
            'Tema Modu',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Gap(12),
          _buildThemeModeCard(context, themeState, themeNotifier),
          const Gap(28),

          // Color Scheme Section
          Text(
            'Renk Teması',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Gap(12),
          _buildColorSchemeGrid(context, themeState, themeNotifier),
        ],
      ),
    );
  }

  Widget _buildThemeModeCard(
    BuildContext context,
    ThemeState themeState,
    ThemeNotifier themeNotifier,
  ) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final modes = [
      (
        ThemeMode.light,
        'Açık Tema',
        'Her zaman açık renk teması',
        Icons.light_mode_rounded,
      ),
      (
        ThemeMode.dark,
        'Koyu Tema',
        'Her zaman koyu renk teması',
        Icons.dark_mode_rounded,
      ),
      (
        ThemeMode.system,
        'Sistem',
        'Cihaz ayarlarını takip et',
        Icons.smartphone_rounded,
      ),
    ];

    return Column(
      children: modes.map((mode) {
        final isSelected = themeState.themeMode == mode.$1;
        return GestureDetector(
          onTap: () => themeNotifier.setThemeMode(mode.$1),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected
                  ? cs.primary.withValues(alpha: 0.08)
                  : isDark
                  ? cs.surfaceContainerHighest
                  : cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? cs.primary.withValues(alpha: 0.3)
                    : cs.outlineVariant.withValues(alpha: 0.2),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  mode.$4,
                  size: 20,
                  color: isSelected
                      ? cs.primary
                      : cs.onSurface.withValues(alpha: 0.5),
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mode.$2,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        mode.$3,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle_rounded, color: cs.primary, size: 22),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildColorSchemeGrid(
    BuildContext context,
    ThemeState themeState,
    ThemeNotifier themeNotifier,
  ) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final schemes = [
      (AppColorScheme.blue, 'Mavi', AppTheme.seedColors['blue']!),
      (AppColorScheme.green, 'Yeşil', AppTheme.seedColors['green']!),
      (AppColorScheme.purple, 'Mor', AppTheme.seedColors['purple']!),
      (AppColorScheme.orange, 'Turuncu', AppTheme.seedColors['orange']!),
      (AppColorScheme.red, 'Kırmızı', AppTheme.seedColors['red']!),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: schemes.length,
      itemBuilder: (context, index) {
        final (scheme, label, color) = schemes[index];
        final isSelected = themeState.colorScheme == scheme;

        return GestureDetector(
          onTap: () => themeNotifier.setColorScheme(scheme),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: isDark
                  ? cs.surfaceContainerHighest
                  : cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? color
                    : cs.outlineVariant.withValues(alpha: 0.2),
                width: isSelected ? 2.5 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: isSelected ? 44 : 38,
                  height: isSelected ? 44 : 38,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
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
                const Gap(8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? color : cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/generated/app_localizations.dart';

class MainWrapperPage extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainWrapperPage({super.key, required this.navigationShell});

  void _goBranch(BuildContext context, int index) {
    // Unfocus when switching tabs
    FocusScope.of(context).unfocus();

    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.15)),
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
          ],
        ),
        child: NavigationBar(
          height: 64,
          selectedIndex: navigationShell.currentIndex,
          destinations: [
            NavigationDestination(
              label: l10n.homeTitle,
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home_rounded),
            ),
            NavigationDestination(
              label: l10n.financeTitle,
              icon: const Icon(Icons.wallet_outlined),
              selectedIcon: const Icon(Icons.wallet_rounded),
            ),
          ],
          onDestinationSelected: (index) => _goBranch(context, index),
        ),
      ),
    );
  }
}

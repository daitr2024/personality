import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/home/presentation/pages/main_wrapper_page.dart';

import '../../features/finance/presentation/pages/finance_summary_page.dart';
import '../../features/finance/presentation/pages/new_transaction_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/settings/presentation/pages/ai_settings_page.dart';
import '../../features/settings/presentation/pages/ai_setup_wizard_page.dart';
import '../../features/search/presentation/pages/search_page.dart';
import '../../features/statistics/presentation/pages/statistics_page.dart';
import '../../features/settings/presentation/pages/theme_settings_page.dart';
import '../../features/image_scan/presentation/pages/image_scan_page.dart';
import '../../features/settings/presentation/pages/profile_page.dart';
import '../../features/settings/presentation/pages/permissions_settings_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorHomeKey = GlobalKey<NavigatorState>(
  debugLabel: 'shellHome',
);
final _shellNavigatorFinanceKey = GlobalKey<NavigatorState>(
  debugLabel: 'shellFinance',
);

/// Creates a smooth slide+fade transition for page routes
CustomTransitionPage<T> _buildPageTransition<T>({
  required Widget child,
  required GoRouterState state,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.06, 0),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/home',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainWrapperPage(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          navigatorKey: _shellNavigatorHomeKey,
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomePage(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _shellNavigatorFinanceKey,
          routes: [
            GoRoute(
              path: '/finance',
              builder: (context, state) => const FinanceSummaryPage(),
              routes: [
                GoRoute(
                  path: 'new',
                  parentNavigatorKey: _rootNavigatorKey,
                  pageBuilder: (context, state) => _buildPageTransition(
                    child: const NewTransactionPage(),
                    state: state,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    ),

    // Top-level routes with smooth transitions
    GoRoute(
      path: '/settings',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) =>
          _buildPageTransition(child: const SettingsPage(), state: state),
      routes: [
        GoRoute(
          path: 'ai',
          pageBuilder: (context, state) =>
              _buildPageTransition(child: const AISettingsPage(), state: state),
        ),
        GoRoute(
          path: 'ai-wizard',
          pageBuilder: (context, state) => _buildPageTransition(
            child: const AISetupWizardPage(),
            state: state,
          ),
        ),
        GoRoute(
          path: 'profile',
          pageBuilder: (context, state) =>
              _buildPageTransition(child: const ProfilePage(), state: state),
        ),
        GoRoute(
          path: 'permissions',
          pageBuilder: (context, state) => _buildPageTransition(
            child: const PermissionSettingsPage(),
            state: state,
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/search',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) =>
          _buildPageTransition(child: const SearchPage(), state: state),
    ),
    GoRoute(
      path: '/statistics',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) =>
          _buildPageTransition(child: const StatisticsPage(), state: state),
    ),
    GoRoute(
      path: '/theme-settings',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) =>
          _buildPageTransition(child: const ThemeSettingsPage(), state: state),
    ),
    GoRoute(
      path: '/image-scan',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final useGallery = extra?['useGallery'] as bool? ?? false;
        return _buildPageTransition(
          child: ImageScanPage(useGallery: useGallery),
          state: state,
        );
      },
    ),
  ],
);

/// Onboarding router — shown only on first launch
final onboardingRouter = GoRouter(
  initialLocation: '/onboarding',
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingPage(),
    ),
  ],
);

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

import 'l10n/generated/app_localizations.dart';
import 'features/settings/presentation/providers/locale_provider.dart';
import 'config/routes/app_router.dart';
import 'config/theme/theme_provider.dart';
import 'core/services/notification_service.dart';
import 'features/onboarding/presentation/pages/onboarding_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  final String timeZoneName = await FlutterTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(timeZoneName));

  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.requestPermissions();

  runApp(const ProviderScope(child: PersonalityApp()));
}

class PersonalityApp extends ConsumerWidget {
  const PersonalityApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final themeState = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);
    final onboardingAsync = ref.watch(onboardingCompletedProvider);

    return FutureBuilder(
      future: initializeDateFormatting(locale.languageCode, null),
      builder: (context, snapshot) {
        return MaterialApp.router(
          title: 'Personality.ai',
          debugShowCheckedModeBanner: false,
          theme: themeNotifier.getLightTheme(),
          darkTheme: themeNotifier.getDarkTheme(),
          themeMode: themeState.themeMode,
          routerConfig: onboardingAsync.when(
            data: (completed) => completed ? router : onboardingRouter,
            loading: () => onboardingRouter,
            error: (_, _) => router,
          ),
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
        );
      },
    );
  }
}

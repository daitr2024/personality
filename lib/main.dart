import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'l10n/generated/app_localizations.dart';
import 'features/settings/presentation/providers/locale_provider.dart';
import 'config/routes/app_router.dart';
import 'config/theme/theme_provider.dart';
import 'core/services/notification_service.dart';
import 'core/database/app_database.dart' as core_db;
import 'features/finance/data/repositories/finance_repository.dart';
import 'features/onboarding/presentation/pages/onboarding_page.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      tz.initializeTimeZones();
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      debugPrint('🕐 TIMEZONE INIT: $timeZoneName → tz.local=${tz.local}');

      // Initialize notification service
      final notificationService = NotificationService();
      await notificationService.initialize();
      await notificationService.requestPermissions();

      // Initialize Firebase (graceful — won't crash if google-services.json missing)
      try {
        await Firebase.initializeApp();

        // Enable Crashlytics collection (including debug mode)
        await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
          true,
        );

        // Pass all uncaught Flutter errors to Crashlytics
        FlutterError.onError =
            FirebaseCrashlytics.instance.recordFlutterFatalError;

        debugPrint('✅ Firebase initialized, Crashlytics active');
      } catch (e) {
        debugPrint('⚠️ Firebase not initialized: $e');
      }

      // Auto-generate recurring transactions for current period
      try {
        final db = core_db.AppDatabase();
        final repo = FinanceRepository(db);
        final generated = await repo.generateRecurringInstances();
        if (generated > 0) {
          debugPrint('💰 Auto-generated $generated recurring transactions');
        }
      } catch (e) {
        debugPrint('⚠️ Recurring generation skipped: $e');
      }

      runApp(const ProviderScope(child: PersonalityApp()));
    },
    (error, stack) {
      // Forward async errors to Crashlytics if available
      try {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      } catch (_) {
        // Firebase not initialized — just print
      }
      debugPrint('🔴 Uncaught error: $error\n$stack');
    },
  );
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

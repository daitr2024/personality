// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:personality_ai/features/notes/presentation/widgets/audio_recorder_widget.dart';
import 'package:personality_ai/features/notes/presentation/providers/note_providers.dart';
import 'package:personality_ai/features/tasks/presentation/providers/task_providers.dart';
import 'package:personality_ai/features/calendar/presentation/providers/calendar_providers.dart';
import '../widgets/home_header.dart';
import '../widgets/two_week_calendar_bar.dart';
import '../widgets/daily_dashboard.dart';
import '../widgets/smart_input_bar.dart';
import '../../../../core/services/quick_access_service.dart';
import '../../../notes/presentation/widgets/audio_analysis_dialog.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../notifications/providers/notification_providers.dart';
import '../../../../core/services/home_widget_service.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final FocusNode _inputFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _setupQuickAccess();
    // Schedule smart notifications on app launch
    Future.microtask(() {
      ref.read(smartNotificationSchedulerProvider);
      // Update home widget with today's tasks
      final db = ref.read(databaseProvider);
      HomeWidgetService(db).updateWidget();
    });
  }

  @override
  void dispose() {
    _inputFocusNode.dispose();
    super.dispose();
  }

  Future<void> _setupQuickAccess() async {
    final service = ref.read(quickAccessServiceProvider);

    // Check cold start
    final pendingAction = await service.checkPendingAction();
    if (!mounted) return;

    if (pendingAction == 'ACTION_QUICK_NOTE') {
      _showRecordDialog(context, ref, autoStart: true);
    } else if (pendingAction == 'ACTION_QUICK_TEXT') {
      // Wait a bit for UI to build
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _inputFocusNode.requestFocus();
      });
    } else if (pendingAction == 'ACTION_IMAGE_SCAN') {
      context.push('/image-scan');
    } else if (pendingAction == 'ACTION_GALLERY_SCAN') {
      context.push('/image-scan', extra: {'useGallery': true});
    }

    // Listen for warm start
    service.setMethodCallHandler((call) async {
      if (!mounted) return;
      if (call.method == 'quickNoteTriggered') {
        _showRecordDialog(context, ref, autoStart: true);
      } else if (call.method == 'quickTextTriggered') {
        if (mounted) {
          // Ensure we are on top
          Navigator.of(context).popUntil((route) => route.isFirst);
          _inputFocusNode.requestFocus();
        }
      } else if (call.method == 'quickImageScanTriggered') {
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
          context.push('/image-scan');
        }
      } else if (call.method == 'quickGalleryScanTriggered') {
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
          context.push('/image-scan', extra: {'useGallery': true});
        }
      }
    });
  }

  void _showRecordDialog(
    BuildContext context,
    WidgetRef ref, {
    bool autoStart = false,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.quickAudioNote),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppLocalizations.of(context)!.tapToRecord),
            const Gap(16),
            AudioRecorderWidget(
              autoStart: autoStart,
              onRecordingComplete: (path, transcription) {
                // Auto-save when recording stops
                final content =
                    (transcription != null && transcription.isNotEmpty)
                    ? transcription
                    : AppLocalizations.of(context)!.quickAudioNote;

                ref
                    .read(notesRepositoryProvider)
                    .addNote(content, audioPath: path);
                Navigator.pop(context);

                if (transcription != null && transcription.isNotEmpty) {
                  // Auto-open Analysis
                  showDialog(
                    context: context,
                    builder: (context) =>
                        AudioAnalysisDialog(text: transcription),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context)!.audioNoteAddedNoText,
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Listener(
                onPointerDown: (_) {
                  if (_inputFocusNode.hasFocus) {
                    _inputFocusNode.unfocus();
                  }
                },
                child: RefreshIndicator(
                  onRefresh: () async {
                    // ... (haptic feedback and invalidation)
                    await HapticFeedback.mediumImpact();
                    ref.invalidate(taskListProvider);
                    ref.invalidate(calendarEventsProvider);
                    ref.invalidate(noteListProvider);
                    // Refresh smart notifications too
                    ref.invalidate(smartNotificationSchedulerProvider);
                    await Future.delayed(const Duration(milliseconds: 1200));

                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)!.dataRefreshed,
                        ),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    children: [
                      const HomeHeader(),
                      const TwoWeekCalendarBar(),
                      const Gap(8),
                      const DailyDashboard(),
                      const Gap(24),
                    ],
                  ),
                ),
              ),
            ),
            // Smart Input Bar at the bottom
            SmartInputBar(focusNode: _inputFocusNode),
          ],
        ),
      ),
      // FAB Removed
    );
  }
}

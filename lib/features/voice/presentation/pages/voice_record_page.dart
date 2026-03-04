import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../notes/presentation/widgets/audio_recorder_widget.dart';
import '../../../notes/presentation/widgets/audio_analysis_dialog.dart';
import '../../../notes/presentation/providers/note_providers.dart';
import '../../../../l10n/generated/app_localizations.dart';

class VoiceRecordPage extends ConsumerWidget {
  const VoiceRecordPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFF1E293B), // Dark Slate Blue
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.quickAudioNote,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const Gap(40),
              // Use the actual recorder instead of mock waveform
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: AudioRecorderWidget(
                  autoStart: true,
                  onRecordingComplete: (path, transcription) {
                    if (transcription != null && transcription.isNotEmpty) {
                      // 1. Save note
                      ref
                          .read(notesRepositoryProvider)
                          .addNote(transcription, audioPath: path);

                      // 2. Go back (prevent multiple layers)
                      context.pop();

                      // 3. Show analysis dialog on the previous screen
                      showDialog(
                        context: context,
                        builder: (ctx) =>
                            AudioAnalysisDialog(text: transcription),
                      );
                    } else {
                      // Transcription failed or empty
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.audioNoteAddedNoText)),
                      );
                      context.pop();
                    }
                  },
                ),
              ),
              const Gap(40),
              Text(
                l10n.tapToRecord,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

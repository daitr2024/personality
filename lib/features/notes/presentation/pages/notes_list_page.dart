import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../core/database/app_database.dart';
import '../providers/note_providers.dart';
import '../widgets/audio_recorder_widget.dart';
import '../widgets/audio_player_widget.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../core/widgets/attachment_manager.dart';

class NotesListPage extends ConsumerWidget {
  const NotesListPage({super.key});

  void _showNoteDialog(
    BuildContext context,
    WidgetRef ref, {
    NoteEntity? note,
  }) {
    final controller = TextEditingController(text: note?.content);
    String? recordedPath = note?.audioPath;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: Text(
          note != null
              ? AppLocalizations.of(context)!.editNote
              : AppLocalizations.of(context)!.addNewNote,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.noteHint,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const Gap(16),
              if (note != null)
                AttachmentManager(
                  itemId: note.id,
                  source: AttachmentSource.note,
                ),
              const Gap(16),
              AudioRecorderWidget(
                onRecordingComplete: (path, transcription) {
                  // If path is empty (deleted after transcription), clear recordedPath
                  if (path.isEmpty) {
                    recordedPath = null;
                  } else {
                    recordedPath = path;
                  }

                  if (transcription != null && transcription.isNotEmpty) {
                    // Append transcription to text field if it has content, or set it
                    if (controller.text.isEmpty) {
                      controller.text = transcription;
                    } else {
                      controller.text = '${controller.text}\n$transcription';
                    }
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty || recordedPath != null) {
                final text = controller.text.isEmpty
                    ? AppLocalizations.of(context)!.voiceNote
                    : controller.text;
                if (note != null) {
                  // Update an existing note
                  ref
                      .read(notesRepositoryProvider)
                      .updateNote(note.id, text, audioPath: recordedPath);
                } else {
                  // Add a new note
                  ref
                      .read(notesRepositoryProvider)
                      .addNote(text, audioPath: recordedPath);
                }
                Navigator.pop(context);
              }
            },
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(noteListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.notesTitle),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: notesAsync.when(
        data: (notes) {
          final cs = Theme.of(context).colorScheme;
          if (notes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.note_alt_rounded,
                    size: 64,
                    color: cs.onSurface.withValues(alpha: 0.1),
                  ),
                  const Gap(16),
                  Text(
                    AppLocalizations.of(context)!.noNotesToday,
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            itemCount: notes.length,
            separatorBuilder: (context, index) => const Gap(4),
            itemBuilder: (context, index) {
              final note = notes[index];
              final isDark = Theme.of(context).brightness == Brightness.dark;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Slidable(
                  key: ValueKey('note_slidable_${note.id}_v3'),
                  endActionPane: ActionPane(
                    motion: const ScrollMotion(),
                    extentRatio: 0.5,
                    children: [
                      SlidableAction(
                        onPressed: (context) =>
                            _showNoteDialog(context, ref, note: note),
                        backgroundColor: AppTheme.eventColor.withValues(
                          alpha: 0.8,
                        ),
                        foregroundColor: Colors.white,
                        icon: Icons.edit_rounded,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                        ),
                      ),
                      SlidableAction(
                        onPressed: (context) => ref
                            .read(notesRepositoryProvider)
                            .deleteNote(note.id),
                        backgroundColor: AppTheme.urgentColor.withValues(
                          alpha: 0.8,
                        ),
                        foregroundColor: Colors.white,
                        icon: Icons.delete_outline_rounded,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                    ],
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? cs.surfaceContainerHighest : cs.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: cs.outlineVariant.withValues(
                          alpha: isDark ? 0.1 : 0.2,
                        ),
                      ),
                      boxShadow: [
                        if (!isDark)
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                      ],
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.transparent,
                        listTileTheme: const ListTileThemeData(
                          minLeadingWidth: 0,
                        ),
                      ),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        iconColor: cs.primary,
                        collapsedIconColor: cs.onSurface.withValues(alpha: 0.3),
                        title: Text(
                          note.content,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          DateFormat(
                            'd MMMM y HH:mm',
                            Localizations.localeOf(context).toString(),
                          ).format(note.date),
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                (note.audioPath != null
                                        ? AppTheme.eventColor
                                        : AppTheme.noteColor)
                                    .withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            note.audioPath != null
                                ? Icons.mic_rounded
                                : Icons.note_rounded,
                            color: note.audioPath != null
                                ? AppTheme.eventColor
                                : AppTheme.noteColor,
                            size: 20,
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Divider(height: 1),
                                const Gap(16),
                                if (note.audioPath != null) ...[
                                  AudioPlayerWidget(audioPath: note.audioPath!),
                                  const Gap(16),
                                ],
                                Text(
                                  note.content,
                                  style: TextStyle(
                                    fontSize: 15,
                                    height: 1.6,
                                    color: cs.onSurface.withValues(alpha: 0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            Center(child: Text('${AppLocalizations.of(context)!.error}: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNoteDialog(context, ref),
        elevation: 4,
        child: const Icon(Icons.add_rounded, size: 30),
      ),
    );
  }
}

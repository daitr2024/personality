import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../features/tasks/presentation/providers/attachment_providers.dart';
import '../../core/database/app_database.dart';
import 'media_preview.dart';
import '../../l10n/generated/app_localizations.dart';

enum AttachmentSource { task, note, transaction, event }

class AttachmentManager extends ConsumerWidget {
  final int itemId;
  final AttachmentSource source;
  final bool readOnly;

  const AttachmentManager({
    super.key,
    required this.itemId,
    required this.source,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attachmentsAsync = _getAttachments(ref);

    return attachmentsAsync.when(
      data: (attachments) {
        if (attachments.isEmpty && readOnly) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(
                    context,
                  )!.mediaFilesCount(attachments.length),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                if (!readOnly)
                  IconButton(
                    onPressed: () => _showAttachmentOptions(context, ref),
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: Colors.blue,
                    ),
                    tooltip: AppLocalizations.of(context)!.addFile,
                  ),
              ],
            ),
            const Gap(8),
            if (attachments.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.attachment, color: Colors.grey, size: 32),
                    const Gap(8),
                    Text(
                      AppLocalizations.of(context)!.noMediaYet,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.0,
                ),
                itemCount: attachments.length,
                itemBuilder: (context, index) {
                  final attachment = attachments[index];
                  return MediaPreview(
                    attachment: attachment,
                    onDelete: readOnly
                        ? null
                        : () => _confirmDelete(context, ref, attachment),
                  );
                },
              ),
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Center(
        child: Text('Hata: $error', style: const TextStyle(color: Colors.red)),
      ),
    );
  }

  AsyncValue<List<AttachmentEntity>> _getAttachments(WidgetRef ref) {
    switch (source) {
      case AttachmentSource.task:
        return ref.watch(taskAttachmentsProvider(itemId));
      case AttachmentSource.note:
        return ref.watch(noteAttachmentsProvider(itemId));
      case AttachmentSource.transaction:
        // These need to be added to the provider file
        return ref.watch(transactionAttachmentsProvider(itemId));
      case AttachmentSource.event:
        return ref.watch(eventAttachmentsProvider(itemId));
    }
  }

  Future<void> _showAttachmentOptions(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final service = ref.read(attachmentServiceProvider);

    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Gap(16),
              Text(
                AppLocalizations.of(context)!.addMedia,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Gap(12),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.camera_alt, color: Colors.white),
                ),
                title: Text(AppLocalizations.of(context)!.takePhoto),
                onTap: () => Navigator.pop(context, 'camera'),
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.indigo,
                  child: Icon(Icons.photo_library, color: Colors.white),
                ),
                title: Text(AppLocalizations.of(context)!.chooseFromGallery),
                onTap: () => Navigator.pop(context, 'gallery'),
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.amber,
                  child: Icon(Icons.mic, color: Colors.white),
                ),
                title: Text(AppLocalizations.of(context)!.chooseAudioFile),
                onTap: () => Navigator.pop(context, 'audio'),
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.deepOrange,
                  child: Icon(Icons.videocam, color: Colors.white),
                ),
                title: Text(AppLocalizations.of(context)!.chooseVideo),
                onTap: () => Navigator.pop(context, 'video'),
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.attach_file, color: Colors.white),
                ),
                title: Text(AppLocalizations.of(context)!.otherFiles),
                onTap: () => Navigator.pop(context, 'file'),
              ),
              const Gap(12),
            ],
          ),
        ),
      ),
    );

    if (choice == null || !context.mounted) return;

    File? file;
    switch (choice) {
      case 'camera':
        file = await service.pickImage(fromCamera: true);
        break;
      case 'gallery':
        file = await service.pickImage(fromCamera: false);
        break;
      case 'audio':
        file = await service.pickAudio();
        break;
      case 'video':
        file = await service.pickVideo();
        break;
      case 'file':
        file = await service.pickFile();
        break;
    }

    if (file != null) {
      await service.saveAttachment(
        file: file,
        taskId: source == AttachmentSource.task ? itemId : null,
        noteId: source == AttachmentSource.note ? itemId : null,
        transactionId: source == AttachmentSource.transaction ? itemId : null,
        eventId: source == AttachmentSource.event ? itemId : null,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.fileAddedSuccess),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    AttachmentEntity attachment,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteMedia),
        content: Text(
          AppLocalizations.of(context)!.deleteConfirmFile(attachment.fileName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(attachmentServiceProvider).deleteAttachment(attachment.id);
    }
  }
}

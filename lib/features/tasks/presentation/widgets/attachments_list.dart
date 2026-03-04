import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../../../core/database/app_database.dart';
import '../providers/attachment_providers.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Widget for displaying and managing attachments
class AttachmentsList extends ConsumerWidget {
  final int? taskId;
  final int? noteId;
  final bool readOnly;

  const AttachmentsList({
    super.key,
    this.taskId,
    this.noteId,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attachmentsAsync = taskId != null
        ? ref.watch(taskAttachmentsProvider(taskId!))
        : noteId != null
        ? ref.watch(noteAttachmentsProvider(noteId!))
        : const AsyncValue.data(<AttachmentEntity>[]);

    return attachmentsAsync.when(
      data: (attachments) {
        if (attachments.isEmpty && readOnly) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (attachments.isNotEmpty) ...[
              const Text(
                'Ekler',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const Gap(8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: attachments
                    .map(
                      (attachment) => _AttachmentChip(
                        attachment: attachment,
                        readOnly: readOnly,
                      ),
                    )
                    .toList(),
              ),
            ],
            if (!readOnly) ...[
              if (attachments.isNotEmpty) const Gap(12),
              _AddAttachmentButton(taskId: taskId, noteId: noteId),
            ],
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Text('${AppLocalizations.of(context)!.error}: $error'),
    );
  }
}

class _AttachmentChip extends ConsumerWidget {
  final AttachmentEntity attachment;
  final bool readOnly;

  const _AttachmentChip({required this.attachment, this.readOnly = false});

  IconData _getIcon() {
    switch (attachment.fileType) {
      case 'image':
        return Icons.image;
      case 'pdf':
        return Icons.picture_as_pdf;
      default:
        return Icons.attach_file;
    }
  }

  Color _getColor() {
    switch (attachment.fileType) {
      case 'image':
        return Colors.blue;
      case 'pdf':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(attachmentServiceProvider);

    return Chip(
      avatar: Icon(_getIcon(), color: _getColor(), size: 18),
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            attachment.fileName,
            style: const TextStyle(fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            service.getFileSizeString(attachment.fileSize),
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          ),
        ],
      ),
      deleteIcon: readOnly ? null : const Icon(Icons.close, size: 18),
      onDeleted: readOnly
          ? null
          : () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(AppLocalizations.of(context)!.deleteAttachment),
                  content: const Text(
                    'Bu eki silmek istediğinizden emin misiniz?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(AppLocalizations.of(context)!.cancel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(AppLocalizations.of(context)!.delete),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                await service.deleteAttachment(attachment.id);
              }
            },
    );
  }
}

class _AddAttachmentButton extends ConsumerWidget {
  final int? taskId;
  final int? noteId;

  const _AddAttachmentButton({this.taskId, this.noteId});

  Future<void> _showAttachmentOptions(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final service = ref.read(attachmentServiceProvider);

    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(AppLocalizations.of(context)!.takePhoto),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(AppLocalizations.of(context)!.chooseFromGallery),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: Text(AppLocalizations.of(context)!.chooseFile),
              onTap: () => Navigator.pop(context, 'file'),
            ),
          ],
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
      case 'file':
        file = await service.pickFile();
        break;
    }

    if (file != null) {
      await service.saveAttachment(file: file, taskId: taskId, noteId: noteId);

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.attachmentAdded)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      onPressed: () => _showAttachmentOptions(context, ref),
      icon: const Icon(Icons.attach_file, size: 18),
      label: Text(AppLocalizations.of(context)!.addFile, style: const TextStyle(fontSize: 13)),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import '../database/app_database.dart';
import '../../features/notes/presentation/widgets/audio_player_widget.dart';

class MediaPreview extends StatelessWidget {
  final AttachmentEntity attachment;
  final VoidCallback? onDelete;

  const MediaPreview({super.key, required this.attachment, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          _buildContent(context),
          if (onDelete != null)
            Positioned(
              top: 4,
              right: 4,
              child: Semantics(
                label: 'Eki sil',
                button: true,
                child: GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (attachment.fileType) {
      case 'image':
        return Semantics(
          label: 'Resim: ${attachment.fileName}',
          image: true,
          child: GestureDetector(
            onTap: () => _showFullScreenImage(context),
            child: Image.file(
              File(attachment.filePath),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) => const Center(
                child: Icon(Icons.broken_image, color: Colors.grey),
              ),
            ),
          ),
        );
      case 'audio':
        return Semantics(
          label: 'Ses dosyası: ${attachment.fileName}',
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.audiotrack, size: 32, color: Colors.blue),
                  const SizedBox(height: 8),
                  Text(
                    attachment.fileName,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  AudioPlayerWidget(audioPath: attachment.filePath),
                ],
              ),
            ),
          ),
        );
      case 'pdf':
      case 'document':
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  attachment.fileType == 'pdf'
                      ? Icons.picture_as_pdf
                      : Icons.description,
                  size: 32,
                  color: Colors.orange,
                ),
                const SizedBox(height: 8),
                Text(
                  attachment.fileName,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => _openFile(context),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Aç', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    minimumSize: const Size(0, 32),
                  ),
                ),
              ],
            ),
          ),
        );
      default:
        return Semantics(
          label: 'Dosya: ${attachment.fileName}',
          child: const Center(
            child: Icon(Icons.insert_drive_file, size: 32, color: Colors.grey),
          ),
        );
    }
  }

  void _showFullScreenImage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.file(
                File(attachment.filePath),
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Icon(
                    Icons.broken_image,
                    size: 64,
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openFile(BuildContext context) async {
    final file = File(attachment.filePath);
    if (!file.existsSync()) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Dosya bulunamadı')));
      }
      return;
    }
    final result = await OpenFilex.open(attachment.filePath);
    if (result.type != ResultType.done && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dosya açılamadı: ${result.message}')),
      );
    }
  }
}

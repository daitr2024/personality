import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:drift/drift.dart';
import '../database/app_database.dart';

/// Service for managing file attachments
class AttachmentService {
  final AppDatabase _database;
  final ImagePicker _imagePicker = ImagePicker();

  AttachmentService(this._database);

  /// Pick an image from gallery or camera
  Future<File?> pickImage({bool fromCamera = false}) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Pick a video from gallery or camera
  Future<File?> pickVideo({bool fromCamera = false}) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickVideo(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Pick an audio file
  Future<File?> pickAudio() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.audio);

      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Pick a file (PDF, document, etc.)
  Future<File?> pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
      );

      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Save attachment to local storage and database
  Future<int?> saveAttachment({
    required File file,
    int? taskId,
    int? noteId,
    int? transactionId,
    int? eventId,
  }) async {
    try {
      // Get app directory
      final appDir = await getApplicationDocumentsDirectory();
      final attachmentsDir = Directory('${appDir.path}/attachments');
      if (!await attachmentsDir.exists()) {
        await attachmentsDir.create(recursive: true);
      }

      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(file.path);
      final fileName = path.basename(file.path);
      final newFileName = '${timestamp}_$fileName';
      final newPath = '${attachmentsDir.path}/$newFileName';

      // Copy file to app directory
      final savedFile = await file.copy(newPath);

      // Determine file type
      String fileType = 'document';
      final ext = extension.toLowerCase();
      if (['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(ext)) {
        fileType = 'image';
      } else if (ext == '.pdf') {
        fileType = 'pdf';
      } else if (['.mp3', '.m4a', '.wav', '.ogg', '.aac'].contains(ext)) {
        fileType = 'audio';
      } else if (['.mp4', '.mov', '.avi', '.mkv'].contains(ext)) {
        fileType = 'video';
      }

      // Get file size
      final fileSize = await savedFile.length();

      // Save to database
      final attachmentId = await _database
          .into(_database.attachments)
          .insert(
            AttachmentsCompanion.insert(
              taskId: taskId != null ? Value(taskId) : const Value.absent(),
              noteId: noteId != null ? Value(noteId) : const Value.absent(),
              transactionId: transactionId != null
                  ? Value(transactionId)
                  : const Value.absent(),
              eventId: eventId != null ? Value(eventId) : const Value.absent(),
              filePath: newPath,
              fileName: fileName,
              fileType: fileType,
              fileSize: fileSize,
              createdAt: DateTime.now(),
            ),
          );

      return attachmentId;
    } catch (e) {
      return null;
    }
  }

  /// Get attachments for a task
  Future<List<AttachmentEntity>> getTaskAttachments(int taskId) async {
    return await (_database.select(
      _database.attachments,
    )..where((a) => a.taskId.equals(taskId))).get();
  }

  /// Get attachments for a note
  Future<List<AttachmentEntity>> getNoteAttachments(int noteId) async {
    return await (_database.select(
      _database.attachments,
    )..where((a) => a.noteId.equals(noteId))).get();
  }

  /// Get attachments for a transaction
  Future<List<AttachmentEntity>> getTransactionAttachments(
    int transactionId,
  ) async {
    return await (_database.select(
      _database.attachments,
    )..where((a) => a.transactionId.equals(transactionId))).get();
  }

  /// Get attachments for an event
  Future<List<AttachmentEntity>> getEventAttachments(int eventId) async {
    return await (_database.select(
      _database.attachments,
    )..where((a) => a.eventId.equals(eventId))).get();
  }

  /// Delete attachment
  Future<bool> deleteAttachment(int attachmentId) async {
    try {
      // Get attachment info
      final attachment = await (_database.select(
        _database.attachments,
      )..where((a) => a.id.equals(attachmentId))).getSingleOrNull();

      if (attachment == null) return false;

      // Delete file from storage
      final file = File(attachment.filePath);
      if (await file.exists()) {
        await file.delete();
      }

      // Delete from database
      await (_database.delete(
        _database.attachments,
      )..where((a) => a.id.equals(attachmentId))).go();

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get file size in human-readable format
  String getFileSizeString(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

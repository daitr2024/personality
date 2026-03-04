import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

class BackupService {
  static const String _dbName = 'db_v2.sqlite';
  static const String _backupFileName = 'personality_ai_backup.zip';

  /// Creates a backup of the database and media files
  Future<void> createBackup() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final backupFile = File(p.join(appDir.path, _backupFileName));

      if (await backupFile.exists()) {
        await backupFile.delete();
      }

      final encoder = ZipFileEncoder();
      encoder.create(backupFile.path);

      // 1. Add Database
      final dbFile = File(p.join(appDir.path, _dbName));
      if (await dbFile.exists()) {
        encoder.addFile(dbFile);
      }

      // 2. Add Receipts
      final receiptDir = Directory(p.join(appDir.path, 'receipts'));
      if (await receiptDir.exists()) {
        await _addDirectoryToZip(encoder, receiptDir, 'receipts');
      }

      // 3. Add Attachments
      final attachmentsDir = Directory(p.join(appDir.path, 'attachments'));
      if (await attachmentsDir.exists()) {
        await _addDirectoryToZip(encoder, attachmentsDir, 'attachments');
      }

      encoder.close();

      // Share the file
      // ignore: deprecated_member_use
      await Share.shareXFiles(
        [XFile(backupFile.path)],
        subject:
            'Personality.ai Yedek - ${DateTime.now().toString().split('.')[0]}',
      );
    } catch (e) {
      debugPrint('Backup Error: $e');
      rethrow;
    }
  }

  /// Restores data from a backup ZIP file
  /// Returns true if success, false if cancelled
  Future<bool> restoreBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (result == null || result.files.single.path == null) {
        return false;
      }

      final zipFile = File(result.files.single.path!);
      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      final appDir = await getApplicationDocumentsDirectory();

      for (final file in archive) {
        final filename = file.name;
        if (file.isFile) {
          final data = file.content as List<int>;
          final outFile = File(p.join(appDir.path, filename));

          // Ensure directory exists
          await outFile.parent.create(recursive: true);
          await outFile.writeAsBytes(data);
        }
      }

      return true;
    } catch (e) {
      debugPrint('Restore Error: $e');
      rethrow;
    }
  }

  Future<void> _addDirectoryToZip(
    ZipFileEncoder encoder,
    Directory dir,
    String zipPath,
  ) async {
    final List<FileSystemEntity> entities = await dir
        .list(recursive: true)
        .toList();
    for (var entity in entities) {
      if (entity is File) {
        final relativePath = p.relative(entity.path, from: dir.parent.path);
        encoder.addFile(entity, relativePath);
      }
    }
  }
}

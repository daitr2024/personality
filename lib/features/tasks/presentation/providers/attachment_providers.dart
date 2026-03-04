import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/attachment_service.dart';
import '../../../../core/database/app_database.dart';

/// Provider for AppDatabase (reuse from search)
final _appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

/// Provider for AttachmentService
final attachmentServiceProvider = Provider<AttachmentService>((ref) {
  final database = ref.watch(_appDatabaseProvider);
  return AttachmentService(database);
});

/// Provider for task attachments
final taskAttachmentsProvider =
    StreamProvider.family<List<AttachmentEntity>, int>((ref, taskId) {
      final database = ref.watch(_appDatabaseProvider);
      return (database.select(
        database.attachments,
      )..where((a) => a.taskId.equals(taskId))).watch();
    });

/// Provider for note attachments
final noteAttachmentsProvider =
    StreamProvider.family<List<AttachmentEntity>, int>((ref, noteId) {
      final database = ref.watch(_appDatabaseProvider);
      return (database.select(
        database.attachments,
      )..where((a) => a.noteId.equals(noteId))).watch();
    });

/// Provider for transaction attachments
final transactionAttachmentsProvider =
    StreamProvider.family<List<AttachmentEntity>, int>((ref, transactionId) {
      final database = ref.watch(_appDatabaseProvider);
      return (database.select(
        database.attachments,
      )..where((a) => a.transactionId.equals(transactionId))).watch();
    });

/// Provider for event attachments
final eventAttachmentsProvider =
    StreamProvider.family<List<AttachmentEntity>, int>((ref, eventId) {
      final database = ref.watch(_appDatabaseProvider);
      return (database.select(
        database.attachments,
      )..where((a) => a.eventId.equals(eventId))).watch();
    });

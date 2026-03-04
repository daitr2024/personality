import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/backup_service.dart';

/// Provider for backup service
final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService();
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/image_analysis_service.dart';
import '../../../../features/settings/presentation/providers/ai_config_provider.dart';
import '../../../../features/tasks/presentation/providers/attachment_providers.dart';
import '../../../../features/tasks/presentation/providers/task_providers.dart';

/// Provider for ImageAnalysisService
/// Uses shared databaseProvider to ensure same DB instance as task/event providers
final imageAnalysisServiceProvider = Provider<ImageAnalysisService>((ref) {
  final database = ref.watch(databaseProvider);
  final aiConfig = ref.watch(aiConfigServiceProvider);
  final attachmentService = ref.watch(attachmentServiceProvider);
  return ImageAnalysisService(database, aiConfig, attachmentService);
});

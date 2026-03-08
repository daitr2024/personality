import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/ai_config_service.dart';
import '../../../../core/services/audio_analysis_service.dart';

/// Provider for AI configuration service
final aiConfigServiceProvider = Provider<AIConfigService>((ref) {
  return AIConfigService();
});

final audioAnalysisServiceProvider = Provider<AudioAnalysisService>((ref) {
  final configService = ref.watch(aiConfigServiceProvider);
  return AudioAnalysisService(configService);
});

/// Provider for checking if AI is configured
final aiConfiguredProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(aiConfigServiceProvider);
  return await service.isConfigured();
});

/// Provider for AI endpoint
final aiEndpointProvider = FutureProvider<String>((ref) async {
  final service = ref.watch(aiConfigServiceProvider);
  return await service.getEndpoint();
});

/// Provider for AI model
final aiModelProvider = FutureProvider<String>((ref) async {
  final service = ref.watch(aiConfigServiceProvider);
  return await service.getModel();
});

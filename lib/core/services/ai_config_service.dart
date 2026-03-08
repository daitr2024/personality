import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Service for managing AI configuration settings
/// Stores API credentials securely using flutter_secure_storage
class AIConfigService {
  static const _storage = FlutterSecureStorage();

  // Storage keys
  static const _keyApiEndpoint = 'ai_api_endpoint';
  static const _keyApiKey = 'ai_api_key';
  static const _keyModel = 'ai_model';
  static const _keyApiKeyBackup = 'ai_api_key_backup';
  static const _keyApiEndpointBackup = 'ai_api_endpoint_backup';
  static const _keyModelBackup = 'ai_model_backup';
  static const _keyVisionEndpoint = 'vision_api_endpoint';
  static const _keyVisionKey = 'vision_api_key';
  static const _keyVisionModel = 'vision_model';
  static const _keyVisionEndpointBackup = 'vision_api_endpoint_backup';
  static const _keyVisionKeyBackup = 'vision_api_key_backup';
  static const _keyVisionModelBackup = 'vision_model_backup';
  static const _keyAlwaysUseLocalSTT = 'always_use_local_stt';
  static const _keyAutoStopOnSilence = 'auto_stop_on_silence';

  // Default values (Gemini Focused)
  static const _defaultEndpoint =
      'https://generativelanguage.googleapis.com/v1beta/openai/v1';
  static const _defaultModel = 'gemini-2.0-flash';

  /// Get API endpoint
  Future<String> getEndpoint() async {
    final value = await _storage.read(key: _keyApiEndpoint);
    return value ?? _defaultEndpoint;
  }

  /// Set API endpoint
  Future<void> setEndpoint(String endpoint) async {
    await _storage.write(key: _keyApiEndpoint, value: endpoint);
  }

  /// Get API key
  Future<String?> getApiKey() async {
    return await _storage.read(key: _keyApiKey);
  }

  /// Set API key
  Future<void> setApiKey(String apiKey) async {
    await _storage.write(key: _keyApiKey, value: apiKey.trim());
  }

  /// Get model name
  Future<String> getModel() async {
    final value = await _storage.read(key: _keyModel);
    return value ?? _defaultModel;
  }

  /// Set model name
  Future<void> setModel(String model) async {
    await _storage.write(key: _keyModel, value: model);
  }

  // Backup Configs
  Future<String> getEndpointBackup() async {
    final value = await _storage.read(key: _keyApiEndpointBackup);
    return value ?? _defaultEndpoint;
  }

  Future<void> setEndpointBackup(String endpoint) async {
    await _storage.write(key: _keyApiEndpointBackup, value: endpoint);
  }

  Future<String?> getApiKeyBackup() async {
    return await _storage.read(key: _keyApiKeyBackup);
  }

  Future<void> setApiKeyBackup(String apiKey) async {
    await _storage.write(key: _keyApiKeyBackup, value: apiKey.trim());
  }

  Future<String> getModelBackup() async {
    final value = await _storage.read(key: _keyModelBackup);
    return value ?? _defaultModel;
  }

  Future<void> setModelBackup(String model) async {
    await _storage.write(key: _keyModelBackup, value: model);
  }

  // Vision Configs
  Future<String> getVisionEndpoint() async {
    final value = await _storage.read(key: _keyVisionEndpoint);
    if (value == null || value.trim().isEmpty) return await getEndpoint();
    return value;
  }

  Future<void> setVisionEndpoint(String endpoint) async {
    await _storage.write(key: _keyVisionEndpoint, value: endpoint.trim());
  }

  Future<String?> getVisionApiKey() async {
    final value = await _storage.read(key: _keyVisionKey);
    if (value == null || value.trim().isEmpty) return await getApiKey();
    return value;
  }

  Future<void> setVisionApiKey(String apiKey) async {
    await _storage.write(key: _keyVisionKey, value: apiKey.trim());
  }

  Future<String> getVisionModel() async {
    final value = await _storage.read(key: _keyVisionModel);
    if (value == null || value.trim().isEmpty) return await getModel();
    return value;
  }

  Future<void> setVisionModel(String model) async {
    await _storage.write(key: _keyVisionModel, value: model);
  }

  // Vision Backup Configs
  Future<String> getVisionEndpointBackup() async {
    final value = await _storage.read(key: _keyVisionEndpointBackup);
    return value ?? await getVisionEndpoint();
  }

  Future<void> setVisionEndpointBackup(String endpoint) async {
    await _storage.write(key: _keyVisionEndpointBackup, value: endpoint);
  }

  Future<String?> getVisionApiKeyBackup() async {
    return await _storage.read(key: _keyVisionKeyBackup);
  }

  Future<void> setVisionApiKeyBackup(String apiKey) async {
    await _storage.write(key: _keyVisionKeyBackup, value: apiKey.trim());
  }

  Future<String> getVisionModelBackup() async {
    final value = await _storage.read(key: _keyVisionModelBackup);
    return value ?? 'gemini-1.5-flash';
  }

  Future<void> setVisionModelBackup(String model) async {
    await _storage.write(key: _keyVisionModelBackup, value: model);
  }

  /// Get always use local STT
  Future<bool> getAlwaysUseLocalSTT() async {
    final value = await _storage.read(key: _keyAlwaysUseLocalSTT);
    return value == 'true';
  }

  /// Set always use local STT
  Future<void> setAlwaysUseLocalSTT(bool value) async {
    await _storage.write(key: _keyAlwaysUseLocalSTT, value: value.toString());
  }

  /// Get auto-stop on silence setting (default: true)
  Future<bool> getAutoStopOnSilence() async {
    final value = await _storage.read(key: _keyAutoStopOnSilence);
    return value != 'false'; // default true
  }

  /// Set auto-stop on silence
  Future<void> setAutoStopOnSilence(bool value) async {
    await _storage.write(key: _keyAutoStopOnSilence, value: value.toString());
  }

  /// Reset all settings to defaults
  Future<void> resetToDefaults() async {
    await _storage.deleteAll();
  }

  /// Check if API key is configured
  Future<bool> isConfigured() async {
    final apiKey = await getApiKey();
    return apiKey != null && apiKey.isNotEmpty;
  }

  /// Test API connection
  Future<(bool, String?)> testConnection({
    bool isBackup = false,
    bool isVision = false,
  }) async {
    try {
      String endpoint;
      String? apiKey;

      if (isVision) {
        endpoint = isBackup
            ? await getVisionEndpointBackup()
            : await getVisionEndpoint();
        apiKey = isBackup
            ? await getVisionApiKeyBackup()
            : await getVisionApiKey();
      } else {
        endpoint = isBackup ? await getEndpointBackup() : await getEndpoint();
        apiKey = isBackup ? await getApiKeyBackup() : await getApiKey();
      }

      if (apiKey == null || apiKey.isEmpty) {
        return (false, 'API Key bulunamadı');
      }

      String cleanEndpoint = endpoint.trim();
      if (cleanEndpoint.endsWith('/')) {
        cleanEndpoint = cleanEndpoint.substring(0, cleanEndpoint.length - 1);
      }

      // Special handling for Gemini direct endpoints vs OpenAI compatible ones
      final isGeminiEndpoint = cleanEndpoint.contains(
        'generativelanguage.googleapis.com',
      );
      final isOpenAiCompatible = cleanEndpoint.contains('/openai');

      Uri testUri;
      Map<String, String> headers = {};
      headers['Content-Type'] = 'application/json';

      if (isGeminiEndpoint && !isOpenAiCompatible) {
        // Direct Gemini API test: /v1beta/models?key=...
        testUri = Uri.parse('$cleanEndpoint/models?key=${apiKey.trim()}');
      } else {
        // OpenAI compatible test or standard OpenAI
        // MUST use Authorization header, MUST NOT use ?key= in URL for /openai path
        testUri = Uri.parse('$cleanEndpoint/models');
        headers['Authorization'] = 'Bearer ${apiKey.trim()}';
      }

      debugPrint('Testing connection to: $testUri');
      debugPrint('Using headers: ${headers.keys.join(", ")}');

      final response = await http
          .get(testUri, headers: headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) return (true, null);

      final errorMsg = utf8.decode(response.bodyBytes);
      debugPrint('Connection test failed (${response.statusCode}): $errorMsg');

      if (response.statusCode == 401) {
        return (false, 'Hata 401: API Anahtarı geçersiz.');
      }
      return (false, 'Hata: ${response.statusCode}');
    } catch (e) {
      debugPrint('Connection test error: $e');
      return (false, 'Bağlantı Hatası: $e');
    }
  }

  Future<List<String>> fetchModels({bool isVision = false}) async {
    return _getDefaultModels(isVision);
  }

  List<String> _getDefaultModels(bool isVision) {
    return [
      'gemini-2.0-flash',
      'gemini-2.5-pro-preview-06-05',
      'gemini-2.0-flash-lite',
    ];
  }
}

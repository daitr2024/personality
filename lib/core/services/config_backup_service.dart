import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for backing up and restoring AI configuration to local storage.
///
/// Saves config to a hidden folder on the device's external storage
/// (/storage/emulated/0/.personality_ai/) which persists after app uninstall.
///
/// Flow:
/// 1. User taps "Yedekle" → config saved to hidden folder as obfuscated file
/// 2. User uninstalls and reinstalls app
/// 3. App detects backup file and offers to restore
class ConfigBackupService {
  static const _storage = FlutterSecureStorage();
  static const _backupDirName = '.personality_ai';
  static const _backupFileName = 'config.bak';

  // All configuration keys to backup
  static const _configKeys = [
    'ai_api_endpoint',
    'ai_api_key',
    'ai_model',
    'ai_api_key_backup',
    'ai_api_endpoint_backup',
    'ai_model_backup',
    'vision_api_endpoint',
    'vision_api_key',
    'vision_model',
    'vision_api_endpoint_backup',
    'vision_api_key_backup',
    'vision_model_backup',
    'always_use_local_stt',
    'auto_stop_on_silence',
  ];

  static const _magicHeader = 'PAI_CFG_V1:';

  /// Get the hidden backup directory path
  static Future<Directory?> _getBackupDir({bool create = false}) async {
    if (!Platform.isAndroid) return null;
    final dir = Directory('/storage/emulated/0/$_backupDirName');
    if (create && !await dir.exists()) {
      await dir.create(recursive: true);
    }
    if (await dir.exists()) return dir;
    return null;
  }

  /// Export current AI configuration to hidden local folder.
  /// Returns true if successful.
  static Future<bool> exportConfig() async {
    try {
      final dir = await _getBackupDir(create: true);
      if (dir == null) {
        debugPrint('ConfigBackup: Could not create backup directory');
        return false;
      }

      // Read all config values
      final configMap = <String, String>{};
      for (final key in _configKeys) {
        final value = await _storage.read(key: key);
        if (value != null && value.isNotEmpty) {
          configMap[key] = value;
        }
      }

      if (configMap.isEmpty) {
        debugPrint('ConfigBackup: No config to export');
        return false;
      }

      // Add metadata
      configMap['_backup_date'] = DateTime.now().toIso8601String();

      // Encode: JSON → Base64 with magic header
      final jsonStr = jsonEncode(configMap);
      final encoded = _magicHeader + base64Encode(utf8.encode(jsonStr));

      final file = File('${dir.path}/$_backupFileName');
      await file.writeAsString(encoded);

      debugPrint(
        'ConfigBackup: Exported ${configMap.length} keys to ${file.path}',
      );
      return true;
    } catch (e) {
      debugPrint('ConfigBackup: Export error: $e');
      return false;
    }
  }

  /// Check if a backup file exists.
  /// Returns backup info if found, null otherwise.
  static Future<Map<String, dynamic>?> checkForBackup() async {
    try {
      final dir = await _getBackupDir();
      if (dir == null) return null;

      final file = File('${dir.path}/$_backupFileName');
      if (!await file.exists()) return null;

      final content = await file.readAsString();
      if (!content.startsWith(_magicHeader)) return null;

      final encoded = content.substring(_magicHeader.length);
      final jsonStr = utf8.decode(base64Decode(encoded));
      final configMap = jsonDecode(jsonStr) as Map<String, dynamic>;

      final backupDate = configMap['_backup_date'] as String?;

      // Mask the API key for display
      String? maskedKey;
      final apiKey = configMap['ai_api_key'] as String?;
      if (apiKey != null && apiKey.length >= 12) {
        maskedKey =
            '${apiKey.substring(0, 8)}...${apiKey.substring(apiKey.length - 4)}';
      }

      return {
        'backupDate': backupDate,
        'hasApiKey': apiKey != null,
        'maskedKey': maskedKey,
        'keyCount': configMap.keys.where((k) => !k.startsWith('_')).length,
      };
    } catch (e) {
      debugPrint('ConfigBackup: Check error: $e');
      return null;
    }
  }

  /// Restore configuration from backup file.
  /// Returns the number of keys restored, or -1 on error.
  static Future<int> restoreConfig() async {
    try {
      final dir = await _getBackupDir();
      if (dir == null) return -1;

      final file = File('${dir.path}/$_backupFileName');
      if (!await file.exists()) return -1;

      final content = await file.readAsString();
      if (!content.startsWith(_magicHeader)) return -1;

      final encoded = content.substring(_magicHeader.length);
      final jsonStr = utf8.decode(base64Decode(encoded));
      final configMap = jsonDecode(jsonStr) as Map<String, dynamic>;

      int restored = 0;
      for (final entry in configMap.entries) {
        if (entry.key.startsWith('_')) continue;
        if (entry.value is String && (entry.value as String).isNotEmpty) {
          await _storage.write(key: entry.key, value: entry.value as String);
          restored++;
        }
      }

      debugPrint('ConfigBackup: Restored $restored keys');
      return restored;
    } catch (e) {
      debugPrint('ConfigBackup: Restore error: $e');
      return -1;
    }
  }

  /// Delete the backup file.
  static Future<bool> deleteBackup() async {
    try {
      final dir = await _getBackupDir();
      if (dir == null) return false;

      final file = File('${dir.path}/$_backupFileName');
      if (await file.exists()) {
        await file.delete();
        debugPrint('ConfigBackup: Backup file deleted');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('ConfigBackup: Delete error: $e');
      return false;
    }
  }
}
